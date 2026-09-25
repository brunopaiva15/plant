// Les trois services, vus du relais.
//
// Chacun est un passe-plat : le corps de la requête traverse presque tel
// quel, et c'est ici que la clé s'ajoute. Presque, parce que trois choses ne
// se laissent pas au client — le modèle, le nombre de jetons de la réponse,
// et la liste des champs acceptés. Un relais qui transmettrait n'importe quel
// corps serait une passerelle IA ouverte, ce qui coûterait plus cher qu'une
// clé volée.

import { source } from './bytes.ts';
import { imageTokens, limits, models, secrets } from './config.ts';
import type { Route } from './config.ts';

/// L'application est native, mais une construction web appellerait le relais
/// depuis un navigateur, qui demanderait d'abord la permission.
const CORS = { 'access-control-allow-origin': '*', 'cache-control': 'no-store' };

export class UpstreamError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

/// Lit le corps sans dépasser la borne de la route. La longueur annoncée ne
/// suffit pas : un `content-length` se ment.
export async function readBounded(request: Request, route: Route): Promise<Uint8Array> {
  const max = limits[route].maxBody;
  const announced = Number(request.headers.get('content-length') ?? '0');
  if (announced > max) throw new UpstreamError(413, 'requête trop volumineuse');

  const body = await request.arrayBuffer();
  if (body.byteLength > max) throw new UpstreamError(413, 'requête trop volumineuse');
  return new Uint8Array(body);
}

async function call(url: string, init: RequestInit, route: Route): Promise<Response> {
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), limits[route].timeout);
  try {
    return await fetch(url, { ...init, signal: abort.signal });
  } catch (error) {
    // Un amont qui ne répond pas est un 504, pas une erreur du relais : le
    // client sait déjà quoi en faire, il a le même cas hors ligne.
    if ((error as Error).name === 'AbortError') throw new UpstreamError(504, 'le service ne répond pas');
    throw new UpstreamError(502, 'service injoignable');
  } finally {
    clearTimeout(timer);
  }
}

/// La réponse rendue au client : le code et le corps de l'amont, rien
/// d'autre. Les codes comptent — Pl@ntNet répond 404 quand il ne reconnaît
/// rien, et l'application le lit comme « aucun candidat ».
async function passthrough(response: Response): Promise<Response> {
  // Un refus d'authentification chez l'amont ne regarde que l'éditeur : le
  // corps pourrait nommer le jeton, et le client n'en ferait rien de plus
  // qu'avec un code nu.
  if (response.status === 401 || response.status === 403) {
    return Response.json({ error: 'amont_refuse' }, { status: 502, headers: CORS });
  }
  return new Response(await response.arrayBuffer(), {
    status: response.status,
    headers: {
      ...CORS,
      'content-type': response.headers.get('content-type') ?? 'application/json',
    },
  });
}

/// Pl@ntNet. Le corps multipart traverse intact — ce sont les photos —, et
/// la langue est le seul réglage que le client garde la main dessus.
export async function identify(request: Request, url: URL): Promise<Response> {
  const body = await readBounded(request, 'identify');
  const contentType = request.headers.get('content-type') ?? '';
  if (!contentType.startsWith('multipart/form-data')) {
    throw new UpstreamError(400, 'multipart attendu');
  }

  const upstream = new URL('https://my-api.plantnet.org/v2/identify/all');
  upstream.searchParams.set('api-key', secrets.plantNet);
  // Deux lettres, et rien d'autre : ce qui part dans une URL signée par la
  // clé de l'éditeur se vérifie avant de partir.
  const language = (url.searchParams.get('lang') ?? 'en').toLowerCase();
  upstream.searchParams.set('lang', /^[a-z]{2}$/.test(language) ? language : 'en');
  upstream.searchParams.set('include-related-images', 'true');

  return passthrough(await call(upstream.toString(), {
    method: 'POST',
    headers: { 'content-type': contentType },
    body: source(body),
  }, 'identify'));
}

/// Les champs qu'un corps de conversation a le droit de porter. Tout le reste
/// tombe : c'est la différence entre un relais qui sert Auxine et un relais
/// qui sert n'importe qui.
const CHAT_FIELDS = ['messages', 'max_tokens', 'temperature', 'response_format', 'top_p'] as const;

/// Le plafond de jetons d'une réponse.
///
/// Il suit ce que demande le plus gourmand des appels : le diagnostic, qui
/// réclame 8000 jetons puis 12000 quand la réponse revient coupée
/// (`InfomaniakDiagnoser._answerTokens`, `_wideTokens`) ; les constructions
/// déjà installées, qui demandent 5000 puis 9000, passent aussi. Qwen
/// réfléchit avant d'écrire, et cette réflexion se paie sur ce budget. Plafonné à 4096, le
/// relais la privait de la place que le client lui avait rendue : la réponse
/// revenait vide ou coupée, le client reposait la question, le relais la
/// rabotait de nouveau, et le diagnostic tournait des minutes avant de
/// finir sur « Analyse impossible ».
///
/// Relever ce plafond ne coûte rien tant qu'il n'est pas atteint : seuls les
/// jetons écrits se facturent. Il reste une borne, et c'est le quota par
/// appareil qui borne la facture. Un appel qui demanderait plus que le
/// client n'en réclame lui-même n'est pas un appel d'Auxine.
const MAX_TOKENS = 12000;

/// Une conversation dont un message porte une image : dans le format
/// OpenAI, une partie `{ type: 'image_url' }` d'un contenu en liste.
function carriesImages(messages: unknown[]): boolean {
  return messages.some((message) => {
    const content = (message as { content?: unknown } | null)?.content;
    return Array.isArray(content) &&
      content.some((part) => (part as { type?: unknown } | null)?.type === 'image_url');
  });
}

export function chatBody(raw: Uint8Array): Record<string, unknown> {
  let parsed: unknown;
  try {
    parsed = JSON.parse(new TextDecoder().decode(raw));
  } catch {
    throw new UpstreamError(400, 'corps JSON illisible');
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    throw new UpstreamError(400, 'objet JSON attendu');
  }

  const source = parsed as Record<string, unknown>;
  if (!Array.isArray(source.messages) || source.messages.length === 0) {
    throw new UpstreamError(400, 'conversation vide');
  }

  const body: Record<string, unknown> = {};
  for (const field of CHAT_FIELDS) {
    if (source[field] !== undefined) body[field] = source[field];
  }
  const tokens = Number(body.max_tokens);
  const asked = Number.isFinite(tokens) ? Math.max(1, Math.floor(tokens)) : 1000;
  // Une demande qui porte des photos est un diagnostic : elle reçoit au moins
  // de quoi réfléchir et répondre en un seul appel (`imageTokens`).
  const floor = carriesImages(source.messages) ? imageTokens : 1;
  body.max_tokens = Math.min(Math.max(asked, floor), MAX_TOKENS);
  // Le modèle vient d'ici, jamais du client : c'est lui qui décide du prix.
  body.model = models.infomaniak;
  // Le client lit une réponse entière ; un flux le laisserait sans rien.
  body.stream = false;
  return body;
}

/// Les AI Services d'Infomaniak, route compatible OpenAI. Les quatre usages
/// de l'application — diagnostic, conseil, fiche d'entretien, bouturage —
/// passent par là : même amont, même corps, une seule route à tenir.
export async function ai(request: Request): Promise<Response> {
  const body = chatBody(await readBounded(request, 'ai'));
  const upstream = `https://api.infomaniak.com/2/ai/${secrets.infomaniakProduct}/openai/v1/chat/completions`;
  const response = await call(upstream, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${secrets.infomaniakKey}` },
    body: JSON.stringify(body),
  }, 'ai');
  const bytes = await response.arrayBuffer();
  console.log(`relais ai amont ${response.status} ${describeCompletion(bytes)} demandés=${body.max_tokens}`);
  return passthrough(new Response(bytes, { status: response.status, headers: response.headers }));
}

/// Ce qu'une réponse du modèle dit de sa propre fin, pour les journaux :
/// pourquoi il s'est arrêté, combien de jetons il a écrits, et la longueur
/// de ce qui reste une fois la réflexion écrite. Jamais le texte lui-même —
/// il parle de la plante de quelqu'un.
///
/// C'est ce qui manquait pour lire un diagnostic lent : sans cela, le
/// journal de la fonction ne disait ni qu'une réponse revenait coupée
/// (`length`), ni qu'elle revenait vide.
function describeCompletion(bytes: ArrayBuffer): string {
  try {
    const json = JSON.parse(new TextDecoder().decode(bytes)) as {
      choices?: { finish_reason?: unknown; message?: { content?: unknown } }[];
      usage?: { completion_tokens?: unknown };
    };
    const choice = json.choices?.[0];
    const content = typeof choice?.message?.content === 'string' ? choice.message.content : '';
    return `fin=${choice?.finish_reason ?? '?'} écrits=${json.usage?.completion_tokens ?? '?'} contenu=${content.length}`;
  } catch {
    return `corps illisible (${bytes.byteLength} octets)`;
  }
}

/// Jev, sur l'endpoint Decisions d'OpenRouter. Il ne génère pas de texte : il
/// reçoit un état et des questions typées, et rend des probabilités.
export async function decide(request: Request): Promise<Response> {
  const raw = await readBounded(request, 'decide');
  let parsed: unknown;
  try {
    parsed = JSON.parse(new TextDecoder().decode(raw));
  } catch {
    throw new UpstreamError(400, 'corps JSON illisible');
  }
  const source = parsed as Record<string, unknown>;
  if (typeof source?.questions !== 'object' || source.questions === null) {
    throw new UpstreamError(400, 'questions attendues');
  }

  return passthrough(await call('https://openrouter.ai/api/alpha/decisions', {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${secrets.openRouter}` },
    body: JSON.stringify({ model: models.jev, state: source.state ?? {}, questions: source.questions }),
  }, 'decide'));
}

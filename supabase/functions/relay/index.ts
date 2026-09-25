// Le relais des clés d'API.
//
//   POST /attest/challenge   un défi à usage unique
//   POST /attest/register    la première attestation d'un appareil
//   POST /attest/session     une assertion, contre un jeton de session
//   POST /attest/dev         le laissez-passer des constructions sans enclave
//   POST /identify           Pl@ntNet
//   POST /ai                 les AI Services d'Infomaniak
//   POST /decide             Jev, sur OpenRouter
//   GET  /health             ce que le relais peut servir
//
// Trois clés d'éditeur vivaient dans le binaire, extractibles par qui en
// démonte le paquet. Elles vivent ici. Ce qui reste à faire, du coup, c'est
// de savoir à qui le relais accepte de parler : sans cela on n'aurait pas
// retiré une clé volable, on aurait publié une passerelle IA gratuite, plus
// facile à trouver qu'une clé.
//
// D'où les deux gardes, qui ne font pas le même travail :
//
// - **App Attest** dit que c'est le vrai Auxine, sur un vrai appareil Apple.
//   Il borne le nombre d'attaquants possibles.
// - **Les quotas** bornent ce que chacun d'eux peut coûter. Ils s'appliquent
//   toujours, y compris à un appareil parfaitement légitime — c'est le seul
//   mécanisme qui tienne encore le jour où le premier est contourné.
//
// Le compte de l'utilisateur n'entre nulle part : l'identification et le
// diagnostic marchent sans être connecté, et le relais n'a donc jamais à
// savoir qui tient l'appareil.

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { fromBase64, hex, sha256, timingSafeEqual, toBase64, toBase64Url, utf8 } from './bytes.ts';
import { attestPolicy, available, challengeLifetime, limits, missingSecrets, secrets, sessionLifetime } from './config.ts';
import type { Route } from './config.ts';
import { AttestationError, verifyAssertion, verifyAttestation } from './attest.ts';
import { mintSession, readSession } from './session.ts';
import { ai, decide, identify, UpstreamError } from './upstreams.ts';

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
  auth: { persistSession: false },
});

const json = (body: unknown, status = 200): Response =>
  Response.json(body, {
    status,
    headers: {
      // L'application est native, mais une construction web appellerait le
      // relais depuis un navigateur, qui demanderait d'abord la permission.
      'access-control-allow-origin': '*',
      'access-control-allow-headers': 'authorization, content-type',
      'cache-control': 'no-store',
    },
  });

const fail = (status: number, error: string): Response => json({ error }, status);

async function body<T>(request: Request): Promise<T> {
  try {
    return (await request.json()) as T;
  } catch {
    throw new UpstreamError(400, 'corps JSON illisible');
  }
}

// ---------- Les défis ----------

/// Un défi est tiré au sort, gardé sous son condensé, et ne vaut qu'une fois.
/// Sans lui, une assertion capturée une fois vaudrait indéfiniment.
async function challenge(): Promise<Response> {
  const value = toBase64Url(crypto.getRandomValues(new Uint8Array(32)));
  const { error } = await db.from('relay_challenges').insert({
    id: hex(await sha256(utf8(value))),
    expires_at: new Date(Date.now() + challengeLifetime * 1000).toISOString(),
  });
  if (error) return fail(503, 'indisponible');
  return json({ challenge: value, expiresIn: challengeLifetime });
}

/// Consomme un défi. La lecture et l'effacement sont le même geste côté base,
/// sans quoi deux requêtes simultanées le dépenseraient toutes les deux.
async function claim(value: unknown): Promise<string> {
  if (typeof value !== 'string' || value.length < 16 || value.length > 128) {
    throw new UpstreamError(400, 'défi absent');
  }
  const { data, error } = await db.rpc('relay_claim_challenge', { p_id: hex(await sha256(utf8(value))) });
  if (error) throw new UpstreamError(503, 'indisponible');
  if (data !== true) throw new UpstreamError(401, 'défi inconnu ou périmé');
  return value;
}

// ---------- L'entrée ----------

interface Registration {
  keyId?: unknown;
  attestation?: unknown;
  assertion?: unknown;
  challenge?: unknown;
  token?: unknown;
}

/// Des octets annoncés en base64. Un corps mal formé est une erreur de
/// l'appelant, pas une panne du relais : il mérite un 400, pas un 500.
function bytesOf(value: unknown, what: string): Uint8Array {
  if (typeof value !== 'string' || value.length === 0) throw new UpstreamError(400, `${what} attendu`);
  try {
    return fromBase64(value);
  } catch {
    throw new UpstreamError(400, `${what} illisible`);
  }
}

function keyIdOf(value: unknown): string {
  // Le condensé d'une clé publique fait 32 octets, soit 44 signes en base64.
  if (typeof value !== 'string' || value.length !== 44) throw new UpstreamError(400, 'identifiant de clé attendu');
  return value;
}

/// Le premier échange d'un appareil : Apple atteste que la clé est née dans
/// la Secure Enclave, dans cette application. Le relais n'aura plus besoin
/// d'Apple ensuite — il garde la clé publique.
async function register(request: Request): Promise<Response> {
  const payload = await body<Registration>(request);
  const keyId = keyIdOf(payload.keyId);
  const attestation = bytesOf(payload.attestation, 'attestation');
  const value = await claim(payload.challenge);

  let attested;
  try {
    attested = await verifyAttestation(attestation, keyId, value, attestPolicy());
  } catch (error) {
    if (error instanceof AttestationError) return fail(401, 'attestation refusée');
    throw error;
  }

  // Le compteur n'est pas dans la charge, et c'est voulu : à l'insertion il
  // prend sa valeur par défaut, et sur un conflit il garde la sienne. Le
  // remettre à zéro ici rouvrirait les assertions déjà passées.
  const { error } = await db.from('relay_devices').upsert({
    key_id: attested.keyId,
    public_key: toBase64(attested.publicKey),
    environment: attested.environment,
    receipt: attested.receipt ? toBase64(attested.receipt) : null,
    last_seen_at: new Date().toISOString(),
  });
  if (error) return fail(503, 'indisponible');

  return json(await mintSession(secrets.session, { sub: attested.keyId, kind: 'appattest' }, sessionLifetime));
}

/// Les échanges suivants : l'appareil signe le défi avec la clé attestée.
async function session(request: Request): Promise<Response> {
  const payload = await body<Registration>(request);
  const keyId = keyIdOf(payload.keyId);
  const assertion = bytesOf(payload.assertion, 'assertion');
  const value = await claim(payload.challenge);

  const { data, error } = await db.from('relay_devices').select('public_key, counter').eq('key_id', keyId).maybeSingle();
  if (error) return fail(503, 'indisponible');
  // Un appareil inconnu doit se réenregistrer : le client le lit au code et
  // repart d'une attestation, ce qui arrive après une remise à zéro de la base.
  if (!data) return fail(404, 'appareil inconnu');

  let counter: number;
  try {
    const verified = await verifyAssertion(
      assertion,
      fromBase64(data.public_key as string),
      value,
      Number(data.counter),
      attestPolicy(),
    );
    counter = verified.counter;
  } catch (error) {
    if (error instanceof AttestationError) return fail(401, 'assertion refusée');
    throw error;
  }

  // Le compteur ne monte que s'il monte, et la base tranche : deux assertions
  // arrivées ensemble ne peuvent pas passer toutes les deux.
  const bumped = await db.rpc('relay_bump_counter', { p_key_id: keyId, p_counter: counter });
  if (bumped.error) return fail(503, 'indisponible');
  if (bumped.data !== true) return fail(401, 'assertion refusée');

  return json(await mintSession(secrets.session, { sub: keyId, kind: 'appattest' }, sessionLifetime));
}

/// Le chemin des constructions qui ne peuvent pas attester : le simulateur,
/// où App Attest n'existe pas, et Android, qui attend Play Integrity. Un
/// secret partagé, donc rien qui prouve quoi que ce soit — d'où le quota
/// commun : tout ce qui entre par là partage un seul appareil, et se coupe
/// d'un `supabase secrets unset` le jour où il fuit.
async function dev(request: Request): Promise<Response> {
  if (!secrets.devToken) return fail(404, 'inconnu');
  const payload = await body<Registration>(request);
  if (typeof payload.token !== 'string') throw new UpstreamError(400, 'jeton attendu');
  if (!timingSafeEqual(utf8(payload.token), utf8(secrets.devToken))) return fail(401, 'jeton refusé');
  return json(await mintSession(secrets.session, { sub: 'dev', kind: 'dev' }, sessionLifetime));
}

// ---------- Les routes qui coûtent ----------

/// Le jeton de session, puis le quota. Dans cet ordre : un appelant qu'on ne
/// reconnaît pas n'a pas à faire écrire une ligne de comptage.
async function guard(request: Request, route: Route): Promise<string> {
  const header = request.headers.get('authorization') ?? '';
  const token = header.toLowerCase().startsWith('bearer ') ? header.slice(7).trim() : '';
  const claims = token ? await readSession(secrets.session, token) : null;
  if (!claims) throw new UpstreamError(401, 'jeton absent ou périmé');

  const { data, error } = await db.rpc('relay_consume', {
    p_device: claims.sub,
    p_route: route,
    p_limit: limits[route].perDevice,
    p_global: limits[route].perDay,
  });
  if (error) throw new UpstreamError(503, 'indisponible');
  const verdict = Array.isArray(data) ? data[0] : data;
  if (!verdict?.allowed) throw new UpstreamError(429, 'quota');
  return claims.sub;
}

const upstreams: Record<Route, (request: Request, url: URL) => Promise<Response>> = {
  identify,
  ai: (request) => ai(request),
  decide: (request) => decide(request),
};

// ---------- L'aiguillage ----------

// Une ligne par requête dans les journaux de la fonction : la route, le code
// rendu et la durée. L'onglet « Invocations » du tableau de bord peut rester
// des minutes sans se mettre à jour ; les journaux, eux, arrivent — et sans
// cette ligne, ils ne disaient que le démarrage et l'arrêt d'une instance.
Deno.serve(async (request) => {
  const started = Date.now();
  const response = await handle(request);
  const path = new URL(request.url).pathname.replace(/^\/relay(?=\/|$)/, '') || '/';
  console.log(`relais ${request.method} ${path} ${response.status} ${Date.now() - started} ms`);
  return response;
});

async function handle(request: Request): Promise<Response> {
  const url = new URL(request.url);
  // Le chemin arrive préfixé du nom de la fonction : le runtime Supabase a
  // déjà retiré `/functions/v1`, il reste `/relay/ai`. La garde après le nom
  // évite de mordre sur un chemin qui commencerait par les mêmes lettres.
  const path = url.pathname.replace(/^\/relay(?=\/|$)/, '').replace(/\/+$/, '') || '/';

  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'access-control-allow-origin': '*',
        'access-control-allow-headers': 'authorization, content-type',
        'access-control-allow-methods': 'POST, GET, OPTIONS',
        'access-control-max-age': '86400',
      },
    });
  }

  // Ce que le relais peut servir, sans rien révéler de ce qu'il tient. La
  // sonde d'état de l'application s'y adresse, et un déploiement sans secrets
  // se voit ici plutôt que dans un échec d'amont trois écrans plus loin.
  if (path === '/health') {
    const missing = missingSecrets();
    return json({ ok: missing.length === 0, routes: available(), missing }, missing.length === 0 ? 200 : 503);
  }

  if (request.method !== 'POST') return fail(405, 'méthode refusée');

  try {
    if (missingSecrets().length > 0) return fail(503, 'relais non configuré');

    switch (path) {
      case '/attest/challenge':
        return await challenge();
      case '/attest/register':
        return await register(request);
      case '/attest/session':
        return await session(request);
      case '/attest/dev':
        return await dev(request);
    }

    const route = path.slice(1) as Route;
    if (!(route in upstreams)) return fail(404, 'inconnu');
    if (!available()[route]) return fail(503, 'service non configuré');

    await guard(request, route);
    return await upstreams[route](request, url);
  } catch (error) {
    if (error instanceof UpstreamError) return fail(error.status, error.message);
    // Ce qui n'a pas été prévu ne sort pas d'ici : le message pourrait porter
    // une URL signée ou un nom de secret.
    console.error('relais', error);
    return fail(500, 'erreur interne');
  }
}

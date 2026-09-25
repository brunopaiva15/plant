// Play Integrity, côté serveur.
//
// Le pendant Android d'App Attest, et il ne prouve pas la même chose de la
// même façon. Apple signe une clé née dans l'enclave, que le relais garde et
// qui signe ensuite chaque défi. Google, lui, ne donne aucune clé : à chaque
// poignée de main, l'application demande un jeton chiffré au Play Store de
// l'appareil, et seul Google sait l'ouvrir. Le relais le lui fait donc
// déchiffrer (`decodeIntegrityToken`), puis lit le verdict :
//
// - **l'application** est celle que Google Play a distribuée, sous ce nom de
//   paquet, signée par la clé déclarée (`PLAY_RECOGNIZED`) ;
// - **l'appareil** est un vrai Android certifié, pas un émulateur ni un
//   téléphone dont le système a été modifié (`MEETS_DEVICE_INTEGRITY`) ;
// - **la demande** porte sur ce défi-ci, et sur cet identifiant
//   d'installation-ci : le condensé des deux est scellé dans le jeton.
//
// Ce que ça ne donne pas : une identité d'appareil stable. Il n'y a pas de
// clé à garder, et Google ne rend aucun identifiant. L'appareil se présente
// donc par un identifiant d'installation tiré au sort par l'application, lié
// au défi par le condensé : il ne se vole pas d'un jeton à l'autre, mais une
// réinstallation en tire un neuf. Le quota par appareil est donc plus souple
// sur Android que sur iPhone, et c'est le plafond du jour, tous appareils
// confondus, qui borne la facture — comme il le fait déjà.
//
// La marche à suivre est celle de Google, « Integrity verdicts » et « Make a
// standard API request ».

import { fromBase64, hex, sha256, source, toBase64Url, utf8 } from './bytes.ts';

export class IntegrityError extends Error {}

export interface IntegrityPolicy {
  /// Le nom du paquet, tel que Google Play le connaît.
  readonly packageName: string;
  /// Les empreintes SHA-256 des certificats de signature acceptés, en
  /// hexadécimal minuscule. Vide : `PLAY_RECOGNIZED` suffit, puisque Google
  /// ne le rend que pour un binaire signé par la clé qu'il connaît.
  readonly certificates: readonly string[];
  /// L'âge maximal d'un jeton, en millisecondes.
  readonly maxAge: number;
}

/// Le condensé que l'application scelle dans sa demande, et que le relais
/// recalcule : le défi seul prouverait la fraîcheur, pas l'installation.
export const integrityRequestHash = async (challenge: string, installId: string): Promise<string> =>
  hex(await sha256(utf8(`${challenge}.${installId}`)));

/// Une empreinte telle que la console Play l'affiche (« AB:CD:… »), telle
/// que le verdict la porte (base64url), ou en hexadécimal : toutes se
/// ramènent à l'hexadécimal minuscule.
export function normalizeDigest(value: string): string {
  const trimmed = value.trim();
  if (/^([0-9a-fA-F]{2}:){31}[0-9a-fA-F]{2}$/.test(trimmed)) return trimmed.replaceAll(':', '').toLowerCase();
  if (/^[0-9a-fA-F]{64}$/.test(trimmed)) return trimmed.toLowerCase();
  return hex(fromBase64(trimmed));
}

interface Verdict {
  requestDetails?: { requestPackageName?: unknown; requestHash?: unknown; timestampMillis?: unknown };
  appIntegrity?: { appRecognitionVerdict?: unknown; packageName?: unknown; certificateSha256Digest?: unknown };
  deviceIntegrity?: { deviceRecognitionVerdict?: unknown };
}

/// Lit le verdict déchiffré par Google, et refuse tout ce qui n'est pas le
/// vrai Auxine, sur un vrai appareil, pour ce défi-ci.
export function checkVerdict(payload: unknown, expectedHash: string, policy: IntegrityPolicy, now: number = Date.now()): void {
  const verdict = (payload ?? {}) as Verdict;
  const request = verdict.requestDetails ?? {};
  const app = verdict.appIntegrity ?? {};
  const device = verdict.deviceIntegrity ?? {};

  // 1. La demande : ce paquet, ce condensé, et récente. Le condensé est ce
  //    qui empêche de rejouer un jeton obtenu pour un autre défi.
  if (request.requestPackageName !== policy.packageName) throw new IntegrityError('paquet de la demande');
  if (request.requestHash !== expectedHash) throw new IntegrityError('condensé de la demande');
  const at = Number(request.timestampMillis);
  if (!Number.isFinite(at) || Math.abs(now - at) > policy.maxAge) throw new IntegrityError('jeton périmé');

  // 2. L'application : distribuée par Google Play, sous ce nom.
  if (app.appRecognitionVerdict !== 'PLAY_RECOGNIZED') throw new IntegrityError('application non reconnue');
  if (app.packageName !== policy.packageName) throw new IntegrityError("paquet de l'application");
  if (policy.certificates.length > 0) {
    const digests = Array.isArray(app.certificateSha256Digest) ? app.certificateSha256Digest : [];
    const known = digests.some((d) => typeof d === 'string' && policy.certificates.includes(normalizeDigest(d)));
    if (!known) throw new IntegrityError('certificat de signature');
  }

  // 3. L'appareil : un Android certifié. `MEETS_BASIC_INTEGRITY` seul, c'est
  //    un système modifié ou un émulateur — précisément ce qu'un script
  //    utiliserait pour se faire passer pour mille appareils.
  const labels = Array.isArray(device.deviceRecognitionVerdict) ? device.deviceRecognitionVerdict : [];
  if (!labels.includes('MEETS_DEVICE_INTEGRITY')) throw new IntegrityError('appareil non certifié');
}

// ---------- Google ----------

/// Le compte de service qui a le droit de déchiffrer les jetons : le JSON que
/// la console Google Cloud fait télécharger, tel quel.
export interface ServiceAccount {
  readonly client_email: string;
  readonly private_key: string;
  readonly token_uri?: string;
}

export function parseServiceAccount(raw: string): ServiceAccount | null {
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as Partial<ServiceAccount>;
    if (typeof parsed.client_email !== 'string' || typeof parsed.private_key !== 'string') return null;
    return parsed as ServiceAccount;
  } catch {
    return null;
  }
}

const SCOPE = 'https://www.googleapis.com/auth/playintegrity';

/// Un jeton d'accès se garde le temps qu'il vit : en redemander un à chaque
/// poignée de main doublerait les allers-retours pour rien.
let cached: { email: string; token: string; expiry: number } | null = null;

async function signingKey(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\s+/g, '');
  return crypto.subtle.importKey(
    'pkcs8',
    source(fromBase64(body)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

/// L'échange d'un JWT signé par le compte de service contre un jeton
/// d'accès OAuth — le flux « service account » de Google, sans bibliothèque.
async function accessToken(account: ServiceAccount, fetcher: typeof fetch, now: number): Promise<string> {
  if (cached && cached.email === account.client_email && cached.expiry - 60_000 > now) return cached.token;

  const audience = account.token_uri ?? 'https://oauth2.googleapis.com/token';
  const issued = Math.floor(now / 1000);
  const segment = (value: unknown) => toBase64Url(utf8(JSON.stringify(value)));
  const unsigned = `${segment({ alg: 'RS256', typ: 'JWT' })}.${segment({
    iss: account.client_email,
    scope: SCOPE,
    aud: audience,
    iat: issued,
    exp: issued + 3600,
  })}`;
  const signature = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', await signingKey(account.private_key), source(utf8(unsigned))),
  );

  const response = await fetcher(audience, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsigned}.${toBase64Url(signature)}`,
    }),
  });
  if (!response.ok) throw new Error(`Google OAuth HTTP ${response.status}`);
  const body = (await response.json()) as { access_token?: unknown; expires_in?: unknown };
  if (typeof body.access_token !== 'string') throw new Error('Google OAuth : jeton absent');
  const lifetime = typeof body.expires_in === 'number' ? body.expires_in : 3600;
  cached = { email: account.client_email, token: body.access_token, expiry: now + lifetime * 1000 };
  return body.access_token;
}

/// Fait déchiffrer un jeton par Google. Un jeton que Google refuse de lire
/// est un refus (`IntegrityError`) ; un Google qui ne répond pas est une
/// panne, et remonte comme telle.
export async function decodeIntegrityToken(
  token: string,
  packageName: string,
  account: ServiceAccount,
  fetcher: typeof fetch = fetch,
  now: number = Date.now(),
): Promise<unknown> {
  const response = await fetcher(
    `https://playintegrity.googleapis.com/v1/${encodeURIComponent(packageName)}:decodeIntegrityToken`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${await accessToken(account, fetcher, now)}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ integrity_token: token }),
    },
  );
  if (response.status === 400) throw new IntegrityError('jeton illisible');
  if (!response.ok) throw new Error(`Play Integrity HTTP ${response.status}`);
  const body = (await response.json()) as { tokenPayloadExternal?: unknown };
  if (!body.tokenPayloadExternal) throw new IntegrityError('verdict absent');
  return body.tokenPayloadExternal;
}

/// Pour les tests : oublier le jeton d'accès gardé.
export const forgetAccessToken = (): void => {
  cached = null;
};

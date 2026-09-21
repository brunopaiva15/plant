// Le jeton que le relais délivre à un appareil dont l'attestation tient.
//
// Une assertion App Attest coûte un aller-retour et une signature de la
// Secure Enclave ; en demander une par requête rendrait chaque diagnostic
// plus lent sans rien prouver de plus. L'appareil en produit donc une, reçoit
// un jeton court, et s'en sert jusqu'à son expiration.
//
// Ce jeton ne voyage qu'entre le relais et lui : il est signé avec un secret
// que seul le relais connaît (`RELAY_SESSION_SECRET`), et ne porte que de
// quoi reconnaître l'appareil et compter ce qu'il consomme. Un JWS compact,
// pas un JWT Supabase — rien ici ne concerne l'authentification d'un compte.

import { fromBase64, source, timingSafeEqual, toBase64Url, utf8 } from './bytes.ts';

export interface SessionClaims {
  /// L'appareil : l'identifiant de clé App Attest, ou `dev:<empreinte>`.
  readonly sub: string;
  /// Comment il s'est présenté, pour que les quotas puissent différer.
  readonly kind: 'appattest' | 'dev';
  readonly iat: number;
  readonly exp: number;
}

const headerSegment = toBase64Url(utf8(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));

async function key(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', source(utf8(secret)), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
}

async function signature(secret: string, payload: string): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.sign('HMAC', await key(secret), source(utf8(payload))));
}

export async function mintSession(
  secret: string,
  claims: Omit<SessionClaims, 'iat' | 'exp'>,
  lifetime: number,
  now: number = Date.now(),
): Promise<{ token: string; expiresIn: number }> {
  const issued = Math.floor(now / 1000);
  const full: SessionClaims = { ...claims, iat: issued, exp: issued + lifetime };
  const body = `${headerSegment}.${toBase64Url(utf8(JSON.stringify(full)))}`;
  return { token: `${body}.${toBase64Url(await signature(secret, body))}`, expiresIn: lifetime };
}

/// Rend les revendications d'un jeton intact et non expiré, `null` sinon.
/// Ne distingue pas les causes : un appelant qui se voit refuser n'a rien à
/// apprendre de la raison.
export async function readSession(secret: string, token: string, now: number = Date.now()): Promise<SessionClaims | null> {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [head, payload, mac] = parts;
  if (head !== headerSegment) return null;

  let provided: Uint8Array;
  try {
    provided = fromBase64(mac);
  } catch {
    return null;
  }
  if (!timingSafeEqual(provided, await signature(secret, `${head}.${payload}`))) return null;

  try {
    const claims = JSON.parse(new TextDecoder().decode(fromBase64(payload))) as SessionClaims;
    if (typeof claims.sub !== 'string' || !claims.sub) return null;
    if (claims.kind !== 'appattest' && claims.kind !== 'dev') return null;
    if (typeof claims.exp !== 'number' || claims.exp * 1000 <= now) return null;
    return claims;
  } catch {
    return null;
  }
}

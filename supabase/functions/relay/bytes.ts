// Conversions d'octets partagées par le relais.
//
// Deno sait faire du base64 (`atob`, `btoa`), mais sur des chaînes de
// caractères : sur un flux binaire, le détour par `charCodeAt` est le seul
// qui ne perde rien. Le reste est trop court pour mériter une dépendance.

export function fromBase64(value: string): Uint8Array {
  // Le base64url voyage mieux dans une URL et dans un JSON ; les deux
  // alphabets arrivent ici, et le second se ramène au premier.
  const normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

export function toBase64(bytes: Uint8Array): string {
  let binary = '';
  // Par tranches : `String.fromCharCode` prend ses octets en arguments, et
  // une photo entière dépasserait la pile d'appels.
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(binary);
}

export const toBase64Url = (bytes: Uint8Array): string =>
  toBase64(bytes).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');

export const utf8 = (value: string): Uint8Array => new TextEncoder().encode(value);

export function concat(...parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((sum, part) => sum + part.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

/// Comparaison à durée constante : l'appelant qui teste un jeton ne doit
/// rien apprendre du temps de réponse.
export function timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

/// Une vue d'octets là où la Web Crypto et `fetch` attendent un
/// `BufferSource`.
///
/// Depuis TypeScript 5.7, `Uint8Array` porte le type de son tampon, et une
/// vue sur un `ArrayBufferLike` — ce que rend toute fonction qui annonce un
/// `Uint8Array` nu — n'est plus assignable. À l'exécution il n'y a rien à
/// faire : une vue *est* une source valable, et le contrat ne vaut que pour
/// un `SharedArrayBuffer`, qui n'entre jamais ici. Le passage par `slice()`
/// recopierait la mémoire pour rien, y compris sur une photo entière.
export const source = (bytes: Uint8Array): BufferSource => bytes as unknown as BufferSource;

export const sha256 = async (data: Uint8Array): Promise<Uint8Array> =>
  new Uint8Array(await crypto.subtle.digest('SHA-256', source(data)));

export const hex = (bytes: Uint8Array): string =>
  Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');

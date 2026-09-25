// Vérification ECDSA, sans la Web Crypto.
//
// La Web Crypto de Deno ne vérifie que deux paires : P-256 avec SHA-256, et
// P-384 avec SHA-384. Tout autre mélange lève « Not implemented ». Or Apple
// en emploie un troisième : l'intermédiaire « Apple App Attestation CA 1 »,
// une clé P-384, signe le certificat d'appareil en ecdsa-with-SHA256. Node et
// les Deno récents l'acceptent, et les tests passaient ; le runtime des
// fonctions Supabase, non — chaque première attestation d'un iPhone finissait
// en erreur 500, et aucune requête n'atteignait plus Pl@ntNet.
//
// D'où ce module : la vérification refaite à la main, pour toutes les
// signatures du relais et pas seulement pour la paire qui manque. Un seul
// chemin, c'est ce qui garantit que les tests éprouvent le code qui tourne
// en production, quel que soit le runtime. Seul le condensé reste confié à
// `crypto.subtle.digest`, que tous savent faire.
//
// Rien ici n'est secret : la clé, le message et la signature sont publics.
// Le calcul n'a donc pas à être à temps constant.

import { source } from './bytes.ts';

export type Curve = 'P-256' | 'P-384';
export type Hash = 'SHA-256' | 'SHA-384';

interface CurveParams {
  readonly p: bigint;
  readonly b: bigint;
  readonly n: bigint;
  readonly gx: bigint;
  readonly gy: bigint;
  /// La taille d'une coordonnée, en octets.
  readonly size: number;
}

/// Les paramètres de FIPS 186-4, annexe D.1.2. Le coefficient `a` vaut -3
/// sur les deux courbes, et les formules ci-dessous le supposent.
const CURVES: Record<Curve, CurveParams> = {
  'P-256': {
    p: 0xffffffff00000001000000000000000000000000ffffffffffffffffffffffffn,
    b: 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604bn,
    n: 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551n,
    gx: 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296n,
    gy: 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5n,
    size: 32,
  },
  'P-384': {
    p: 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffffn,
    b: 0xb3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aefn,
    n: 0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973n,
    gx: 0xaa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7n,
    gy: 0x3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5fn,
    size: 48,
  },
};

const mod = (a: bigint, m: bigint): bigint => {
  const r = a % m;
  return r < 0n ? r + m : r;
};

/// L'inverse modulaire, par Euclide étendu. `m` est premier et `a` non nul.
function invert(a: bigint, m: bigint): bigint {
  let [r0, r1] = [mod(a, m), m];
  let [s0, s1] = [1n, 0n];
  while (r1 !== 0n) {
    const q = r0 / r1;
    [r0, r1] = [r1, r0 - q * r1];
    [s0, s1] = [s1, s0 - q * s1];
  }
  return mod(s0, m);
}

const bigintOf = (bytes: Uint8Array): bigint => {
  let value = 0n;
  for (const byte of bytes) value = (value << 8n) | BigInt(byte);
  return value;
};

/// Un point en coordonnées jacobiennes : (X / Z², Y / Z³). Z nul désigne le
/// point à l'infini. Elles évitent une inversion à chaque opération.
type Point = readonly [bigint, bigint, bigint];

const INFINITY: Point = [1n, 1n, 0n];

function double([x, y, z]: Point, p: bigint): Point {
  if (z === 0n || y === 0n) return INFINITY;
  // dbl-2001-b, pour a = -3.
  const delta = mod(z * z, p);
  const gamma = mod(y * y, p);
  const beta = mod(x * gamma, p);
  const alpha = mod(3n * (x - delta) * (x + delta), p);
  const x3 = mod(alpha * alpha - 8n * beta, p);
  const z3 = mod((y + z) * (y + z) - gamma - delta, p);
  const y3 = mod(alpha * (4n * beta - x3) - 8n * gamma * gamma, p);
  return [x3, y3, z3];
}

function add(a: Point, b: Point, p: bigint): Point {
  if (a[2] === 0n) return b;
  if (b[2] === 0n) return a;
  const [x1, y1, z1] = a;
  const [x2, y2, z2] = b;
  const z1z1 = mod(z1 * z1, p);
  const z2z2 = mod(z2 * z2, p);
  const u1 = mod(x1 * z2z2, p);
  const u2 = mod(x2 * z1z1, p);
  const s1 = mod(y1 * z2 * z2z2, p);
  const s2 = mod(y2 * z1 * z1z1, p);
  if (u1 === u2) return s1 === s2 ? double(a, p) : INFINITY;
  const h = mod(u2 - u1, p);
  const r = mod(s2 - s1, p);
  const h2 = mod(h * h, p);
  const h3 = mod(h * h2, p);
  const u1h2 = mod(u1 * h2, p);
  const x3 = mod(r * r - h3 - 2n * u1h2, p);
  const y3 = mod(r * (u1h2 - x3) - s1 * h3, p);
  const z3 = mod(h * z1 * z2, p);
  return [x3, y3, z3];
}

/// u1·G + u2·Q en une seule passe (Shamir) : une chaîne de doublements au
/// lieu de deux.
function combine(u1: bigint, g: Point, u2: bigint, q: Point, p: bigint): Point {
  const both = add(g, q, p);
  let acc = INFINITY;
  const bits = Math.max(u1.toString(2).length, u2.toString(2).length);
  for (let i = bits - 1; i >= 0; i--) {
    acc = double(acc, p);
    const bit = BigInt(i);
    const a = (u1 >> bit) & 1n;
    const b = (u2 >> bit) & 1n;
    if (a && b) acc = add(acc, both, p);
    else if (a) acc = add(acc, g, p);
    else if (b) acc = add(acc, q, p);
  }
  return acc;
}

/// Le point d'une clé publique non compressée (0x04 ‖ x ‖ y), s'il est bien
/// sur la courbe. Un point hors courbe n'est pas une clé : il est refusé
/// avant tout calcul.
function publicPoint(key: Uint8Array, params: CurveParams): Point | null {
  if (key.length !== 1 + 2 * params.size || key[0] !== 0x04) return null;
  const x = bigintOf(key.subarray(1, 1 + params.size));
  const y = bigintOf(key.subarray(1 + params.size));
  const { p, b } = params;
  if (x >= p || y >= p) return null;
  if (mod(y * y - (x * x * x - 3n * x + b), p) !== 0n) return null;
  return [x, y, 1n];
}

/// Vérifie une signature ECDSA brute (r ‖ s, chacun sur la taille de la
/// courbe) sur `message`, condensé par `hash`. Faux pour toute entrée
/// invalide — clé hors courbe, composante hors bornes —, jamais d'exception
/// sur des octets fournis par l'appelant.
export async function verifyEcdsa(
  curve: Curve,
  hash: Hash,
  publicKey: Uint8Array,
  signature: Uint8Array,
  message: Uint8Array,
): Promise<boolean> {
  const params = CURVES[curve];
  const { p, n, size } = params;
  if (signature.length !== 2 * size) return false;
  const q = publicPoint(publicKey, params);
  if (!q) return false;

  const r = bigintOf(signature.subarray(0, size));
  const s = bigintOf(signature.subarray(size));
  if (r <= 0n || r >= n || s <= 0n || s >= n) return false;

  // Le condensé, tronqué à la taille de l'ordre s'il la dépasse (SEC 1,
  // § 4.1.4). SHA-256 sous P-384 est plus court : il se prend tel quel.
  const digest = new Uint8Array(await crypto.subtle.digest(hash, source(message)));
  const excess = digest.length * 8 - n.toString(2).length;
  const e = excess > 0 ? bigintOf(digest) >> BigInt(excess) : bigintOf(digest);

  const w = invert(s, n);
  const point = combine(mod(e * w, n), [params.gx, params.gy, 1n], mod(r * w, n), q, p);
  if (point[2] === 0n) return false;
  const zInv = invert(point[2], p);
  const x = mod(point[0] * zInv * zInv, p);
  return mod(x, n) === r;
}

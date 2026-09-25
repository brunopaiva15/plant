// Refabrique les pièces d'attestation de `supabase/functions/relay/attest_fixtures.ts`.
//
//   mkdir -p /tmp/attest && cd /tmp/attest
//   node <racine>/tool/fabriquer_attestation.mjs
//
// Écrit `fixtures.json` dans le dossier courant, avec les clés à recopier
// dans `attest_fixtures.ts`. Demande `openssl` sur le chemin.
//
// Pourquoi ce détour : App Attest ne se rejoue pas. Une clé de Secure Enclave
// ne s'atteste qu'une fois, et personne n'a d'iPhone sous la main quand les
// tests tournent. On fabrique donc une chaîne de la même forme qu'Apple —
// racine P-384, intermédiaire qu'elle signe, certificat d'appareil P-256
// portant l'extension 1.2.840.113635.100.8.2 avec le nonce calculé sur
// `authData` — mais enracinée dans une autorité de test. Le vérificateur
// l'accepte parce que la politique lui passe cette racine-là, et le test
// « refuse la racine d'Apple » montre que la vraie ancre la rejette.
//
// Les certificats sont écrits par OpenSSL, pas à la main : c'est ce qui rend
// l'épreuve du lecteur DER honnête. Seul l'assemblage CBOR est fait ici.

import { execFileSync } from 'node:child_process';
import { writeFileSync, readFileSync } from 'node:fs';
import crypto from 'node:crypto';

const sh = (args, input) => execFileSync('openssl', args, { input, maxBuffer: 1 << 24 });
const pemToDer = (pem) => Buffer.from(pem.toString().replace(/-----[^-]+-----|\s/g, ''), 'base64');

const APP_ID = 'ABCDE12345.ch.vergasta.plant';
const CHALLENGE = 'Yw9rk3pQ2nTf5sVx8bLh1dGm4aZcJeRu';

// ---- 1. Racine de test, P-384, auto-signée ----
sh(['ecparam', '-name', 'secp384r1', '-genkey', '-noout', '-out', 'root.key']);
sh(['req', '-x509', '-new', '-key', 'root.key', '-sha384', '-days', '9000',
    '-subj', '/CN=Auxine Test App Attest Root/O=Auxine', '-out', 'root.pem']);

// ---- 2. Intermédiaire, P-384, signé par la racine ----
sh(['ecparam', '-name', 'secp384r1', '-genkey', '-noout', '-out', 'int.key']);
sh(['req', '-new', '-key', 'int.key', '-subj', '/CN=Auxine Test App Attest CA 1/O=Auxine', '-out', 'int.csr']);
writeFileSync('int.ext', 'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign\n');
sh(['x509', '-req', '-in', 'int.csr', '-CA', 'root.pem', '-CAkey', 'root.key', '-CAcreateserial',
    '-sha384', '-days', '9000', '-extfile', 'int.ext', '-out', 'int.pem']);

// ---- 3. Clé d'appareil, P-256 ----
sh(['ecparam', '-name', 'prime256v1', '-genkey', '-noout', '-out', 'cred.key']);
const credPriv = crypto.createPrivateKey(readFileSync('cred.key'));
const jwk = crypto.createPublicKey(credPriv).export({ format: 'jwk' });
const b64u = (s) => Buffer.from(s, 'base64url');
const point = Buffer.concat([Buffer.from([0x04]), b64u(jwk.x), b64u(jwk.y)]);
const credentialId = crypto.createHash('sha256').update(point).digest();

// ---- 4. authData, à la façon de WebAuthn ----
const cborEncode = (value) => {
  const head = (major, n) => {
    if (n < 24) return Buffer.from([(major << 5) | n]);
    if (n < 256) return Buffer.from([(major << 5) | 24, n]);
    if (n < 65536) return Buffer.from([(major << 5) | 25, n >> 8, n & 0xff]);
    const b = Buffer.alloc(5); b[0] = (major << 5) | 26; b.writeUInt32BE(n, 1); return b;
  };
  if (Buffer.isBuffer(value)) return Buffer.concat([head(2, value.length), value]);
  if (typeof value === 'string') { const b = Buffer.from(value, 'utf8'); return Buffer.concat([head(3, b.length), b]); }
  if (typeof value === 'number') return value >= 0 ? head(0, value) : head(1, -1 - value);
  if (Array.isArray(value)) return Buffer.concat([head(4, value.length), ...value.map(cborEncode)]);
  if (value instanceof Map) return Buffer.concat([head(5, value.size), ...[...value].flatMap(([k, v]) => [cborEncode(k), cborEncode(v)])]);
  throw new Error('cbor: type non géré');
};

const coseKey = cborEncode(new Map([[1, 2], [3, -7], [-1, 1], [-2, b64u(jwk.x)], [-3, b64u(jwk.y)]]));
const rpIdHash = crypto.createHash('sha256').update(APP_ID, 'utf8').digest();
const aaguid = Buffer.concat([Buffer.from('appattestdevelop', 'utf8')]);
const credLen = Buffer.alloc(2); credLen.writeUInt16BE(credentialId.length);
const authData = Buffer.concat([
  rpIdHash, Buffer.from([0x40]), Buffer.alloc(4), aaguid, credLen, credentialId, coseKey,
]);

// ---- 5. Le nonce scellé dans le certificat d'appareil ----
const clientDataHash = crypto.createHash('sha256').update(CHALLENGE, 'utf8').digest();
const nonce = crypto.createHash('sha256').update(Buffer.concat([authData, clientDataHash])).digest();
const nonceDer = Buffer.concat([Buffer.from([0x30, 0x24, 0xa1, 0x22, 0x04, 0x20]), nonce]);
writeFileSync('cred.ext', `1.2.840.113635.100.8.2=DER:${nonceDer.toString('hex').match(/../g).join(':')}\n`);

sh(['req', '-new', '-key', 'cred.key', '-subj', '/CN=Auxine Test Device/O=Auxine', '-out', 'cred.csr']);
sh(['x509', '-req', '-in', 'cred.csr', '-CA', 'int.pem', '-CAkey', 'int.key', '-CAcreateserial',
    '-sha256', '-days', '9000', '-extfile', 'cred.ext', '-out', 'cred.pem']);

const attestation = cborEncode(new Map([
  ['fmt', 'apple-appattest'],
  ['attStmt', new Map([['x5c', [pemToDer(readFileSync('cred.pem')), pemToDer(readFileSync('int.pem'))]], ['receipt', Buffer.from('reçu opaque', 'utf8')]])],
  ['authData', authData],
]));

// ---- 6. Deux assertions, compteurs 1 puis 2 ----
const assertionFor = (counter, challenge) => {
  const ad = Buffer.concat([rpIdHash, Buffer.from([0x00]), (() => { const b = Buffer.alloc(4); b.writeUInt32BE(counter); return b; })()]);
  const n = crypto.createHash('sha256').update(Buffer.concat([ad, crypto.createHash('sha256').update(challenge, 'utf8').digest()])).digest();
  const signature = crypto.sign('sha256', n, credPriv);
  return cborEncode(new Map([['signature', signature], ['authenticatorData', ad]]));
};

const out = {
  appId: APP_ID,
  challenge: CHALLENGE,
  keyId: credentialId.toString('base64'),
  testRoot: pemToDer(readFileSync('root.pem')).toString('base64'),
  attestation: attestation.toString('base64'),
  assertionCounter1: assertionFor(1, CHALLENGE).toString('base64'),
  assertionCounter2: assertionFor(2, CHALLENGE).toString('base64'),
  assertionOtherChallenge: assertionFor(3, 'un autre défi, jamais délivré').toString('base64'),
};
writeFileSync('fixtures.json', JSON.stringify(out, null, 2));
console.log('fabriqué :', Object.entries(out).map(([k, v]) => `${k}=${v.length}`).join(' '));

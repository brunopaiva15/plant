// Ce que le relais laisse entrer, éprouvé sans iPhone.
//
//   node --experimental-strip-types supabase/functions/relay/attest_test.ts
//   deno run --allow-none supabase/functions/relay/attest_test.ts
//
// Les cas qui comptent sont les refus : une vérification qui accepte ce
// qu'il faut mais laisse aussi passer le reste ne protège rien. Chaque étape
// de la marche à suivre d'Apple a donc ici le test qui la casse.

import { fromBase64, toBase64 } from './bytes.ts';
import { decodeCbor } from './cbor.ts';
import { readNode } from './asn1.ts';
import { parseCertificate, verifySignedBy } from './asn1.ts';
import { appleRootCertificate } from './apple_root.ts';
import { AttestationError, verifyAssertion, verifyAttestation } from './attest.ts';
import type { AttestPolicy } from './attest.ts';
import { mintSession, readSession } from './session.ts';
import { fixtures } from './attest_fixtures.ts';

let failures = 0;
let passes = 0;

async function test(name: string, body: () => void | Promise<void>): Promise<void> {
  try {
    await body();
    passes++;
    console.log(`  ok   ${name}`);
  } catch (error) {
    failures++;
    console.log(`  ÉCHEC ${name}\n       ${(error as Error).message}`);
  }
}

function assert(condition: unknown, message: string): void {
  if (!condition) throw new Error(message);
}

/// Exige que l'appel soit refusé. Un test de refus qui passerait parce que le
/// code a planté ailleurs ne prouve rien : le rejet doit être délibéré.
async function rejects(what: string, body: () => Promise<unknown>): Promise<void> {
  try {
    await body();
  } catch (error) {
    if (error instanceof AttestationError) return;
    throw new Error(`${what} : refusé, mais par une erreur inattendue — ${(error as Error).message}`);
  }
  throw new Error(`${what} : accepté alors qu'il fallait refuser`);
}

const testPolicy: AttestPolicy = {
  appId: fixtures.appId,
  environments: ['development'],
  roots: [fromBase64(fixtures.testRoot)],
};

const attestation = fromBase64(fixtures.attestation);

/// Le même flux, un octet changé.
function tampered(bytes: Uint8Array, at: number): Uint8Array {
  const copy = new Uint8Array(bytes);
  copy[at] ^= 0x01;
  return copy;
}

console.log("\nL'ancre épinglée");
await test("est lisible et signée d'elle-même", async () => {
  const root = parseCertificate(appleRootCertificate());
  assert(root.curve === 'P-384', 'la racine d’Apple est en P-384');
  assert(await verifySignedBy(root, root), 'auto-signature de la racine');
  assert(root.notAfter > Date.now(), 'la racine épinglée a expiré : il faut la remplacer');
});

console.log("\nL'attestation");
await test('est acceptée et rend la clé annoncée', async () => {
  const key = await verifyAttestation(attestation, fixtures.keyId, fixtures.challenge, testPolicy);
  assert(key.keyId === fixtures.keyId, 'identifiant de clé rendu');
  assert(key.counter === 0, 'compteur initial nul');
  assert(key.environment === 'development', 'environnement reconnu');
  assert(key.publicKey.length === 65, 'point non compressé de 65 octets');
  assert(toBase64(key.receipt!).length > 0, 'reçu conservé');
});

await test("est refusée sous un défi qu'on n'a pas délivré", () =>
  rejects('autre défi', () => verifyAttestation(attestation, fixtures.keyId, 'un défi inventé', testPolicy)));

await test('est refusée pour une autre application', () =>
  rejects('autre identifiant d’application', () =>
    verifyAttestation(attestation, fixtures.keyId, fixtures.challenge, { ...testPolicy, appId: 'ZZZZZ99999.ch.exemple.autre' })));

await test('est refusée si le relais n’accepte que la production', () =>
  rejects('environnement de développement', () =>
    verifyAttestation(attestation, fixtures.keyId, fixtures.challenge, { ...testPolicy, environments: ['production'] })));

await test("est refusée sous l'ancre d'Apple, qui n'a pas signé cette chaîne", () =>
  rejects('racine d’Apple', () =>
    verifyAttestation(attestation, fixtures.keyId, fixtures.challenge, { ...testPolicy, roots: undefined })));

await test("est refusée sous un identifiant de clé qui n'est pas le sien", () =>
  rejects('identifiant de clé', () =>
    verifyAttestation(attestation, 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', fixtures.challenge, testPolicy)));

await test('est refusée dès qu’un octet a bougé', async () => {
  // Le dernier octet tombe dans la clé publique COSE, donc dans `authData`,
  // donc dans le nonce ; celui du début, dans la chaîne de certificats.
  await rejects('dernier octet', () =>
    verifyAttestation(tampered(attestation, attestation.length - 1), fixtures.keyId, fixtures.challenge, testPolicy));
  await rejects('octet de la chaîne', () =>
    verifyAttestation(tampered(attestation, 60), fixtures.keyId, fixtures.challenge, testPolicy));
});

await test("est refusée quand la racine de test a expiré", () =>
  rejects('ancre expirée', () =>
    verifyAttestation(attestation, fixtures.keyId, fixtures.challenge, { ...testPolicy, now: Date.parse('2100-01-01T00:00:00Z') })));

console.log("\nL'assertion");
const publicKey = (await verifyAttestation(attestation, fixtures.keyId, fixtures.challenge, testPolicy)).publicKey;
const assertion1 = fromBase64(fixtures.assertionCounter1);
const assertion2 = fromBase64(fixtures.assertionCounter2);

await test('est acceptée et rend son compteur', async () => {
  const first = await verifyAssertion(assertion1, publicKey, fixtures.challenge, 0, testPolicy);
  assert(first.counter === 1, 'compteur de la première assertion');
  const second = await verifyAssertion(assertion2, publicKey, fixtures.challenge, first.counter, testPolicy);
  assert(second.counter === 2, 'compteur de la seconde');
});

await test('est refusée si elle est rejouée', () =>
  rejects('compteur non progressé', () => verifyAssertion(assertion1, publicKey, fixtures.challenge, 1, testPolicy)));

await test("est refusée si elle a été signée sur un autre défi", () =>
  rejects('défi discordant', () =>
    verifyAssertion(fromBase64(fixtures.assertionOtherChallenge), publicKey, fixtures.challenge, 0, testPolicy)));

await test('est refusée pour une autre application', () =>
  rejects('autre identifiant d’application', () =>
    verifyAssertion(assertion1, publicKey, fixtures.challenge, 0, { ...testPolicy, appId: 'ZZZZZ99999.ch.exemple.autre' })));

await test("est refusée dès qu'un octet de la signature a bougé", () =>
  rejects('signature modifiée', () => verifyAssertion(tampered(assertion1, 24), publicKey, fixtures.challenge, 0, testPolicy)));

await test("est refusée sous la clé publique d'un autre appareil", async () => {
  const other = new Uint8Array(publicKey);
  other[1] ^= 0x01;
  await rejects('autre clé', () => verifyAssertion(assertion1, other, fixtures.challenge, 0, testPolicy));
});

console.log('\nLe jeton de session');
await test('se relit, et pas sous un autre secret', async () => {
  const { token } = await mintSession('secret du relais', { sub: 'abc', kind: 'appattest' }, 3600);
  const claims = await readSession('secret du relais', token);
  assert(claims?.sub === 'abc' && claims.kind === 'appattest', 'revendications relues');
  assert((await readSession('un autre secret', token)) === null, 'jeton refusé sous un autre secret');
});

await test('cesse de valoir à son expiration', async () => {
  const now = Date.now();
  const { token } = await mintSession('secret du relais', { sub: 'abc', kind: 'dev' }, 60, now);
  assert((await readSession('secret du relais', token, now + 59_000)) !== null, 'valide avant terme');
  assert((await readSession('secret du relais', token, now + 61_000)) === null, 'périmé après terme');
});

await test("ne se laisse pas relire sans sa signature", async () => {
  const { token } = await mintSession('secret du relais', { sub: 'abc', kind: 'appattest' }, 3600);
  const [head, payload] = token.split('.');
  assert((await readSession('secret du relais', `${head}.${payload}.`)) === null, 'signature vide refusée');
  assert((await readSession('secret du relais', `${head}.${payload}`)) === null, 'jeton tronqué refusé');
});

console.log('\nLes décodeurs');
await test('le CBOR refuse ce qui déborde ou se répète', () => {
  // 0x01 0x01 : un entier, puis un octet de trop.
  let refused = false;
  try { decodeCbor(new Uint8Array([0x01, 0x01])); } catch { refused = true; }
  assert(refused, 'octets en trop refusés');
  // Un dictionnaire de deux entrées dont la clé se répète.
  refused = false;
  try { decodeCbor(new Uint8Array([0xa2, 0x01, 0x01, 0x01, 0x02])); } catch { refused = true; }
  assert(refused, 'clé répétée refusée');
});

await test('le DER refuse une longueur écrite trop large', () => {
  let refused = false;
  // 0x04 0x81 0x01 0x00 : une chaîne d'un octet, dont la longueur tiendrait
  // dans la forme courte.
  try { readNode(new Uint8Array([0x04, 0x81, 0x01, 0x00]), 0); } catch { refused = true; }
  assert(refused, 'longueur non minimale refusée');
});

console.log(`\n${passes} réussis, ${failures} en échec\n`);
if (failures > 0) {
  if (typeof (globalThis as { Deno?: { exit(code: number): never } }).Deno !== 'undefined') {
    (globalThis as unknown as { Deno: { exit(code: number): never } }).Deno.exit(1);
  }
  (globalThis as unknown as { process: { exitCode: number } }).process.exitCode = 1;
}

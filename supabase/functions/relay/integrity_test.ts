// Ce que le relais laisse entrer depuis Android, éprouvé sans téléphone.
//
//   node --experimental-strip-types supabase/functions/relay/integrity_test.ts
//   deno run --allow-none supabase/functions/relay/integrity_test.ts
//
// Comme pour App Attest, ce qui compte ce sont les refus : chaque ligne du
// verdict que le relais lit a ici le test qui la casse.

import { fromBase64, toBase64, toBase64Url } from './bytes.ts';
import {
  checkVerdict,
  decodeIntegrityToken,
  forgetAccessToken,
  integrityRequestHash,
  IntegrityError,
  normalizeDigest,
  parseServiceAccount,
} from './integrity.ts';
import type { IntegrityPolicy } from './integrity.ts';
import { mintSession, readSession } from './session.ts';

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

/// Exige un refus délibéré : un test qui passerait parce que le code a planté
/// ailleurs ne prouve rien.
async function rejects(what: string, body: () => unknown): Promise<void> {
  try {
    await body();
  } catch (error) {
    if (error instanceof IntegrityError) return;
    throw new Error(`${what} : refusé, mais par une erreur inattendue — ${(error as Error).message}`);
  }
  throw new Error(`${what} : accepté alors qu'il fallait refuser`);
}

const now = Date.UTC(2026, 8, 25, 12);
const challenge = 'défi-du-relais-0123456789';
const installId = 'A'.repeat(43);
const digest = 'ab'.repeat(32);
const digestBytes = new Uint8Array(digest.match(/../g)!.map((pair) => parseInt(pair, 16)));

const policy: IntegrityPolicy = { packageName: 'ch.vergasta.plant', certificates: [digest], maxAge: 300_000 };

/// Un verdict comme Google le rend pour le vrai Auxine, sur un vrai
/// téléphone, pour ce défi-ci. Chaque test en casse une ligne.
// deno-lint-ignore no-explicit-any
async function genuine(): Promise<Record<string, any>> {
  return {
    requestDetails: {
      requestPackageName: 'ch.vergasta.plant',
      requestHash: await integrityRequestHash(challenge, installId),
      timestampMillis: String(now - 2_000),
    },
    appIntegrity: {
      appRecognitionVerdict: 'PLAY_RECOGNIZED',
      packageName: 'ch.vergasta.plant',
      // Le verdict porte l'empreinte en base64url.
      certificateSha256Digest: [toBase64Url(digestBytes)],
      versionCode: '26',
    },
    deviceIntegrity: { deviceRecognitionVerdict: ['MEETS_DEVICE_INTEGRITY'] },
    accountDetails: { appLicensingVerdict: 'LICENSED' },
  };
}

console.log('\nLe verdict');

await test('le vrai Auxine, sur un vrai téléphone, passe', async () => {
  checkVerdict(await genuine(), await integrityRequestHash(challenge, installId), policy, now);
});

await test('sans empreinte configurée, PLAY_RECOGNIZED suffit', async () => {
  const verdict = await genuine();
  verdict.appIntegrity.certificateSha256Digest = ['autre'];
  checkVerdict(verdict, await integrityRequestHash(challenge, installId), { ...policy, certificates: [] }, now);
});

await test('un jeton obtenu pour un autre défi est refusé', async () => {
  const verdict = await genuine();
  await rejects('autre défi', async () => checkVerdict(verdict, await integrityRequestHash('un-autre-défi-0000000', installId), policy, now));
});

await test("un jeton volé à une autre installation est refusé", async () => {
  const verdict = await genuine();
  await rejects('autre installation', async () => checkVerdict(verdict, await integrityRequestHash(challenge, 'B'.repeat(43)), policy, now));
});

await test('un jeton trop vieux est refusé', async () => {
  const verdict = await genuine();
  verdict.requestDetails.timestampMillis = String(now - 600_000);
  await rejects('périmé', async () => checkVerdict(verdict, await integrityRequestHash(challenge, installId), policy, now));
});

await test("une demande faite au nom d'un autre paquet est refusée", async () => {
  const verdict = await genuine();
  verdict.requestDetails.requestPackageName = 'com.exemple.copie';
  await rejects('autre paquet', async () => checkVerdict(verdict, await integrityRequestHash(challenge, installId), policy, now));
});

await test("un binaire que Google Play n'a pas distribué est refusé", async () => {
  const verdict = await genuine();
  verdict.appIntegrity.appRecognitionVerdict = 'UNRECOGNIZED_VERSION';
  await rejects('non reconnu', async () => checkVerdict(verdict, await integrityRequestHash(challenge, installId), policy, now));
});

await test('une signature inconnue est refusée', async () => {
  const verdict = await genuine();
  verdict.appIntegrity.certificateSha256Digest = ['AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'];
  await rejects('signature', async () => checkVerdict(verdict, await integrityRequestHash(challenge, installId), policy, now));
});

await test('un système modifié ou un émulateur est refusé', async () => {
  const verdict = await genuine();
  verdict.deviceIntegrity.deviceRecognitionVerdict = ['MEETS_BASIC_INTEGRITY'];
  await rejects('appareil', async () => checkVerdict(verdict, await integrityRequestHash(challenge, installId), policy, now));
});

await test('un verdict vide est refusé', async () => {
  await rejects('vide', async () => checkVerdict({}, await integrityRequestHash(challenge, installId), policy, now));
  await rejects('nul', async () => checkVerdict(null, await integrityRequestHash(challenge, installId), policy, now));
});

console.log('\nLes empreintes');

await test('les trois écritures se ramènent à la même', () => {
  const colons = digest.toUpperCase().match(/../g)!.join(':');
  const base64url = toBase64Url(digestBytes);
  assert(normalizeDigest(colons) === digest, `console Play : ${normalizeDigest(colons)}`);
  assert(normalizeDigest(digest.toUpperCase()) === digest, 'hexadécimal');
  assert(normalizeDigest(base64url) === digest, `base64url : ${normalizeDigest(base64url)}`);
});

await test('le condensé scelle le défi et l’installation ensemble', async () => {
  const a = await integrityRequestHash(challenge, installId);
  assert(/^[0-9a-f]{64}$/.test(a), `forme : ${a}`);
  assert(a === (await integrityRequestHash(challenge, installId)), 'stable');
  assert(a !== (await integrityRequestHash(challenge, 'B'.repeat(43))), "dépend de l'installation");
  // Le même vecteur que `test/core/relay_client_test.dart` : l'application
  // et le relais doivent calculer le même condensé, octet pour octet.
  const vector = await integrityRequestHash('abc', 'xyz');
  assert(vector === '8806d08be1da6bafefb3c5a7fa0f9f70cda3b288246021f6f9f5050ad3457063', `vecteur : ${vector}`);
});

console.log('\nGoogle');

const keys = await crypto.subtle.generateKey(
  { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
  true,
  ['sign', 'verify'],
);
const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', keys.privateKey));
const pem = `-----BEGIN PRIVATE KEY-----\n${toBase64(pkcs8).match(/.{1,64}/g)!.join('\n')}\n-----END PRIVATE KEY-----\n`;
const account = parseServiceAccount(JSON.stringify({ client_email: 'relais@auxine.iam.gserviceaccount.com', private_key: pem }))!;

/// Un Google de papier : il vérifie la signature du compte de service, rend
/// un jeton d'accès, puis le verdict qu'on lui a donné.
function fakeGoogle(verdictStatus = 200) {
  const calls: string[] = [];
  const fetcher = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push(url);
    if (url === 'https://oauth2.googleapis.com/token') {
      const form = new URLSearchParams(String(init?.body));
      const [head, claims, signature] = form.get('assertion')!.split('.');
      const valid = await crypto.subtle.verify(
        'RSASSA-PKCS1-v1_5',
        keys.publicKey,
        fromBase64(signature) as unknown as BufferSource,
        new TextEncoder().encode(`${head}.${claims}`),
      );
      const body = JSON.parse(new TextDecoder().decode(fromBase64(claims)));
      if (!valid || body.scope !== 'https://www.googleapis.com/auth/playintegrity') return new Response('{}', { status: 401 });
      return Response.json({ access_token: 'accès-google', expires_in: 3600 });
    }
    const auth = new Headers(init?.headers).get('authorization');
    if (auth !== 'Bearer accès-google') return new Response('{}', { status: 401 });
    if (verdictStatus !== 200) return new Response('{}', { status: verdictStatus });
    return Response.json({ tokenPayloadExternal: { lu: JSON.parse(String(init?.body)).integrity_token } });
  }) as typeof fetch;
  return { calls, fetcher };
}

await test('le jeton est déchiffré par Google, avec le compte de service', async () => {
  forgetAccessToken();
  const google = fakeGoogle();
  const verdict = (await decodeIntegrityToken('jeton-opaque', 'ch.vergasta.plant', account, google.fetcher, now)) as { lu: string };
  assert(verdict.lu === 'jeton-opaque', 'verdict rendu');
  assert(google.calls[1] === 'https://playintegrity.googleapis.com/v1/ch.vergasta.plant:decodeIntegrityToken', google.calls[1]);
});

await test("le jeton d'accès se garde d'une poignée de main à l'autre", async () => {
  forgetAccessToken();
  const google = fakeGoogle();
  await decodeIntegrityToken('un', 'ch.vergasta.plant', account, google.fetcher, now);
  await decodeIntegrityToken('deux', 'ch.vergasta.plant', account, google.fetcher, now + 60_000);
  assert(google.calls.filter((c) => c.includes('oauth2')).length === 1, `échanges OAuth : ${google.calls.length}`);
});

await test('un jeton que Google ne sait pas lire est un refus', async () => {
  forgetAccessToken();
  await rejects('illisible', () => decodeIntegrityToken('abîmé', 'ch.vergasta.plant', account, fakeGoogle(400).fetcher, now));
});

await test("un Google qui ne répond pas est une panne, pas un refus", async () => {
  forgetAccessToken();
  try {
    await decodeIntegrityToken('jeton', 'ch.vergasta.plant', account, fakeGoogle(503).fetcher, now);
    throw new Error('accepté');
  } catch (error) {
    assert(!(error instanceof IntegrityError), 'la panne ne doit pas se lire comme un refus');
  }
});

await test('un compte de service mal formé ne se lit pas', () => {
  assert(parseServiceAccount('') === null, 'vide');
  assert(parseServiceAccount('{') === null, 'illisible');
  assert(parseServiceAccount('{"client_email":"x"}') === null, 'sans clé');
});

console.log('\nLe jeton de session');

await test("une séance ouverte par Play Integrity se relit", async () => {
  const { token } = await mintSession('secret du relais', { sub: `play:${installId}`, kind: 'playintegrity' }, 3600);
  const claims = await readSession('secret du relais', token);
  assert(claims?.kind === 'playintegrity' && claims.sub === `play:${installId}`, JSON.stringify(claims));
});

console.log(`\n${passes} réussis, ${failures} en échec\n`);
if (failures > 0) {
  if (typeof (globalThis as { Deno?: { exit(code: number): never } }).Deno !== 'undefined') {
    (globalThis as unknown as { Deno: { exit(code: number): never } }).Deno.exit(1);
  }
  (globalThis as unknown as { process: { exitCode: number } }).process.exitCode = 1;
}

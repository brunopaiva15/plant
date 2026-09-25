// App Attest, côté serveur.
//
// Ce que le mécanisme prouve, et ce qu'il ne prouve pas. La Secure Enclave
// d'un appareil Apple fabrique une paire de clés dont la partie privée ne
// sort jamais, et Apple signe un certificat attestant que cette clé est née
// là, dans *cette* application — l'identifiant d'équipe et celui du paquet
// sont dans la chaîne. Le relais qui vérifie cette chaîne sait donc qu'il
// parle au vrai Auxine, sur un vrai iPhone. Il ne sait rien de la personne
// qui le tient, et n'a pas à le savoir : aucune donnée de compte n'entre ici.
//
// Ce que ça ne prouve pas : qu'une requête est sincère. Un appareil légitime
// dont quelqu'un détourne l'application reste un appareil légitime. C'est
// pourquoi l'attestation ne remplace pas les quotas — elle borne le nombre
// d'attaquants possibles, les quotas bornent ce que chacun coûte.
//
// La marche à suivre est celle d'Apple, « Validating Apps That Connect to
// Your Server ». Chaque étape ci-dessous porte son numéro.

import { concat, sha256, timingSafeEqual, toBase64, utf8 } from './bytes.ts';
import { cborBytes, cborMap, decodeCbor } from './cbor.ts';
import { appleRootCertificate } from './apple_root.ts';
import type { Certificate } from './asn1.ts';
import { children, content, ecdsaSignatureToRaw, parseCertificate, readNode, verifySignedBy } from './asn1.ts';
import { verifyEcdsa } from './ecdsa.ts';

export class AttestationError extends Error {}

/// L'extension où Apple range le nonce du certificat d'appareil.
const NONCE_EXTENSION = '1.2.840.113635.100.8.2';

/// Les deux mondes d'App Attest. Un binaire compilé en debug ou distribué par
/// TestFlight depuis Xcode attesterait dans le premier ; une application de
/// l'App Store, dans le second. Le relais dit lequel il accepte, et accepter
/// le développement en production reviendrait à laisser entrer n'importe quel
/// appareil de développement enregistré.
const AAGUIDS: Record<string, Uint8Array> = {
  development: utf8('appattestdevelop'),
  // « appattest » suivi de sept octets nuls : seize en tout.
  production: concat(utf8('appattest'), new Uint8Array(7)),
};

export type AttestEnvironment = keyof typeof AAGUIDS;

export interface AttestPolicy {
  /// « <identifiant d'équipe>.<identifiant du paquet> », par exemple
  /// « ABCDE12345.ch.vergasta.plant ».
  readonly appId: string;
  readonly environments: readonly AttestEnvironment[];
  /// Les ancres acceptées. Celle d'Apple par défaut ; les tests en passent
  /// une à eux, pour éprouver la vérification sans appareil.
  readonly roots?: readonly Uint8Array[];
  readonly now?: number;
}

export interface AttestedKey {
  /// L'identifiant rendu par `DCAppAttestService.generateKey`, en base64 :
  /// le condensé SHA-256 de la clé publique.
  readonly keyId: string;
  /// Le point de la courbe, non compressé. C'est lui qu'on garde pour
  /// vérifier les assertions suivantes.
  readonly publicKey: Uint8Array;
  readonly counter: number;
  readonly environment: AttestEnvironment;
  /// Le reçu d'Apple, opaque ici. Gardé tel quel : il sert à interroger le
  /// service de risque d'Apple, ce que le relais ne fait pas encore.
  readonly receipt: Uint8Array | null;
}

/// Les données d'authentification, telles que la spécification WebAuthn les
/// découpe et qu'App Attest les reprend.
interface AuthenticatorData {
  readonly rpIdHash: Uint8Array;
  readonly counter: number;
  readonly aaguid: Uint8Array | null;
  readonly credentialId: Uint8Array | null;
}

function parseAuthenticatorData(bytes: Uint8Array, expectCredential: boolean): AuthenticatorData {
  if (bytes.length < 37) throw new AttestationError('données d’authentification trop courtes');
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const rpIdHash = bytes.subarray(0, 32);
  const flags = bytes[32];
  const counter = view.getUint32(33, false);

  if (!expectCredential) return { rpIdHash, counter, aaguid: null, credentialId: null };

  // Le drapeau AT annonce les données de la clé ; sans lui, l'attestation ne
  // porte pas de clé et il n'y a rien à enregistrer.
  if ((flags & 0x40) === 0) throw new AttestationError('attestation sans données de clé');
  if (bytes.length < 55) throw new AttestationError('données de clé tronquées');
  const length = view.getUint16(53, false);
  if (bytes.length < 55 + length) throw new AttestationError('identifiant de clé tronqué');
  return {
    rpIdHash,
    counter,
    aaguid: bytes.subarray(37, 53),
    credentialId: bytes.subarray(55, 55 + length),
  };
}

/// Le nonce qu'Apple a scellé dans le certificat : une SEQUENCE qui ne
/// contient qu'un contexte [1], lequel ne contient qu'une chaîne d'octets.
function extensionNonce(certificate: Certificate): Uint8Array {
  const extension = certificate.extensions.get(NONCE_EXTENSION);
  if (!extension) throw new AttestationError('certificat sans nonce Apple');
  const der = extension.value;
  const outer = readNode(der, 0);
  if (outer.tag !== 0x30) throw new AttestationError('nonce mal formé');
  const [context] = children(der, outer);
  if (!context || context.tag !== 0xa1) throw new AttestationError('nonce mal formé');
  const [octets] = children(der, context);
  if (!octets || octets.tag !== 0x04) throw new AttestationError('nonce mal formé');
  return content(der, octets);
}

/// Remonte la chaîne jusqu'à une ancre acceptée. La chaîne fournie par
/// l'appareil s'arrête à l'intermédiaire : la racine, elle, vient d'ici.
async function verifyChain(chain: Certificate[], roots: readonly Certificate[], now: number): Promise<void> {
  if (chain.length === 0) throw new AttestationError('chaîne vide');
  for (const certificate of chain) {
    if (now < certificate.notBefore || now > certificate.notAfter) {
      throw new AttestationError('certificat hors de sa période de validité');
    }
  }
  // Chaque maillon signe le précédent…
  for (let i = 0; i < chain.length - 1; i++) {
    if (!(await verifySignedBy(chain[i], chain[i + 1]))) {
      throw new AttestationError('chaîne rompue');
    }
  }
  // …et le dernier doit l'être par une ancre que le relais connaît.
  const last = chain[chain.length - 1];
  for (const root of roots) {
    if (now < root.notBefore || now > root.notAfter) continue;
    if (await verifySignedBy(last, root)) return;
  }
  throw new AttestationError('chaîne non rattachée à une ancre connue');
}

const anchors = (policy: AttestPolicy): Certificate[] =>
  (policy.roots ?? [appleRootCertificate()]).map(parseCertificate);

/// Ce sur quoi porte la signature : le défi, tel que le relais l'a écrit.
///
/// Apple laisse le contenu libre — c'est « clientData » —, à condition que
/// les deux bords en fassent le même condensé. Le plus simple qui tienne :
/// les octets UTF-8 du défi. Le défi étant tiré au sort, à usage unique et de
/// courte vie, une assertion ne vaut que pour l'échange qui l'a demandée.
const clientDataHash = (challenge: string): Promise<Uint8Array> => sha256(utf8(challenge));

/// L'enregistrement d'un appareil : la seule étape où Apple intervient.
export async function verifyAttestation(
  attestation: Uint8Array,
  keyId: string,
  challenge: string,
  policy: AttestPolicy,
): Promise<AttestedKey> {
  const now = policy.now ?? Date.now();

  let object: Map<string | number | bigint, unknown>;
  try {
    object = cborMap(decodeCbor(attestation)) as Map<string | number | bigint, unknown>;
  } catch (error) {
    throw new AttestationError(`attestation illisible : ${(error as Error).message}`);
  }
  if (object.get('fmt') !== 'apple-appattest') throw new AttestationError('format d’attestation inattendu');

  let statement: Map<string | number | bigint, unknown>;
  try {
    statement = cborMap(object.get('attStmt') as never) as Map<string | number | bigint, unknown>;
  } catch (error) {
    throw new AttestationError(`attestation incomplète : ${(error as Error).message}`);
  }
  const x5c = statement.get('x5c');
  if (!Array.isArray(x5c) || x5c.length === 0) throw new AttestationError('chaîne de certificats absente');
  // Deux maillons suffisent et Apple n'en envoie pas plus ; borner évite de
  // faire travailler le relais sur une chaîne fabriquée pour l'occuper.
  if (x5c.length > 4) throw new AttestationError('chaîne de certificats trop longue');

  let chain: Certificate[];
  try {
    chain = x5c.map((entry, i) => parseCertificate(cborBytes(entry as never, `certificat ${i}`)));
  } catch (error) {
    throw new AttestationError(`certificat illisible : ${(error as Error).message}`);
  }

  // 1. La chaîne remonte-t-elle à Apple ?
  await verifyChain(chain, anchors(policy), now);

  let authData: Uint8Array;
  try {
    authData = cborBytes(object.get('authData') as never, 'authData');
  } catch (error) {
    throw new AttestationError(`attestation incomplète : ${(error as Error).message}`);
  }

  // 2 et 3. Le nonce se recalcule à partir de ce que l'appareil a envoyé.
  const nonce = await sha256(concat(authData, await clientDataHash(challenge)));

  // 4. Et il doit être celui qu'Apple a scellé dans le certificat d'appareil.
  const credCert = chain[0];
  if (!timingSafeEqual(nonce, extensionNonce(credCert))) {
    throw new AttestationError('nonce de l’attestation non conforme');
  }

  // 5. La clé publique du certificat est bien celle que l'appareil annonce.
  const digest = await sha256(credCert.publicKey);
  const parsed = parseAuthenticatorData(authData, true);
  if (!timingSafeEqual(digest, parsed.credentialId!)) {
    throw new AttestationError('clé publique et identifiant discordants');
  }
  // 9. Et c'est bien la clé dont l'appareil a donné l'identifiant.
  if (toBase64(digest) !== keyId) throw new AttestationError('identifiant de clé inattendu');

  // 6. L'attestation vient-elle de cette application-ci ?
  if (!timingSafeEqual(parsed.rpIdHash, await sha256(utf8(policy.appId)))) {
    throw new AttestationError('attestation émise pour une autre application');
  }

  // 7. Une clé qui vient de naître n'a encore rien signé.
  if (parsed.counter !== 0) throw new AttestationError('compteur d’attestation non nul');

  // 8. Développement ou production, selon ce que le relais accepte.
  const environment = policy.environments.find((name) => timingSafeEqual(parsed.aaguid!, AAGUIDS[name]));
  if (!environment) throw new AttestationError('environnement d’attestation refusé');

  const receipt = statement.get('receipt');
  return {
    keyId,
    publicKey: credCert.publicKey,
    counter: 0,
    environment,
    receipt: receipt instanceof Uint8Array ? receipt : null,
  };
}

/// Les échanges suivants : l'appareil signe le défi avec la clé qu'Apple a
/// attestée, et le relais n'a plus besoin d'Apple pour le croire.
export async function verifyAssertion(
  assertion: Uint8Array,
  publicKey: Uint8Array,
  challenge: string,
  previousCounter: number,
  policy: AttestPolicy,
): Promise<{ counter: number }> {
  let object: Map<string | number | bigint, unknown>;
  try {
    object = cborMap(decodeCbor(assertion)) as Map<string | number | bigint, unknown>;
  } catch (error) {
    throw new AttestationError(`assertion illisible : ${(error as Error).message}`);
  }

  let signature: Uint8Array;
  let authData: Uint8Array;
  try {
    signature = cborBytes(object.get('signature') as never, 'signature');
    authData = cborBytes(object.get('authenticatorData') as never, 'authenticatorData');
  } catch (error) {
    throw new AttestationError(`assertion incomplète : ${(error as Error).message}`);
  }
  const parsed = parseAuthenticatorData(authData, false);

  if (!timingSafeEqual(parsed.rpIdHash, await sha256(utf8(policy.appId)))) {
    throw new AttestationError('assertion émise pour une autre application');
  }

  // Le compteur de la Secure Enclave monte d'au moins un à chaque signature.
  // S'il n'a pas bougé, c'est qu'on rejoue une assertion déjà vue — et le
  // défi à usage unique l'aurait déjà arrêtée, mais deux verrous valent mieux
  // qu'un sur le seul mécanisme qui tienne l'entrée.
  if (parsed.counter <= previousCounter) throw new AttestationError('compteur d’assertion non progressé');

  const nonce = await sha256(concat(authData, await clientDataHash(challenge)));

  let raw: Uint8Array;
  try {
    raw = ecdsaSignatureToRaw(signature, 'P-256');
  } catch {
    throw new AttestationError('signature mal formée');
  }
  // Une clé illisible — hors courbe, ou écrite autrement par une version
  // antérieure du relais — fait échouer la vérification sans lever : c'est
  // un appareil à réenregistrer, pas une panne. La Web Crypto de Deno, elle,
  // ne signalait une telle clé qu'au moment de vérifier, par une exception
  // que rien n'attrapait (`ecdsa.ts`).
  if (!(await verifyEcdsa('P-256', 'SHA-256', publicKey, raw, nonce))) {
    throw new AttestationError('signature d’assertion invalide');
  }

  return { counter: parsed.counter };
}

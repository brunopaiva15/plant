// Lecture DER et découpe d'un certificat X.509, réduites à ce que la chaîne
// d'App Attest demande.
//
// Deno n'expose pas de parseur de certificats, et la Web Crypto ne sait
// importer qu'un `SubjectPublicKeyInfo` déjà isolé. Il faut donc ouvrir le
// DER soi-même pour trois choses : les octets exacts du `tbsCertificate`
// (c'est sur eux que porte la signature), la clé publique de chaque maillon,
// et l'extension où Apple range le nonce. Le reste du certificat n'est pas lu.
//
// Le DER n'admet qu'une écriture par valeur, et ce module s'y tient : une
// longueur écrite plus large que nécessaire, un entier à zéros de tête, sont
// refusés. La souplesse ici ouvrirait deux lectures d'un même flux, ce qui
// est exactement ce dont vit une attaque sur une chaîne de certificats.

import { source } from './bytes.ts';

export interface DerNode {
  readonly tag: number;
  /// Bornes du contenu, sans l'en-tête.
  readonly start: number;
  readonly end: number;
  /// Bornes de la valeur entière, en-tête compris : ce qu'il faut hacher.
  readonly from: number;
  readonly to: number;
}

export function readNode(bytes: Uint8Array, offset: number): DerNode {
  if (offset + 2 > bytes.length) throw new Error('der: en-tête tronqué');
  const tag = bytes[offset];
  // Les étiquettes sur plusieurs octets (0x1f) ne paraissent pas dans un
  // certificat X.509 ordinaire.
  if ((tag & 0x1f) === 0x1f) throw new Error('der: étiquette longue non prise en charge');

  const first = bytes[offset + 1];
  let start = offset + 2;
  let length: number;

  if (first < 0x80) {
    length = first;
  } else if (first === 0x80) {
    throw new Error('der: longueur indéfinie interdite');
  } else {
    const count = first & 0x7f;
    if (count > 4) throw new Error('der: longueur démesurée');
    if (offset + 2 + count > bytes.length) throw new Error('der: longueur tronquée');
    length = 0;
    for (let i = 0; i < count; i++) length = length * 256 + bytes[offset + 2 + i];
    // DER exige la forme la plus courte : 0x81 0x7f, par exemple, est un
    // doublon de 0x7f et n'a pas à être accepté.
    if (length < 0x80 || (count > 1 && length < 1 << ((count - 1) * 8 - 1))) {
      throw new Error('der: longueur non minimale');
    }
    start = offset + 2 + count;
  }

  const end = start + length;
  if (end > bytes.length) throw new Error('der: contenu hors flux');
  return { tag, start, end, from: offset, to: end };
}

/// Les enfants immédiats d'une valeur construite (SEQUENCE, SET, contexte).
export function children(bytes: Uint8Array, node: DerNode): DerNode[] {
  const out: DerNode[] = [];
  let offset = node.start;
  while (offset < node.end) {
    const child = readNode(bytes, offset);
    out.push(child);
    offset = child.to;
  }
  if (offset !== node.end) throw new Error('der: enfants débordants');
  return out;
}

export const slice = (bytes: Uint8Array, node: DerNode): Uint8Array =>
  new Uint8Array(bytes.subarray(node.from, node.to));

export const content = (bytes: Uint8Array, node: DerNode): Uint8Array =>
  new Uint8Array(bytes.subarray(node.start, node.end));

const TAG_INTEGER = 0x02;
const TAG_BIT_STRING = 0x03;
const TAG_OCTET_STRING = 0x04;
const TAG_OID = 0x06;
const TAG_SEQUENCE = 0x30;
const TAG_UTC_TIME = 0x17;
const TAG_GENERALIZED_TIME = 0x18;

function expect(node: DerNode, tag: number, what: string): DerNode {
  if (node.tag !== tag) throw new Error(`der: ${what} attendu (0x${tag.toString(16)}), vu 0x${node.tag.toString(16)}`);
  return node;
}

/// Un OID sous sa forme pointée. Le premier octet porte deux arcs ; les
/// suivants sont en base 128, le bit de poids fort marquant la suite.
export function readOid(bytes: Uint8Array, node: DerNode): string {
  expect(node, TAG_OID, 'identifiant d’objet');
  const body = bytes.subarray(node.start, node.end);
  if (body.length === 0) throw new Error('der: identifiant vide');
  const arcs: number[] = [Math.floor(body[0] / 40), body[0] % 40];
  let value = 0;
  for (let i = 1; i < body.length; i++) {
    if (value === 0 && body[i] === 0x80) throw new Error('der: arc à zéro de tête');
    value = value * 128 + (body[i] & 0x7f);
    if ((body[i] & 0x80) === 0) {
      arcs.push(value);
      value = 0;
    }
  }
  if (value !== 0) throw new Error('der: identifiant tronqué');
  return arcs.join('.');
}

/// Le contenu d'un BIT STRING, l'octet des bits inutilisés retiré. Dans un
/// certificat, ce compte vaut toujours zéro : une clé et une signature font
/// un nombre entier d'octets.
export function readBitString(bytes: Uint8Array, node: DerNode): Uint8Array {
  expect(node, TAG_BIT_STRING, 'chaîne de bits');
  if (node.end - node.start < 1) throw new Error('der: chaîne de bits vide');
  if (bytes[node.start] !== 0) throw new Error('der: bits inutilisés non nuls');
  return new Uint8Array(bytes.subarray(node.start + 1, node.end));
}

/// Un entier positif, ses zéros de tête retirés — la forme brute qu'attend
/// la Web Crypto pour une moitié de signature ECDSA.
export function readPositiveInteger(bytes: Uint8Array, node: DerNode): Uint8Array {
  expect(node, TAG_INTEGER, 'entier');
  const body = bytes.subarray(node.start, node.end);
  if (body.length === 0) throw new Error('der: entier vide');
  if (body[0] & 0x80) throw new Error('der: entier négatif');
  // Un seul zéro de tête est licite, et seulement pour désarmer le bit de
  // signe de l'octet suivant.
  if (body.length > 1 && body[0] === 0 && (body[1] & 0x80) === 0) throw new Error('der: entier non minimal');
  const first = body[0] === 0 ? 1 : 0;
  return new Uint8Array(body.subarray(first));
}

function readTime(bytes: Uint8Array, node: DerNode): number {
  const text = new TextDecoder().decode(bytes.subarray(node.start, node.end));
  if (node.tag === TAG_UTC_TIME) {
    const m = /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/.exec(text);
    if (!m) throw new Error('der: date UTC illisible');
    // RFC 5280 : deux chiffres, et le siècle bascule à 50.
    const year = Number(m[1]) >= 50 ? 1900 + Number(m[1]) : 2000 + Number(m[1]);
    return Date.UTC(year, Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]), Number(m[6]));
  }
  if (node.tag === TAG_GENERALIZED_TIME) {
    const m = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/.exec(text);
    if (!m) throw new Error('der: date généralisée illisible');
    return Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]), Number(m[6]));
  }
  throw new Error('der: type de date inattendu');
}

/// Les courbes qu'Apple emploie dans cette chaîne, et rien d'autre : la
/// racine est en P-384, les certificats d'appareil en P-256.
const CURVES: Record<string, 'P-256' | 'P-384'> = {
  '1.2.840.10045.3.1.7': 'P-256',
  '1.3.132.0.34': 'P-384',
};

/// Les algorithmes de signature acceptés, avec le condensé qui va avec.
const SIGNATURE_HASHES: Record<string, 'SHA-256' | 'SHA-384'> = {
  '1.2.840.10045.4.3.2': 'SHA-256',
  '1.2.840.10045.4.3.3': 'SHA-384',
};

export interface Certificate {
  /// Les octets signés, en-tête compris.
  readonly tbs: Uint8Array;
  readonly signatureAlgorithm: string;
  /// La signature telle qu'elle est écrite : SEQUENCE { r, s }.
  readonly signature: Uint8Array;
  /// Le `SubjectPublicKeyInfo` entier, tel que la Web Crypto l'importe.
  readonly spki: Uint8Array;
  /// Le point de la courbe, non compressé (0x04 ‖ x ‖ y).
  readonly publicKey: Uint8Array;
  readonly curve: 'P-256' | 'P-384';
  /// Les noms bruts, comparés octet à octet d'un maillon à l'autre.
  readonly issuer: Uint8Array;
  readonly subject: Uint8Array;
  readonly notBefore: number;
  readonly notAfter: number;
  readonly extensions: ReadonlyMap<string, { critical: boolean; value: Uint8Array }>;
}

/// Ouvre un certificat. Ne lit que ce dont la vérification a besoin ; tout
/// champ absent ou d'un type inattendu arrête la lecture.
export function parseCertificate(der: Uint8Array): Certificate {
  const root = expect(readNode(der, 0), TAG_SEQUENCE, 'certificat');
  if (root.to !== der.length) throw new Error('der: octets après le certificat');
  const [tbsNode, algorithmNode, signatureNode] = children(der, root);
  if (!tbsNode || !algorithmNode || !signatureNode) throw new Error('der: certificat incomplet');

  const tbsChildren = children(der, expect(tbsNode, TAG_SEQUENCE, 'tbsCertificate'));
  // Le numéro de version est optionnel et marqué [0] ; sans lui, la
  // numérotation des champs glisse d'un cran.
  let index = tbsChildren[0]?.tag === 0xa0 ? 1 : 0;
  index++; // numéro de série
  index++; // algorithme de signature, répété
  const issuerNode = tbsChildren[index++];
  const validityNode = tbsChildren[index++];
  const subjectNode = tbsChildren[index++];
  const spkiNode = tbsChildren[index++];
  if (!issuerNode || !validityNode || !subjectNode || !spkiNode) throw new Error('der: tbsCertificate incomplet');

  const [notBeforeNode, notAfterNode] = children(der, expect(validityNode, TAG_SEQUENCE, 'validité'));
  const [spkiAlgorithm, spkiKey] = children(der, expect(spkiNode, TAG_SEQUENCE, 'clé publique'));
  const [keyTypeNode, keyCurveNode] = children(der, expect(spkiAlgorithm, TAG_SEQUENCE, 'algorithme de clé'));
  if (readOid(der, keyTypeNode) !== '1.2.840.10045.2.1') throw new Error('der: clé non elliptique');
  if (!keyCurveNode) throw new Error('der: courbe absente');
  const curve = CURVES[readOid(der, keyCurveNode)];
  if (!curve) throw new Error('der: courbe non prise en charge');

  const publicKey = readBitString(der, spkiKey);
  if (publicKey[0] !== 0x04) throw new Error('der: point compressé non pris en charge');

  const extensions = new Map<string, { critical: boolean; value: Uint8Array }>();
  const extensionsNode = tbsChildren.slice(index).find((node) => node.tag === 0xa3);
  if (extensionsNode) {
    const [list] = children(der, extensionsNode);
    for (const node of children(der, expect(list, TAG_SEQUENCE, 'extensions'))) {
      const parts = children(der, expect(node, TAG_SEQUENCE, 'extension'));
      const oid = readOid(der, parts[0]);
      // `critical` est un booléen optionnel avant la valeur.
      const critical = parts.length === 3 && der[parts[1].start] !== 0;
      const valueNode = parts[parts.length - 1];
      extensions.set(oid, { critical, value: content(der, expect(valueNode, TAG_OCTET_STRING, 'valeur d’extension')) });
    }
  }

  return {
    tbs: slice(der, tbsNode),
    signatureAlgorithm: readOid(der, children(der, expect(algorithmNode, TAG_SEQUENCE, 'algorithme'))[0]),
    signature: readBitString(der, signatureNode),
    spki: slice(der, spkiNode),
    publicKey,
    curve,
    issuer: slice(der, issuerNode),
    subject: slice(der, subjectNode),
    notBefore: readTime(der, notBeforeNode),
    notAfter: readTime(der, notAfterNode),
    extensions,
  };
}

/// La signature ECDSA passe du DER — SEQUENCE { r, s } — au couple d'octets
/// de taille fixe que la Web Crypto attend. La taille vient de la courbe du
/// signataire, pas de ce que la signature mesure.
export function ecdsaSignatureToRaw(der: Uint8Array, curve: 'P-256' | 'P-384'): Uint8Array {
  const size = curve === 'P-256' ? 32 : 48;
  const root = expect(readNode(der, 0), TAG_SEQUENCE, 'signature');
  if (root.to !== der.length) throw new Error('der: octets après la signature');
  const [rNode, sNode] = children(der, root);
  if (!rNode || !sNode) throw new Error('der: signature incomplète');
  const raw = new Uint8Array(size * 2);
  for (const [i, node] of [rNode, sNode].entries()) {
    const value = readPositiveInteger(der, node);
    if (value.length > size) throw new Error('der: composante de signature trop longue');
    raw.set(value, size * (i + 1) - value.length);
  }
  return raw;
}

/// Vérifie qu'un certificat a bien été signé par un autre : même nom d'un
/// maillon à l'autre, algorithme connu, et signature valide sur les octets
/// du `tbsCertificate`.
export async function verifySignedBy(certificate: Certificate, issuer: Certificate): Promise<boolean> {
  if (certificate.issuer.length !== issuer.subject.length) return false;
  if (!certificate.issuer.every((byte, i) => byte === issuer.subject[i])) return false;

  const hash = SIGNATURE_HASHES[certificate.signatureAlgorithm];
  if (!hash) return false;

  const key = await crypto.subtle.importKey(
    'spki',
    source(issuer.spki),
    { name: 'ECDSA', namedCurve: issuer.curve },
    false,
    ['verify'],
  );
  let raw: Uint8Array;
  try {
    raw = ecdsaSignatureToRaw(certificate.signature, issuer.curve);
  } catch {
    return false;
  }
  return crypto.subtle.verify({ name: 'ECDSA', hash }, key, source(raw), source(certificate.tbs));
}

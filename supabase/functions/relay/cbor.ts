// Décodeur CBOR (RFC 8949), réduit à ce qu'Apple écrit.
//
// Trois structures d'App Attest sont en CBOR : l'objet d'attestation
// (`fmt`, `attStmt`, `authData`), l'assertion (`signature`,
// `authenticatorData`) et la clé publique COSE nichée dans `authData`. Toutes
// s'en tiennent aux longueurs définies et aux types simples ; ce qui sort de
// là est refusé plutôt que deviné — un décodeur permissif sur des octets
// qu'un attaquant fournit est une surface offerte pour rien.

export type CborValue =
  | number
  | bigint
  | string
  | Uint8Array
  | boolean
  | null
  | CborValue[]
  | Map<string | number | bigint, CborValue>;

class Reader {
  private readonly bytes: Uint8Array;

  constructor(bytes: Uint8Array) {
    this.bytes = bytes;
  }

  offset = 0;

  private byte(): number {
    if (this.offset >= this.bytes.length) throw new Error('cbor: fin de flux');
    return this.bytes[this.offset++];
  }

  private take(length: number): Uint8Array {
    if (length < 0 || this.offset + length > this.bytes.length) throw new Error('cbor: longueur hors flux');
    const slice = this.bytes.subarray(this.offset, this.offset + length);
    this.offset += length;
    return slice;
  }

  /// L'argument d'un en-tête : la valeur tient dans les cinq bits de poids
  /// faible, ou dans les 1, 2, 4 ou 8 octets qui suivent.
  private argument(info: number): number {
    if (info < 24) return info;
    if (info === 24) return this.byte();
    if (info === 25) return (this.byte() << 8) | this.byte();
    if (info === 26) {
      // Sans décalage : `<< 24` bascule en entier signé au-delà de 2^31.
      return this.byte() * 0x1000000 + (this.byte() << 16) + (this.byte() << 8) + this.byte();
    }
    if (info === 27) {
      let value = 0n;
      for (let i = 0; i < 8; i++) value = (value << 8n) | BigInt(this.byte());
      if (value > BigInt(Number.MAX_SAFE_INTEGER)) throw new Error('cbor: longueur démesurée');
      return Number(value);
    }
    // 28 à 30 sont réservés, 31 annonce une longueur indéfinie.
    throw new Error(`cbor: en-tête non pris en charge (${info})`);
  }

  value(): CborValue {
    const initial = this.byte();
    const major = initial >> 5;
    const info = initial & 0x1f;

    switch (major) {
      case 0:
        return this.argument(info);
      case 1:
        return -1 - this.argument(info);
      case 2:
        // Copié : la tranche partage la mémoire du flux, et l'appelant garde
        // parfois ces octets plus longtemps que le décodage.
        return new Uint8Array(this.take(this.argument(info)));
      case 3:
        return new TextDecoder().decode(this.take(this.argument(info)));
      case 4: {
        const length = this.argument(info);
        return Array.from({ length }, () => this.value());
      }
      case 5: {
        const length = this.argument(info);
        const map = new Map<string | number | bigint, CborValue>();
        for (let i = 0; i < length; i++) {
          const key = this.value();
          if (typeof key !== 'string' && typeof key !== 'number' && typeof key !== 'bigint') {
            throw new Error('cbor: clé de dictionnaire inattendue');
          }
          // Une clé répétée laisserait le choix de la valeur à celui qui
          // écrit le flux, et le décodeur et le vérificateur pourraient ne
          // pas prendre la même.
          if (map.has(key)) throw new Error('cbor: clé répétée');
          map.set(key, this.value());
        }
        return map;
      }
      case 7:
        if (info === 20) return false;
        if (info === 21) return true;
        if (info === 22) return null;
        throw new Error(`cbor: valeur simple non prise en charge (${info})`);
      default:
        // Majeur 6 : les étiquettes sémantiques, qu'App Attest n'emploie pas.
        throw new Error(`cbor: type majeur non pris en charge (${major})`);
    }
  }
}

/// Décode une valeur unique et exige que le flux s'arrête là : des octets en
/// trop signalent un flux fabriqué, jamais une écriture d'Apple.
export function decodeCbor(bytes: Uint8Array): CborValue {
  const reader = new Reader(bytes);
  const value = reader.value();
  if (reader.offset !== bytes.length) throw new Error('cbor: octets en trop');
  return value;
}

export function cborMap(value: CborValue): Map<string | number | bigint, CborValue> {
  if (!(value instanceof Map)) throw new Error('cbor: dictionnaire attendu');
  return value;
}

export function cborBytes(value: CborValue | undefined, what: string): Uint8Array {
  if (!(value instanceof Uint8Array)) throw new Error(`cbor: ${what} n'est pas une chaîne d'octets`);
  return value;
}

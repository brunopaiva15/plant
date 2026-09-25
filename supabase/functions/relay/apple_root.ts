// L'ancre de confiance d'App Attest, épinglée.
//
// « Apple App Attestation Root CA », récupérée sur
// https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem
// — P-384, auto-signée, valable jusqu'au 15 mars 2045. Empreinte SHA-256 :
// 1C:B9:82:3B:A2:8B:A6:AD:2D:33:A0:06:94:1D:E2:AE:4F:51:3E:F1:D4:E8:31:B9:F7:E0:FA:7B:62:42:C9:32
//
// Épinglée plutôt qu'allée chercher : une racine téléchargée à chaque
// vérification fait dépendre l'entrée de l'application de la joignabilité
// d'apple.com, et donne à qui tiendrait le réseau du relais le moyen de
// substituer la sienne. Elle expire en 2045 ; d'ici là, c'est cette chaîne de
// caractères qu'il faudra remplacer, et le test `vérifie l'ancre épinglée`
// dira si la nouvelle est lisible.

import { fromBase64 } from './bytes.ts';

const APPLE_APP_ATTESTATION_ROOT_CA =
  'MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYwJAYDVQQDDB1B' +
  'cHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwKQXBwbGUgSW5jLjETMBEGA1UE' +
  'CAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNaFw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMM' +
  'HUFwcGxlIEFwcCBBdHRlc3RhdGlvbiBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYD' +
  'VQQIDApDYWxpZm9ybmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dy' +
  'ctdhNbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9auYen1mMEv' +
  'Rq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSskRBT' +
  'M72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZIzj0EAwMDaAAwZQIwQgFGnByv' +
  'siVbpTKwSga0kP0e8EeDS4+sQmTvb7vn53O5+FRXgeLhpJ06ysC5PrOyAjEAp5U4xDgEgllF7En3' +
  'VcE3iexZZtKeYnpqtijVoyFraWVIyd/dganmrduC1bmTBGwD';

export const appleRootCertificate = (): Uint8Array => fromBase64(APPLE_APP_ATTESTATION_ROOT_CA);

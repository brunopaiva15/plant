// Une chaîne d'attestation de la forme qu'Apple produit, enracinée dans une
// autorité de test.
//
// App Attest ne se répète pas : une clé de Secure Enclave ne s'atteste qu'une
// fois, et personne n'a d'iPhone sous la main quand les tests tournent. Ces
// pièces ont donc été fabriquées une fois par OpenSSL, et ce sont de vrais
// certificats : racine P-384 auto-signée, intermédiaire qu'elle signe,
// certificat d'appareil P-256 portant l'extension 1.2.840.113635.100.8.2 avec
// le nonce calculé sur `authData`. Seul l'assemblage CBOR est écrit à la main.
// `tool/fabriquer_attestation.mjs` en refait un jeu équivalent, avec des clés
// neuves.
//
// La racine de test remplace celle d'Apple par la politique passée au
// vérificateur, et par elle seulement : le test « refuse la racine d'Apple »
// vérifie que la vraie ancre rejette bien cette chaîne-là.

export const fixtures = {
  appId: 'ABCDE12345.ch.vergasta.plant',
  challenge: 'Yw9rk3pQ2nTf5sVx8bLh1dGm4aZcJeRu',
  keyId: '3DCtIQ/PfiGkoYafSEeBzeUk2bj/mv5O0Se5IMtXa9E=',
  testRoot:
    'MIICATCCAYigAwIBAgIUKSUmSiggvKUjE1VllU+m1tCcpbQwCgYIKoZIzj0EAwMwNzEkMCIGA1UE' +
    'AwwbQXV4aW5lIFRlc3QgQXBwIEF0dGVzdCBSb290MQ8wDQYDVQQKDAZBdXhpbmUwIBcNMjYwOTIx' +
    'MjAyMzU0WhgPMjA1MTA1MTMyMDIzNTRaMDcxJDAiBgNVBAMMG0F1eGluZSBUZXN0IEFwcCBBdHRl' +
    'c3QgUm9vdDEPMA0GA1UECgwGQXV4aW5lMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEd/TqlwENm432' +
    'EyumWoaiCp/zmLe7Dd54x19i1h1BSAQuR3Sg2uHNiDa0HmKslUE/gfclgtiRU58fv3DahJjefDHm' +
    'YmQpfULg2yiPVhKe2lLXkIy8fjNWmHh4vL32HDVIo1MwUTAdBgNVHQ4EFgQUaSqdJCvwK/NR7JMm' +
    'hfPu3IozgU4wHwYDVR0jBBgwFoAUaSqdJCvwK/NR7JMmhfPu3IozgU4wDwYDVR0TAQH/BAUwAwEB' +
    '/zAKBggqhkjOPQQDAwNnADBkAjB6L/9hveN/qxGfrhsgFCC2b1hbYJtmd8yKkpWYCAXrWjb8nvsV' +
    'i5Emaytsa/FJrdkCMBKmImoAKjdZ5hRWYJVVR1IpJbXSXqWwXKQ6ilPLeivlDtM3iR92InFXSqOG' +
    'c0K6ow==',
  attestation:
    'o2NmbXRvYXBwbGUtYXBwYXR0ZXN0Z2F0dFN0bXSiY3g1Y4JZAgMwggH/MIIBhqADAgECAhRWkct9' +
    'YrnNHD9mw1kPbqNgossRZDAKBggqhkjOPQQDAjA3MSQwIgYDVQQDDBtBdXhpbmUgVGVzdCBBcHAg' +
    'QXR0ZXN0IENBIDExDzANBgNVBAoMBkF1eGluZTAgFw0yNjA5MjEyMDIzNTRaGA8yMDUxMDUxMzIw' +
    'MjM1NFowLjEbMBkGA1UEAwwSQXV4aW5lIFRlc3QgRGV2aWNlMQ8wDQYDVQQKDAZBdXhpbmUwWTAT' +
    'BgcqhkjOPQIBBggqhkjOPQMBBwNCAATzChczu9j/uHNvQIS+BB00Ci81jvT8IUv6X5Nj/AAtahl1' +
    'K5iXf/D1e51CxJtjF7TiLuidLNUVfBQgUrWOmWjno3cwdTAzBgkqhkiG92NkCAIEJjAkoSIEIOFn' +
    'UmMjR0zoyqnlcwo32p6QEL5aZ+kz/LtWT04754GYMB0GA1UdDgQWBBSJolACJYZTteNmdicViki2' +
    'kh2gDzAfBgNVHSMEGDAWgBS+aCt1jqPvrC91OV33ui7OplerdzAKBggqhkjOPQQDAgNnADBkAjB5' +
    'SPfR6hZatTLxi2P/E6NjGp48HlRvhA2iMU+Syd13024cfdbiJlr+S6Gt1dbYp6sCMDwehuUrdewA' +
    '+ZrRHurQE1sQpGsFJ2NzbNLR+5T/m+L6QQWcfVZsHZd/P+nbB22M4lkCFzCCAhMwggGYoAMCAQIC' +
    'FAizGnKzlRYhwlj2Nhn+9bd++76nMAoGCCqGSM49BAMDMDcxJDAiBgNVBAMMG0F1eGluZSBUZXN0' +
    'IEFwcCBBdHRlc3QgUm9vdDEPMA0GA1UECgwGQXV4aW5lMCAXDTI2MDkyMTIwMjM1NFoYDzIwNTEw' +
    'NTEzMjAyMzU0WjA3MSQwIgYDVQQDDBtBdXhpbmUgVGVzdCBBcHAgQXR0ZXN0IENBIDExDzANBgNV' +
    'BAoMBkF1eGluZTB2MBAGByqGSM49AgEGBSuBBAAiA2IABNWd6m7llufG1Ar+Q55IKiibYMRDNx0I' +
    'UhBQ/DNxeGqV/bTiZCyoWHnuz1R6Jsww77H/jaoT/p3MCcsjQO8nIEEDZq0D3Sri7hzkSRwZiFKY' +
    'lD9CJa7HqZijS9rGJ7rFdqNjMGEwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAgQwHQYD' +
    'VR0OBBYEFL5oK3WOo++sL3U5Xfe6Ls6mV6t3MB8GA1UdIwQYMBaAFGkqnSQr8CvzUeyTJoXz7tyK' +
    'M4FOMAoGCCqGSM49BAMDA2kAMGYCMQDk5r9lTNGwFWRaF2I4kKCny970tj37anehfnGYoMFWcJ5U' +
    'PzZRx3KtfX/i9gTNygMCMQD14aT+rn+lLmrzJwobFvykHmBpCFfeouI9dtO04ciYzm2IerbkUoan' +
    'ET5mP0nr/0ZncmVjZWlwdExyZcOndSBvcGFxdWVoYXV0aERhdGFYpCPamabeMnusGX5YVW4e1NKC' +
    'Fm454jPZGHjJaCM2GkhBQAAAAABhcHBhdHRlc3RkZXZlbG9wACDcMK0hD89+IaShhp9IR4HN5STZ' +
    'uP+a/k7RJ7kgy1dr0aUBAgMmIAEhWCDzChczu9j/uHNvQIS+BB00Ci81jvT8IUv6X5Nj/AAtaiJY' +
    'IBl1K5iXf/D1e51CxJtjF7TiLuidLNUVfBQgUrWOmWjn',
  assertionCounter1:
    'omlzaWduYXR1cmVYRzBFAiEAxermSTDoq82tlr1gBzDd1i8z+8LImzRJcx8y+wyz1K8CICayI2/a' +
    'EZpuJ6jazSScKkQnikgIn95OKcKO4o4Sl0jncWF1dGhlbnRpY2F0b3JEYXRhWCUj2pmm3jJ7rBl+' +
    'WFVuHtTSghZuOeIz2Rh4yWgjNhpIQQAAAAAB',
  assertionCounter2:
    'omlzaWduYXR1cmVYRzBFAiEAnWxShFI0JdfbsX/EQuCVSmffImunHf3+G2UtVtvgKNwCIE2QA2Dw' +
    'ozNB0CiCPNGvu96G+rSgVjRjdZczjOj3fqZWcWF1dGhlbnRpY2F0b3JEYXRhWCUj2pmm3jJ7rBl+' +
    'WFVuHtTSghZuOeIz2Rh4yWgjNhpIQQAAAAAC',
  assertionOtherChallenge:
    'omlzaWduYXR1cmVYRzBFAiAGlL2AHCDw3GtaUF7EQUBGHzzM48gKwYvY1YXt3q/wVQIhAOa70J44' +
    '2dWXCMHzfa2tUXFIVmB5FPYnVos09snAoq2IcWF1dGhlbnRpY2F0b3JEYXRhWCUj2pmm3jJ7rBl+' +
    'WFVuHtTSghZuOeIz2Rh4yWgjNhpIQQAAAAAD',
} as const;

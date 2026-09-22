// Ce que le relais tient, et ce qu'il laisse consommer.
//
// Rien de tout cela n'est écrit dans le dépôt : les valeurs viennent des
// secrets du projet Supabase (`supabase secrets set`), et c'est tout l'objet
// du relais — une clé qui n'est nulle part dans le binaire ni dans le code
// n'est extractible de nulle part. La marche à suivre est dans
// `docs/19-relais-des-cles.md`.

import type { AttestEnvironment, AttestPolicy } from './attest.ts';

const env = (name: string): string => Deno.env.get(name)?.trim() ?? '';

const number = (name: string, fallback: number): number => {
  const raw = Number(env(name));
  return Number.isFinite(raw) && raw > 0 ? Math.floor(raw) : fallback;
};

export const routes = ['identify', 'ai', 'decide'] as const;
export type Route = (typeof routes)[number];

export interface RouteLimits {
  /// Ce qu'un appareil peut demander en une journée.
  readonly perDevice: number;
  /// Ce que le relais laisse passer en une journée, tous appareils
  /// confondus. C'est ce plafond-là qui borne la facture, et lui seul tient
  /// encore si quelqu'un trouve le moyen de se faire passer pour mille
  /// appareils.
  readonly perDay: number;
  /// Au-delà, la requête est refusée sans être transmise.
  readonly maxBody: number;
  readonly timeout: number;
}

/// Des plafonds qui ne gênent pas un usage ordinaire — quelques
/// identifications et un diagnostic ou deux par jour — et qui arrêtent une
/// boucle. Chacun se relève par un secret, sans redéployer.
export const limits: Record<Route, RouteLimits> = {
  identify: {
    perDevice: number('RELAY_QUOTA_IDENTIFY', 40),
    perDay: number('RELAY_QUOTA_IDENTIFY_DAY', 4000),
    // Trois photos de téléphone, non réduites : c'est Pl@ntNet qui les
    // rétrécit, et l'application les envoie telles quelles.
    maxBody: number('RELAY_BODY_IDENTIFY', 24 * 1024 * 1024),
    timeout: number('RELAY_TIMEOUT_IDENTIFY', 30) * 1000,
  },
  ai: {
    perDevice: number('RELAY_QUOTA_AI', 30),
    perDay: number('RELAY_QUOTA_AI_DAY', 1500),
    maxBody: number('RELAY_BODY_AI', 12 * 1024 * 1024),
    // Le modèle réfléchit avant d'écrire ; le client attend déjà 90 s, et le
    // relais doit lui laisser le temps de répondre avant de couper.
    timeout: number('RELAY_TIMEOUT_AI', 120) * 1000,
  },
  decide: {
    perDevice: number('RELAY_QUOTA_DECIDE', 60),
    perDay: number('RELAY_QUOTA_DECIDE_DAY', 4000),
    maxBody: number('RELAY_BODY_DECIDE', 256 * 1024),
    timeout: number('RELAY_TIMEOUT_DECIDE', 30) * 1000,
  },
};

export const secrets = {
  session: env('RELAY_SESSION_SECRET'),
  /// Le laissez-passer des constructions qui ne peuvent pas attester : le
  /// simulateur, où App Attest n'existe pas, et Android, qui attend Play
  /// Integrity. Vide en production — et alors ce chemin n'existe pas.
  devToken: env('RELAY_DEV_TOKEN'),
  plantNet: env('PLANTNET_API_KEY'),
  infomaniakKey: env('INFOMANIAK_AI_API_KEY'),
  infomaniakProduct: env('INFOMANIAK_AI_PRODUCT_ID'),
  openRouter: env('OPENROUTER_API_KEY'),
};

/// Les modèles se décident ici, et non dans l'application : en changer ne
/// demande plus de repasser par l'App Store.
export const models = {
  infomaniak: env('INFOMANIAK_AI_MODEL') || 'Qwen/Qwen3.5-397B-A17B-FP8',
  jev: env('OPENROUTER_MODEL') || '~typesafe/jev-latest',
};

/// La durée d'un jeton de session. Assez longue pour qu'une séance
/// d'identification n'en redemande pas, assez courte pour qu'un jeton
/// recopié ne serve pas longtemps.
export const sessionLifetime = number('RELAY_SESSION_LIFETIME', 3600);

/// La durée d'un défi : le temps d'un aller-retour et d'une signature de la
/// Secure Enclave, pas davantage.
export const challengeLifetime = number('RELAY_CHALLENGE_LIFETIME', 300);

function environments(): AttestEnvironment[] {
  const raw = env('APP_ATTEST_ENVIRONMENTS') || 'production';
  const wanted = raw.split(',').map((name) => name.trim()).filter(Boolean);
  return wanted.filter((name): name is AttestEnvironment => name === 'development' || name === 'production');
}

/// `APPLE_APP_ID` vaut « <identifiant d'équipe>.<identifiant du paquet> », par
/// exemple « ABCDE12345.ch.vergasta.plant ». L'identifiant d'équipe se lit
/// dans l'onglet *Membership* du compte développeur.
export const attestPolicy = (): AttestPolicy => ({
  appId: env('APPLE_APP_ID'),
  environments: environments(),
});

/// Ce qui manque pour que le relais serve. Dit tôt et en clair : une fonction
/// déployée sans ses secrets répondrait sinon par des erreurs d'amont
/// incompréhensibles.
export function missingSecrets(): string[] {
  const missing: string[] = [];
  if (!secrets.session) missing.push('RELAY_SESSION_SECRET');
  if (!env('APPLE_APP_ID')) missing.push('APPLE_APP_ID');
  if (environments().length === 0) missing.push('APP_ATTEST_ENVIRONMENTS');
  return missing;
}

/// Les routes que le relais peut servir : une clé absente ferme la sienne,
/// sans fermer les autres.
export const available = (): Record<Route, boolean> => ({
  identify: secrets.plantNet !== '',
  ai: secrets.infomaniakKey !== '' && secrets.infomaniakProduct !== '',
  decide: secrets.openRouter !== '',
});

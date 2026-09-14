// La page elle-même : sa feuille de style, sa coquille HTML, et le seul
// écran qui ne dépend d'aucune donnée. Séparée du routage, elle se rend sans
// Supabase — de quoi la regarder avant de la déployer.
//
// Elle porte le design system de l'application (docs/06) : papier crème
// grainé, pièces d'argile, titres à la main. Les valeurs viennent des tokens
// Dart — les changer ici sans les changer là-bas ferait deux Auxine.

/** La page ne charge rien d'ailleurs : ses styles sont en ligne, sa fonte et
 * son grain viennent de `/asset/`, ses photos du stockage public. */
export const CSP = "default-src 'none'; img-src https: data:; style-src 'unsafe-inline'; font-src 'self'";

/** Échappe le texte inséré dans le HTML : aucun contenu utilisateur n'est brut. */
export function esc(value: unknown): string {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

/**
 * La feuille de style de la page, à l'identique du design system (docs/06).
 *
 * `design_system/tokens/` donne les couleurs, l'échelle d'espacement, les
 * rayons et les sept styles de texte ; `components/clay.dart` donne la
 * matière. Le relief d'une pièce y est peint : une ombre portée dans sa
 * teinte décalée en bas à droite, un reflet blanc en haut à gauche, un creux
 * en bas à droite. Trois `box-shadow` disent la même chose. Chaque pièce a
 * son `unit` — `plus petit côté / 48`, borné à 0,6–1,6 —, si bien qu'un
 * bouton de 52 points et une carte de 360 ne portent pas la même ombre.
 *
 * Deux conversions séparent les nombres d'ici de ceux de `paintClay` :
 *
 * - un rayon de flou CSS vaut deux fois le sigma de Flutter, d'où les rayons
 *   doublés ;
 * - surtout, les deux ombres intérieures n'y sont pas la même figure.
 *   Flutter floute une **bande** large de quelques points — le décalage du
 *   trou —, CSS floute un **bord**. À opacité égale, la bande perd presque
 *   tout à la convolution (son pic vaut `A · largeur / (σ·√2π)`, soit moins
 *   d'un quart pour un reflet de carte) là où le bord garde la moitié de la
 *   sienne. Les opacités du reflet et du creux sont donc celles qui rendent
 *   le même pic, pas celles de `clay.dart` : un reflet à 0,75 recopié tel
 *   quel délave la carte. L'ombre portée, elle, est bien la même figure des
 *   deux côtés, et garde ses valeurs.
 */
function styles(assetBase: string): string {
  return `
@font-face {
  font-family: 'ShantellSans';
  src: url('${assetBase}/asset/shantell.woff2') format('woff2');
  font-weight: 600 700;
  font-display: swap;
}
:root {
  --canvas:#F6EFE4; --surface:#FBF6EE; --surface-muted:#EFE4D4;
  --ink:#4A3528; --ink-2:#6F5A4E; --ink-3:#746256;
  --sage:#2C774E; --on-sage:#FFFFFF;
  --grain:0.07;
  /* Les pièces : ombre portée · reflet · creux. */
  --clay-card:
    8px 11.2px 28.8px rgba(176,172,167,0.14),
    inset 4.8px 4.8px 16px rgba(255,255,255,0.36),
    inset -6.4px -8px 22.4px rgba(176,172,167,0.06);
  --clay-open:
    5.4px 7.6px 19.5px rgba(31,83,55,0.24),
    inset 3.3px 3.3px 10.8px rgba(255,255,255,0.15),
    inset -4.3px -5.4px 15.2px rgba(31,83,55,0.16);
  --clay-code:
    5.9px 8.2px 21.1px rgba(167,160,148,0.14),
    inset 3.5px 3.5px 11.7px rgba(255,255,255,0.36),
    inset -4.7px -5.9px 16.4px rgba(167,160,148,0.06);
}
@media (prefers-color-scheme: dark) {
  :root {
    --canvas:#221A15; --surface:#2E2219; --surface-muted:#3A2C22;
    --ink:#F6EFE4; --ink-2:#C2AE9C; --ink-3:#A69485;
    --sage:#6DC48D; --on-sage:#0B1A10;
    --grain:0.10;
    --clay-card:
      8px 11.2px 28.8px rgba(0,0,0,0.28),
      inset 4.8px 4.8px 16px rgba(255,255,255,0.05),
      inset -6.4px -8px 22.4px rgba(32,24,18,0.20);
    --clay-open:
      5.4px 7.6px 19.5px rgba(0,0,0,0.32),
      inset 3.3px 3.3px 10.8px rgba(255,255,255,0.11),
      inset -4.3px -5.4px 15.2px rgba(76,137,99,0.23);
    --clay-code:
      5.9px 8.2px 21.1px rgba(0,0,0,0.28),
      inset 3.5px 3.5px 11.7px rgba(255,255,255,0.05),
      inset -4.7px -5.9px 16.4px rgba(41,31,24,0.20);
  }
}
* { box-sizing: border-box; }
body {
  margin:0; background:var(--canvas); color:var(--ink);
  font:400 17px/1.35 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  letter-spacing:-0.2px;
  display:flex; justify-content:center; padding:32px 20px 48px;
}
/* Le grain du papier, la tuile de 128 px de l'app, par-dessus tout et
   ignorée par le pointeur. */
body::after {
  content:''; position:fixed; inset:0; pointer-events:none;
  background:url('${assetBase}/asset/grain.png') repeat;
  background-size:128px 128px; opacity:var(--grain);
}
main { width:100%; max-width:560px; }
.card {
  background:var(--surface); border-radius:24px; box-shadow:var(--clay-card);
  overflow:hidden;
}
.body { padding:24px; }
img { width:100%; display:block; background:var(--surface-muted); }
h1 {
  margin:0 0 8px; font-family:'ShantellSans', -apple-system, BlinkMacSystemFont, sans-serif;
  font-weight:700; font-size:28px; line-height:1.2; letter-spacing:-0.2px; color:var(--ink);
}
p { margin:0 0 12px; }
.lead { color:var(--ink-2); font-size:15px; letter-spacing:-0.1px; }
.species { margin:-4px 0 12px; color:var(--sage); font-size:15px; letter-spacing:-0.1px; }
.meta { margin:16px 0 0; font-size:13px; line-height:1.3; font-weight:500; color:var(--ink-3); letter-spacing:0; }
.open {
  display:flex; align-items:center; justify-content:center; min-height:52px;
  margin:20px 0 16px; padding:0 24px; border-radius:999px;
  background:var(--sage); box-shadow:var(--clay-open);
  color:var(--on-sage); text-decoration:none; font-weight:600; font-size:17px;
  transition:transform 150ms cubic-bezier(0.215,0.61,0.355,1);
}
/* L'appui du design system : la pièce s'aplatit plus qu'elle ne s'éloigne. */
.open:active { transform:scale(0.992, 0.968); }
.open:focus-visible { outline:2px solid var(--ink); outline-offset:3px; }
.code {
  margin:16px 0 0; padding:16px 20px; border-radius:16px;
  background:var(--surface-muted); box-shadow:var(--clay-code);
  font-family:'ShantellSans', ui-monospace, monospace; font-weight:600;
  font-size:22px; line-height:1.25; letter-spacing:3px; color:var(--ink);
  text-align:center;
}
b { font-weight:600; color:var(--ink); }
footer {
  margin:20px 0 0; text-align:center;
  font-size:13px; line-height:1.3; font-weight:500; letter-spacing:0; color:var(--ink-3);
}
footer b { color:var(--sage); }
@media (prefers-reduced-motion: reduce) {
  .open { transition:none; }
  .open:active { transform:none; }
}
`;
}

/**
 * Ce qu'une messagerie affiche du lien.
 *
 * WhatsApp, Telegram, Messages et les autres lisent les balises Open Graph
 * et fabriquent une carte. Trois choses la décident : un titre, une phrase,
 * une image — et l'image doit porter une adresse absolue, une relative n'est
 * pas résolue de façon fiable par ces robots.
 *
 * Pas d'`og:url` : servie derrière le relais, la fonction ne connaît que sa
 * propre adresse Supabase, celle qui rend la page en texte brut. Mieux vaut
 * n'en donner aucune — les robots retiennent alors celle qu'ils ont suivie —
 * que d'en donner une qui déçoit.
 */
export interface PagePreview {
  /** Adresse absolue de la vignette. */
  image?: string;
  /** Ses dimensions, quand elles sont connues : elles décident de la grande
   * carte plutôt que de la petite. Une photo de plante n'en a pas. */
  imageWidth?: number;
  imageHeight?: number;
  imageAlt?: string;
}

export function page(
  body: string,
  opts: PagePreview & { title: string; assetBase: string; description?: string; keywords?: string; noindex: boolean; status?: number },
) {
  const html = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(opts.title)}</title>
${opts.noindex ? '<meta name="robots" content="noindex, nofollow">' : ''}
${opts.description ? `<meta name="description" content="${esc(opts.description)}">` : ''}
${opts.keywords ? `<meta name="keywords" content="${esc(opts.keywords)}">` : ''}
<meta property="og:type" content="website">
<meta property="og:site_name" content="Auxine">
<meta property="og:locale" content="fr_FR">
<meta property="og:title" content="${esc(opts.title)}">
${opts.description ? `<meta property="og:description" content="${esc(opts.description)}">` : ''}
${opts.image ? `<meta property="og:image" content="${esc(opts.image)}">` : ''}
${opts.imageAlt ? `<meta property="og:image:alt" content="${esc(opts.imageAlt)}">` : ''}
${opts.imageWidth ? `<meta property="og:image:width" content="${opts.imageWidth}">` : ''}
${opts.imageHeight ? `<meta property="og:image:height" content="${opts.imageHeight}">` : ''}
<meta name="twitter:card" content="${opts.image ? 'summary_large_image' : 'summary'}">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#F6EFE4" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#221A15" media="(prefers-color-scheme: dark)">
<style>${styles(opts.assetBase)}</style>
</head>
<body><main>${body}<footer>Partagé depuis <b>Auxine</b></footer></main></body>
</html>`;
  return new Response(html, {
    status: opts.status ?? 200,
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': opts.noindex ? 'private, max-age=0, no-store' : 'public, max-age=300',
      'x-robots-tag': opts.noindex ? 'noindex, nofollow' : 'all',
      'referrer-policy': 'no-referrer',
      'content-security-policy': CSP,
      // Le même en-tête sous un nom que la passerelle laisse passer. Sur
      // `*.supabase.co`, elle réécrit celui du dessus en `sandbox` — ce qui
      // empêcherait « Ouvrir dans Auxine » d'ouvrir quoi que ce soit. Le
      // relais public (`share-proxy/worker.js`) le remet à sa place.
      'x-auxine-csp': CSP,
    },
  });
}

export const notFound = (assetBase: string) =>
  page('<div class="card"><div class="body"><h1>Lien indisponible</h1><p class="lead">Ce partage a été révoqué, a expiré, ou n\'existe pas.</p></div></div>', {
    title: 'Lien indisponible',
    assetBase,
    noindex: true,
    status: 404,
  });

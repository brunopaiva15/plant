// L'image d'aperçu des liens de partage, celle que WhatsApp, Telegram ou
// Messages affichent sous le titre.
//
//   node tool/build_share_preview.mjs
//
// Sort `supabase/functions/share/preview.jpg`, en 1200 × 630 — le format que
// les messageries attendent pour une grande carte. Le dessin est composé en
// HTML puis photographié par Chromium, comme les visuels du magasin : c'est
// la seule façon d'avoir la vraie fonte et le vrai grain sans les redessiner.
// En JPEG, parce que le grain est du bruit : il tient trois fois moins de
// place là qu'en PNG, et les messageries n'aiment pas les vignettes lourdes.
//
// Rien n'y nomme le jardin ni la personne : l'image est la même pour tous les
// liens, et c'est le titre `og:title` qui porte le particulier. Elle ne
// vieillit donc qu'avec la marque.
//
// Refaire `python3 tool/build_share_assets.py` ensuite : c'est lui qui la
// fait entrer dans la fonction.
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const racine = join(dirname(fileURLToPath(import.meta.url)), '..');
const dataUri = (chemin, type) => `data:${type};base64,${readFileSync(join(racine, chemin)).toString('base64')}`;

// Les valeurs viennent de `design_system/tokens/` (docs/06).
const CANVAS = '#F6EFE4';
const INK = '#4A3528';
const OMBRE = 'rgba(94,44,20,0.14)'; // le token `shadow` : brune, jamais noire

const html = `<!doctype html><meta charset="utf-8"><style>
@font-face { font-family:'ShantellSans'; src:url('${dataUri('assets/fonts/ShantellSans-VF.ttf', 'font/ttf')}'); font-weight:600 700; }
* { margin:0; box-sizing:border-box; }
body { width:1200px; height:630px; background:${CANVAS}; overflow:hidden;
       display:flex; align-items:center; justify-content:center; gap:72px; }
body::after { content:''; position:fixed; inset:0; pointer-events:none;
              background:url('${dataUri('assets/textures/grain.png', 'image/png')}') repeat;
              background-size:128px 128px; opacity:0.07; }
img { height:340px; filter:drop-shadow(10px 14px 18px ${OMBRE}); }
h1 { font-family:'ShantellSans'; font-weight:700; font-size:132px; line-height:1;
     letter-spacing:-2px; color:${INK}; }
</style>
<img src="${dataUri('assets/icon/plant.png', 'image/png')}" alt="">
<h1>Auxine</h1>`;

const navigateur = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined, args: ['--no-sandbox'] });
const page = await navigateur.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 });
await page.setContent(html, { waitUntil: 'load' });
await page.evaluate(() => document.fonts.ready);
const sortie = join(racine, 'supabase/functions/share/preview.jpg');
await page.screenshot({ path: sortie, type: 'jpeg', quality: 88 });
await navigateur.close();
console.log(sortie);

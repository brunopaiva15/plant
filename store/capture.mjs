// Captures de l'app pour les visuels du magasin.
//
// Prérequis : `flutter build web --profile --no-web-resources-cdn`, puis
// `python3 store/serve.py 8081 build/web`. Le jeu de données de démo (`?demo`)
// et le mode iOS (`&ios`) viennent de l'app elle-même.
//
// Usage : node store/capture.mjs <dossier de sortie> [fr-FR|en-US]
import { chromium } from 'playwright';
import { execSync } from 'node:child_process';
const out = process.argv[2], locale = process.argv[3] || 'fr-FR';
const b = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined, args: ['--no-sandbox'] });
const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, locale });
await p.route(/fonts\.gstatic\.com|fonts\.googleapis\.com/, async route => {
  try {
    const body = execSync(`curl -sS --max-time 30 "${route.request().url()}"`, { maxBuffer: 64 * 1024 * 1024 });
    await route.fulfill({ status: 200, body, headers: { 'content-type': 'font/woff2', 'access-control-allow-origin': '*' } });
  } catch (e) { await route.abort(); }
});
const go = async (hash, wait = 3500) => { await p.goto('http://localhost:8081/?demo&ios#' + hash, { waitUntil: 'load' }); await p.waitForTimeout(wait); };
const shot = (name) => p.screenshot({ path: `${out}/${name}.png` });
// L'arbre sémantique de Flutter web donne des cibles nommées : on l'active.
const a11y = async () => { await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click()); await p.waitForTimeout(1200); };
// Un tap par l'arbre sémantique : l'élément dont l'étiquette contient le texte.
const tap = async (text) => {
  const found = await p.evaluate((t) => {
    const el = [...document.querySelectorAll('[aria-label]')].find(e => e.getAttribute('aria-label').includes(t));
    if (!el) return false; el.click(); return true;
  }, text);
  if (!found) throw new Error('introuvable : ' + text);
  await p.waitForTimeout(2500);
};

await go('/onboarding', 7000);
await p.mouse.click(350, 22); await p.waitForTimeout(1500);           // Passer
await go('/today', 5000);
// « Pas maintenant » / « Not now » : le bouton n'a pas la même largeur selon la langue.
await p.mouse.click(193, 347); await p.waitForTimeout(800);
await p.mouse.click(168, 327); await p.waitForTimeout(1500);
await shot('today');
await go('/plants', 4000); await shot('plants');
await p.mouse.click(104, 375); await p.waitForTimeout(3000);          // Basilic
await shot('plant');
await p.mouse.click(195, 765); await p.waitForTimeout(3500); await shot('care');       // Comment en prendre soin
await p.goBack(); await p.waitForTimeout(2500);
await p.mouse.click(330, 376); await p.waitForTimeout(3500); await shot('schedule');   // Planning
await go('/garden', 4000); await shot('garden');
await p.mouse.click(326, 168); await p.waitForTimeout(2500); await shot('garden-calendar');
await p.mouse.click(150, 168); await p.waitForTimeout(2500); await shot('garden-tasks');
await p.mouse.click(240, 168); await p.waitForTimeout(2500); await shot('garden-inventory');
await go('/dashboard', 4000); await shot('dashboard');
await go('/settings/backup', 4000); await shot('backup');
await go('/profile', 4000); await shot('profile');
await b.close();

// Captures de l'app pour les visuels du magasin.
//
// Prérequis : `flutter build web --profile --no-web-resources-cdn`, puis
// `python3 store/serve.py 8081 build/web`. Le jeu de données de démo (`?demo`)
// et le mode iOS (`&ios`) viennent de l'app elle-même.
//
// Usage : node store/capture.mjs <dossier de sortie> [fr-FR|en-US]
// Mode sombre : DARK=1 node store/capture.mjs …
import { chromium } from 'playwright';
import { execSync } from 'node:child_process';
const out = process.argv[2], locale = process.argv[3] || 'fr-FR';
const b = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined, args: ['--no-sandbox'] });
const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, locale, colorScheme: process.env.DARK ? 'dark' : 'light', hasTouch: true });
const p = await ctx.newPage();
// Un glissement du doigt, par le protocole du navigateur : là où la molette
// n'entraîne presque rien sur certaines pages, le geste tactile défile comme
// sur un téléphone.
const cdp = await ctx.newCDPSession(p);
const swipe = async (x, y0, y1, steps = 20) => {
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y: y0 }] });
  for (let i = 1; i <= steps; i++) { await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x, y: y0 + (y1 - y0) * i / steps }] }); await p.waitForTimeout(16); }
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await p.waitForTimeout(2000);
};
// Les préférences d'un téléphone déjà réglé, écrites comme shared_preferences
// les garde sur le web (clé préfixée, valeur en JSON) : l'onboarding passé,
// un prénom pour « Bonjour », une ville pour la météo, l'invite aux rappels
// (« Un rappel utile, chaque jour ») déjà vue, la question des photos
// d'entraînement d'Iris déjà posée. Apple Maison ne se lit que par HomeKit,
// sur un iPhone : rien à régler ici.
const en = locale.startsWith('en');
await p.addInitScript(() => {
  const set = (k, v) => localStorage.setItem('flutter.' + k, JSON.stringify(v));
  set('onboarding_done', true);
  set('notification_prompt_shown', true);
  set('upcoming_grid_view', true);
  set('iris_feedback_asked', true);
  set('display_name', 'Camille');
  set('weather_place', 'Lausanne|46.5197|6.6323');
});
// La météo (Open-Meteo) suit le même relais par curl que les polices.
await p.route(/open-meteo\.com/, async route => {
  try {
    const body = execSync(`curl -sS --max-time 30 "${route.request().url()}"`, { maxBuffer: 16 * 1024 * 1024 });
    await route.fulfill({ status: 200, body, headers: { 'content-type': 'application/json', 'access-control-allow-origin': '*' } });
  } catch (e) { await route.abort(); }
});
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

await go('/today', 7000); await shot('today');
await go('/plants', 4000); await shot('plants');
await p.mouse.click(104, 375); await p.waitForTimeout(3000);          // Basilic
await shot('plant');
// Sous l'en-tête photo, la carte d'entretien est hors écran : on descend à la molette
// (un glissement de souris ne fait pas défiler Flutter web), puis on tape dessus.
await p.mouse.move(195, 500); for (let i = 0; i < 6; i++) { await p.mouse.wheel(0, 400); await p.waitForTimeout(250); }
await p.waitForTimeout(1200); await p.mouse.click(195, 770); await p.waitForTimeout(3500); await shot('care');
await go('/plants', 4000); await p.mouse.click(104, 375); await p.waitForTimeout(3000);
await p.mouse.click(320, 563); await p.waitForTimeout(3500); await shot('schedule');   // Planning
await go('/garden', 4000); await shot('garden');
await p.mouse.click(326, 168); await p.waitForTimeout(2500); await shot('garden-calendar');
await p.mouse.click(150, 168); await p.waitForTimeout(2500); await shot('garden-tasks');
await p.mouse.click(240, 168); await p.waitForTimeout(2500); await shot('garden-inventory');
await go('/dashboard', 4000); await shot('dashboard');
await go('/settings/backup', 4000); await shot('backup');
await go('/profile', 4000); await shot('profile');
// Le diagnostic gardé au journal de la Calathea, rouvert en entier. Le
// journal vient juste sous la carte d'entretien : un glissement, et la
// carte « Diagnostic » est au milieu de l'écran.
await go('/plants', 4000); await p.mouse.click(286, 375); await p.waitForTimeout(3000);
await swipe(195, 760, 60); await p.mouse.click(195, 660); await p.waitForTimeout(3000); await shot('diagnosis');
// En dernier : la feuille « Une photo ? » de l'ajout reste ouverte par-dessus tout.
await go('/plants', 4000); await p.mouse.click(362, 22); await p.waitForTimeout(3000); await shot('add-plant');
await b.close();

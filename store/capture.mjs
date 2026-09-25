// Captures de l'app pour les visuels du magasin.
//
// Prérequis : `flutter build web --profile --no-web-resources-cdn`, puis
// `python3 store/serve.py 8081 build/web`. Le jeu de données de démo (`?demo`)
// et le mode iOS (`&ios`) viennent de l'app elle-même.
//
// Usage : node store/capture.mjs <dossier de sortie> [fr-FR|en-US|de-DE|it-IT]
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
// Un tap par l'arbre sémantique : le nœud le plus profond dont l'étiquette ou
// le texte contient le libellé, puis le premier ancêtre qui se touche. Flutter
// web met le texte tantôt dans `aria-label`, tantôt dans le nœud lui-même.
const tap = async (text) => {
  // Le centre du nœud à l'écran, touché par un vrai clic : un `click()` sur un
  // nœud sans action ne fait rien, là où le doigt atteint ce qui est dessous.
  const box = await p.evaluate((t) => {
    const lit = (e) => (e.getAttribute('aria-label') || '').includes(t) || e.textContent.includes(t);
    // Parmi les nœuds à l'écran, le plus petit : c'est le libellé lui-même,
    // pas la page qui le contient.
    const vus = [...document.querySelectorAll('flt-semantics, [aria-label]')].filter(lit)
      .map(e => e.getBoundingClientRect())
      .filter(r => r.width > 0 && r.height > 0 && r.y > 60 && r.y + r.height < innerHeight - 20)
      .sort((a, b) => a.width * a.height - b.width * b.height);
    if (!vus.length) return null;
    const r = vus[0];
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  }, text);
  if (!box) throw new Error('introuvable : ' + text);
  await p.mouse.click(box.x, box.y);
  await p.waitForTimeout(2500);
};

// Ce que les pages portent, dans la langue de la capture (les ARB) : on
// touche par le libellé, pas par la position, que la mise en page déplace.
const LABELS = {
  'fr-FR': { careHowTo: 'Comment en prendre soin', schedule: 'Planning', diagnosis: 'Voir le diagnostic complet' },
  'en-US': { careHowTo: 'How to care for it', schedule: 'Schedule', diagnosis: 'See the full diagnosis' },
  'de-DE': { careHowTo: 'So pflegst du sie', schedule: 'Pflegeplan', diagnosis: 'Vollständige Diagnose ansehen' },
  'it-IT': { careHowTo: 'Come prendersene cura', schedule: 'Programma', diagnosis: 'Vedere la diagnosi completa' },
}[locale];
// Les cases de la grille des plantes, sous la tête verte : Basilic et
// Calathea sur la première rangée, le Ficus sous le Basilic.
const CASE = { basilic: [104, 450], calathea: [286, 450], ficus: [104, 690] };

await go('/today', 7000); await shot('today');
await go('/plants', 4000); await shot('plants');
await p.mouse.click(...CASE.basilic); await p.waitForTimeout(3000);
await shot('plant');
// La carte d'entretien est sous l'en-tête photo : on descend jusqu'à elle
// (Flutter ne la construit qu'à l'approche), puis on la touche par son titre.
await swipe(195, 760, 260); await swipe(195, 760, 360);
await a11y(); await tap(LABELS.careHowTo); await p.waitForTimeout(1000); await shot('care');
await go('/plants', 4000); await p.mouse.click(...CASE.basilic); await p.waitForTimeout(3000);
await a11y(); await tap(LABELS.schedule); await p.waitForTimeout(1000); await shot('schedule');
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
await go('/plants', 4000); await p.mouse.click(...CASE.calathea); await p.waitForTimeout(3000);
await swipe(195, 760, 60); await swipe(195, 700, 400); await a11y(); await tap(LABELS.diagnosis); await p.waitForTimeout(1000); await shot('diagnosis');
// La fiche du Ficus : c'est elle que la feuille « Espèce » recouvre, et
// c'est sur elle que compose.py la redessine faute de modèle sur le web.
await go('/plants', 4000); await p.mouse.click(...CASE.ficus); await p.waitForTimeout(3000); await shot('plant-ficus');
await b.close();

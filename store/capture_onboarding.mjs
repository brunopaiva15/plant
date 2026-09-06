// Captures de l'onboarding, écran par écran, en clair et en sombre.
//
// Prérequis : `flutter build web --profile --no-web-resources-cdn`, puis
// `python3 store/serve.py 8081 build/web`.
//
// Usage : node store/capture_onboarding.mjs <dossier de sortie> [fr-FR]
import { chromium } from 'playwright';
import { execSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
const out = process.argv[2], locale = process.argv[3] || 'fr-FR';
mkdirSync(out, { recursive: true });
const b = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined, args: ['--no-sandbox'] });

for (const scheme of ['light', 'dark']) {
  const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, locale, colorScheme: scheme });
  await p.route(/fonts\.gstatic\.com|fonts\.googleapis\.com/, async route => {
    try {
      const body = execSync(`curl -sS --max-time 30 "${route.request().url()}"`, { maxBuffer: 64 * 1024 * 1024 });
      await route.fulfill({ status: 200, body, headers: { 'content-type': 'font/woff2', 'access-control-allow-origin': '*' } });
    } catch (e) { await route.abort(); }
  });
  await p.goto('http://localhost:8081/?demo&ios#/onboarding', { waitUntil: 'load' });
  await p.waitForTimeout(7000);
  const shot = (n) => p.screenshot({ path: `${out}/${scheme}-${n}.png` });
  await shot('1');
  // « Continuer » : le bouton plein du bas. L'objet met trois secondes à se
  // poser : on attend qu'il soit net.
  for (let i = 2; i <= 5; i++) { await p.mouse.click(195, 798); await p.waitForTimeout(4000); await shot(String(i)); }
  // Après les cinq présentations vient l'étape du lieu, avec ses propres
  // boutons ; « Plus tard » mène au prénom.
  await p.mouse.click(195, 798); await p.waitForTimeout(2600); await shot('place');
  await p.close();
}
await b.close();

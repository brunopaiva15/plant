// Ce que le relais laisse passer vers les AI Services.
//
//   deno run --allow-env supabase/functions/relay/upstreams_test.ts
//
// Sous Deno seulement : la configuration du relais lit `Deno.env`.

import { chatBody } from './upstreams.ts';

let failures = 0;

function check(name: string, condition: boolean): void {
  console.log(`  ${condition ? 'ok  ' : 'ÉCHEC'} ${name}`);
  if (!condition) failures++;
}

const encode = (value: unknown) => new TextEncoder().encode(JSON.stringify(value));
const withPhoto = (maxTokens: number) => encode({
  max_tokens: maxTokens,
  messages: [{ role: 'user', content: [{ type: 'image_url', image_url: { url: 'data:image/jpeg;base64,AA==' } }, { type: 'text', text: 'Ma plante' }] }],
});
const textOnly = (maxTokens: number) => encode({ max_tokens: maxTokens, messages: [{ role: 'user', content: 'Ma plante' }] });

console.log('\nLe budget de jetons');
check('une demande avec photo reçoit au moins 8000 jetons', chatBody(withPhoto(5000)).max_tokens === 8000);
check('une demande avec photo garde un budget plus large', chatBody(withPhoto(9000)).max_tokens === 9000);
check('une demande sans photo garde son budget', chatBody(textOnly(700)).max_tokens === 700);
check('rien ne dépasse le plafond', chatBody(withPhoto(50000)).max_tokens === 12000);
check('le modèle vient du relais, pas du client', typeof chatBody(textOnly(700)).model === 'string');
check('le relais ne rend pas de flux', chatBody(textOnly(700)).stream === false);

console.log(`\n${failures === 0 ? 'tout passe' : `${failures} en échec`}\n`);
if (failures > 0) {
  if (typeof (globalThis as { Deno?: { exit(code: number): never } }).Deno !== 'undefined') {
    (globalThis as unknown as { Deno: { exit(code: number): never } }).Deno.exit(1);
  }
  (globalThis as unknown as { process: { exitCode: number } }).process.exitCode = 1;
}

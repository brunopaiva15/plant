// Page publique d'un lien de partage Flora.
//
// GET /functions/v1/share/<token>
//
// Ne rend qu'un lien vivant : non révoqué, non expiré, plante non supprimée.
// La lecture passe par `public_shared_link`, une fonction SQL security definer :
// la table `shared_links` reste inaccessible aux anonymes.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const PHOTO_BUCKET = 'plant-photos';

/** Échappe le texte inséré dans le HTML : aucun contenu utilisateur n'est brut. */
function esc(value: unknown): string {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function page(body: string, opts: { title: string; description?: string; keywords?: string; noindex: boolean; image?: string; status?: number }) {
  const html = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(opts.title)}</title>
${opts.noindex ? '<meta name="robots" content="noindex, nofollow">' : ''}
${opts.description ? `<meta name="description" content="${esc(opts.description)}">` : ''}
${opts.keywords ? `<meta name="keywords" content="${esc(opts.keywords)}">` : ''}
<meta property="og:title" content="${esc(opts.title)}">
${opts.description ? `<meta property="og:description" content="${esc(opts.description)}">` : ''}
${opts.image ? `<meta property="og:image" content="${esc(opts.image)}">` : ''}
<meta name="color-scheme" content="light dark">
<style>
  :root { --canvas:#f3f6f1; --surface:#fff; --ink:#14201a; --ink2:#5a6b60; --sage:#2e8b57; --line:#e4eae4; }
  @media (prefers-color-scheme: dark) {
    :root { --canvas:#0d100e; --surface:#161a17; --ink:#f2f5f2; --ink2:#9aa79f; --line:#242a25; }
  }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--canvas); color:var(--ink);
         font:16px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
         display:flex; justify-content:center; padding:24px 16px 48px; }
  main { width:100%; max-width:560px; }
  .card { background:var(--surface); border:1px solid var(--line); border-radius:24px; overflow:hidden; }
  img { width:100%; display:block; background:var(--line); }
  .body { padding:20px 22px 24px; }
  h1 { margin:0 0 4px; font-size:26px; letter-spacing:-0.02em; }
  .species { margin:0 0 12px; color:var(--sage); font-style:italic; }
  p { margin:0 0 8px; color:var(--ink2); }
  .meta { margin-top:14px; font-size:13px; color:var(--ink2); }
  footer { margin-top:20px; text-align:center; font-size:13px; color:var(--ink2); }
  footer b { color:var(--sage); }
</style>
</head>
<body><main>${body}<footer>Partagé depuis <b>Flora</b></footer></main></body>
</html>`;
  return new Response(html, {
    status: opts.status ?? 200,
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': opts.noindex ? 'private, max-age=0, no-store' : 'public, max-age=300',
      'x-robots-tag': opts.noindex ? 'noindex, nofollow' : 'all',
      'referrer-policy': 'no-referrer',
      'content-security-policy': "default-src 'none'; img-src https: data:; style-src 'unsafe-inline'",
    },
  });
}

const notFound = () =>
  page('<div class="card"><div class="body"><h1>Lien indisponible</h1><p>Ce partage a été révoqué, a expiré, ou n\'existe pas.</p></div></div>', {
    title: 'Lien indisponible',
    noindex: true,
    status: 404,
  });

Deno.serve(async (req) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') return new Response('Method not allowed', { status: 405 });

  const token = new URL(req.url).pathname.split('/').filter(Boolean).pop() ?? '';
  if (!/^[A-Za-z0-9]{16,40}$/.test(token)) return notFound();

  const client = createClient(SUPABASE_URL, ANON_KEY);
  const { data, error } = await client.rpc('public_shared_link', { p_token: token });
  const link = Array.isArray(data) ? data[0] : data;
  if (error || !link) return notFound();

  const image = link.photo_path ? `${SUPABASE_URL}/storage/v1/object/public/${PHOTO_BUCKET}/${link.photo_path}` : undefined;
  const title = link.title || link.plant_name || 'Une plante';
  const taken = link.taken_at ? new Date(link.taken_at).toLocaleDateString('fr-CH', { year: 'numeric', month: 'long', day: 'numeric' }) : '';

  const body = `<div class="card">
  ${image ? `<img src="${esc(image)}" alt="${esc(link.photo_label || title)}" loading="lazy">` : ''}
  <div class="body">
    <h1>${esc(title)}</h1>
    ${link.species_name ? `<p class="species">${esc(link.species_name)}</p>` : ''}
    ${link.description ? `<p>${esc(link.description)}</p>` : ''}
    ${link.photo_label ? `<p>${esc(link.photo_label)}</p>` : ''}
    ${taken ? `<div class="meta">Photo du ${esc(taken)}</div>` : ''}
  </div>
</div>`;

  return page(body, {
    title,
    description: link.description ?? undefined,
    keywords: link.keywords ?? undefined,
    noindex: link.unlisted !== false,
    image,
  });
});

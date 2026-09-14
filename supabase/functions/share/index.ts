// Page publique d'un lien de partage Auxine.
//
// GET /functions/v1/share/<token>       une plante ou une photo partagée
// GET /functions/v1/share/join/<code>   une invitation à collaborer dans un jardin
// GET /functions/v1/share/asset/<nom>   la fonte et le grain de la page
//
// Ne rend qu'un lien vivant : non révoqué, non expiré, plante non supprimée.
// La lecture passe par `public_shared_link` et `public_invite`, deux fonctions
// SQL security definer : ni `shared_links` ni `garden_invites` ne sont
// accessibles aux anonymes.
//
// L'habillage de la page vit dans `page.ts` ; ce fichier route et interroge.
import { createClient } from 'jsr:@supabase/supabase-js@2';

import { ASSETS } from './assets.ts';
import { esc, notFound, page } from './page.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const PHOTO_BUCKET = 'plant-photos';

/** La vignette des messageries, servie par cette fonction même. Adresse
 * absolue et jointe à Supabase : elle vaut de partout, y compris quand la
 * page, elle, est servie par le relais. La passerelle ne réécrit que le
 * HTML, une image lui passe entre les doigts. */
const PREVIEW = {
  image: `${SUPABASE_URL}/functions/v1/share/asset/preview.jpg`,
  imageWidth: 1200,
  imageHeight: 630,
  imageAlt: 'Auxine',
};

/** Schéma des liens de l'application : `auxine://join/<code>`. */
const APP_SCHEME = 'auxine';

const roleLabels: Record<string, string> = {
  member: 'ajouter, modifier et supprimer des plantes',
  viewer: 'consulter le jardin, sans rien y changer',
};

/**
 * Page d'atterrissage d'une invitation. Elle ne fait rien elle-même : le code
 * ne vaut que dans l'application, échangé contre une place par un compte
 * connecté. La page dit qui invite, et ouvre l'application.
 */
async function invitePage(code: string, assetBase: string) {
  const client = createClient(SUPABASE_URL, ANON_KEY);
  const { data, error } = await client.rpc('public_invite', { p_code: code });
  const invite = Array.isArray(data) ? data[0] : data;
  if (error || !invite) return notFound(assetBase);

  const garden = invite.garden_name || 'un jardin';
  const owner = invite.owner_name || '';
  const title = owner ? `${owner} vous invite dans « ${garden} »` : `Invitation dans « ${garden} »`;
  // La même phrase tient lieu de description dans les messageries : elle dit
  // ce que l'invitation donne, ce qu'un titre seul laisse deviner.
  const role = `Vous pourrez ${roleLabels[invite.role] ?? roleLabels.member}.`;
  const body = `<div class="card"><div class="body">
  <h1>${esc(title)}</h1>
  <p class="lead">${esc(role)}</p>
  <a class="open" href="${esc(`${APP_SCHEME}://join/${code}`)}">Ouvrir dans Auxine</a>
  <p class="lead">Pas encore l'application ? Installez Auxine, créez un compte${invite.needs_email ? ' avec l’adresse invitée' : ''}, puis saisissez ce code dans <b>Réglages › Mes jardins › Rejoindre un jardin</b> :</p>
  <p class="code">${esc(code.length === 8 ? `${code.slice(0, 4)}-${code.slice(4)}` : code)}</p>
  <p class="meta">L'invitation ne sert qu'une fois.</p>
</div></div>`;
  return page(body, { title, assetBase, description: role, noindex: true, ...PREVIEW });
}

/** La fonte et le grain, gardés un an : leur contenu ne change qu'avec leur nom. */
function assetResponse(name: string) {
  const asset = ASSETS[name];
  if (!asset) return null;
  return new Response(asset.bytes, {
    headers: {
      'content-type': asset.type,
      'cache-control': 'public, max-age=31536000, immutable',
      'x-robots-tag': 'noindex, nofollow',
    },
  });
}

Deno.serve(async (req) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') return new Response('Method not allowed', { status: 405 });

  const segments = new URL(req.url).pathname.split('/').filter(Boolean);
  const last = segments.pop() ?? '';
  const kind = segments[segments.length - 1];
  // La page pointe ses pièces en relatif, jamais depuis la racine : ce qui
  // précède la route n'est pas le même des deux côtés — vide derrière le
  // relais, `/share` dans le runtime Supabase, qui a déjà retiré
  // `/functions/v1`. Or l'asset est toujours le voisin de la route : d'un
  // `/join/<code>` il est un cran plus haut, d'un `/<jeton>` il est à côté.
  // Cela suffit, et la page s'habille des deux côtés sans rien deviner.
  const UP = '..';
  const HERE = '.';

  if (kind === 'asset') {
    return assetResponse(last) ?? notFound(HERE);
  }
  if (kind === 'join') {
    return /^[A-Za-z0-9]{6,16}$/.test(last) ? await invitePage(last.toUpperCase(), UP) : notFound(UP);
  }

  const assetBase = HERE;
  if (!/^[A-Za-z0-9]{16,40}$/.test(last)) return notFound(assetBase);

  const client = createClient(SUPABASE_URL, ANON_KEY);
  const { data, error } = await client.rpc('public_shared_link', { p_token: last });
  const link = Array.isArray(data) ? data[0] : data;
  if (error || !link) return notFound(assetBase);

  const image = link.photo_path ? `${SUPABASE_URL}/storage/v1/object/public/${PHOTO_BUCKET}/${link.photo_path}` : undefined;
  const title = link.title || link.plant_name || 'Une plante';
  const taken = link.taken_at ? new Date(link.taken_at).toLocaleDateString('fr-CH', { year: 'numeric', month: 'long', day: 'numeric' }) : '';

  const body = `<div class="card">
  ${image ? `<img src="${esc(image)}" alt="${esc(link.photo_label || title)}" loading="lazy">` : ''}
  <div class="body">
    <h1>${esc(title)}</h1>
    ${link.species_name ? `<p class="species">${esc(link.species_name)}</p>` : ''}
    ${link.description ? `<p>${esc(link.description)}</p>` : ''}
    ${link.photo_label ? `<p class="lead">${esc(link.photo_label)}</p>` : ''}
    ${taken ? `<p class="meta">Photo du ${esc(taken)}</p>` : ''}
  </div>
</div>`;

  return page(body, {
    title,
    assetBase,
    description: link.description ?? undefined,
    keywords: link.keywords ?? undefined,
    noindex: link.unlisted !== false,
    // La photo quand il y en a une — ses dimensions, elles, sont inconnues,
    // et les annoncer fausses vaut moins que se taire. Sans photo, la
    // vignette de l'app plutôt qu'un lien nu.
    ...(image ? { image, imageAlt: link.photo_label || title } : PREVIEW),
  });
});

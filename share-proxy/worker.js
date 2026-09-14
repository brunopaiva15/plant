// Relais public des pages de partage et d'invitation.
//
// Supabase force `text/plain` sur le HTML qu'une fonction Edge sert depuis
// `*.supabase.co` : c'est sa protection contre les pages d'hameçonnage
// hébergées sous son nom. Le navigateur affiche alors la source de la page,
// accents cassés — le `charset` tombe avec le type. Servie depuis un domaine
// qui n'est pas le sien, la page n'a plus lieu d'être bridée.
//
// Ce Worker relaie la requête vers la fonction `share` et rend à la réponse
// le type et la politique de sécurité qu'elle avait écrits. La page, elle,
// reste dans `supabase/functions/share/index.ts` : il n'y a rien à tenir en
// double ici.
//
// Déploiement : docs/08-sync-and-collaboration.md, « Mise en place ».

export default {
  async fetch(request, env) {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method not allowed', { status: 405 });
    }

    const upstream = (env.SHARE_UPSTREAM ?? '').replace(/\/+$/, '');
    if (!upstream.startsWith('https://')) {
      return new Response('SHARE_UPSTREAM manquant', { status: 500 });
    }

    // Les chemins se superposent tels quels : `/join/<code>` et `/<jeton>`
    // sont ce que la fonction attend déjà derrière `…/functions/v1/share`.
    const { pathname, search } = new URL(request.url);
    const origin = await fetch(`${upstream}${pathname}${search}`, { method: request.method });

    const response = new Response(origin.body, origin);
    // La passerelle ne réécrit que le HTML, et toujours en `text/plain` :
    // là où elle est passée, le type d'origine revient. La fonte et le grain
    // servis sous `/asset/` gardent le leur.
    if ((response.headers.get('content-type') ?? '').startsWith('text/plain')) {
      response.headers.set('content-type', 'text/html; charset=utf-8');
    }
    // Même histoire pour la politique de sécurité, remplacée en chemin par
    // un `sandbox` qui empêcherait « Ouvrir dans Auxine » de s'ouvrir. La
    // fonction en publie un double sous un nom que la passerelle laisse
    // passer ; il reprend sa place ici.
    const csp = response.headers.get('x-auxine-csp');
    if (csp) {
      response.headers.set('content-security-policy', csp);
      response.headers.delete('x-auxine-csp');
    }
    // Le cookie d'analyse de la passerelle n'a rien à faire sur ce domaine.
    response.headers.delete('set-cookie');
    return response;
  },
};

-- Le fichier se rejoue tel quel dans l'éditeur SQL d'un projet existant :
-- tables « if not exists », colonnes ajoutées par « add column if not
-- exists », politiques et déclencheurs recréés après un « drop if exists ».
-- Mettre le schéma à jour, c'est le rejouer en entier.
-- Auxine — schéma Postgres (Supabase). Miroir du schéma local (docs/04-data-model.md).
-- Toutes les tables portent garden_id (directement ou via plant_id) ; l'accès est
-- gouverné par garden_members via RLS. Les IDs sont générés côté client (UUID v4).

create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  locale text,
  created_at timestamptz not null default now()
);

create table if not exists gardens (
  id uuid primary key,
  plant_counter int not null default 0,   -- dernier numéro « #42 » attribué
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists garden_members (
  garden_id uuid not null references gardens(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','member','viewer')),
  created_at timestamptz not null default now(),
  primary key (garden_id, user_id)
);

-- v8 : notes, photo et journal d'emplacement ; numéro court de plante.
create table if not exists locations (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  parent_id uuid references locations(id) on delete set null,
  name text not null,
  icon text not null default '🪴',
  light text,
  orientation text,
  is_outdoor boolean not null default false,
  notes text,
  photo_path text,
  thumb_path text,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists plants (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  number int not null default 0,      -- numéro court « #42 », unique par jardin
  name text not null,
  species_name text,
  location_id uuid references locations(id) on delete set null,
  primary_photo_id uuid,
  status text not null default 'active' check (status in ('active','archived')),
  health text not null default 'healthy' check (health in ('healthy','watch','sick')),
  is_favorite boolean not null default false,
  acquired_at timestamptz,
  source text,
  price numeric,
  pot_size numeric,
  notes text,
  parent_plant_id uuid references plants(id) on delete set null,
  archived_at timestamptz,
  archive_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- Les trois fonctions des règles d'accès, définies dès que leurs tables
-- existent : les premières règles (liens partagés) les appellent bien avant
-- la section RLS, et sur un projet neuf le script s'arrêtait là —
-- « function is_member(uuid) does not exist » — sans rien créer.
create or replace function is_member(g uuid) returns boolean language sql stable security definer as $$
  select exists(select 1 from garden_members where garden_id = g and user_id = auth.uid());
$$;
create or replace function can_edit(g uuid) returns boolean language sql stable security definer as $$
  select exists(select 1 from garden_members where garden_id = g and user_id = auth.uid() and role in ('owner','member'));
$$;
create or replace function plant_garden(p uuid) returns uuid language sql stable security definer as $$
  select garden_id from plants where id = p;
$$;

-- v11 : précision de l'état de santé et besoins propres à la plante.
alter table plants add column if not exists health_issue text
  check (health_issue in ('overwatering','underwatering','pests','disease','rootRot','transplantShock','deficiency','sunburn','frost'));
alter table plants add column if not exists light text
  check (light in ('shade','lowLight','indirect','brightIndirect','someSun','fullSun'));
alter table plants add column if not exists humidity text check (humidity in ('low','average','high'));
alter table plants add column if not exists lifespan text check (lifespan in ('annual','biennial','perennial'));
alter table plants add column if not exists hardiness text check (hardiness in ('hardy','tender'));
alter table plants add column if not exists cutting_month int check (cutting_month between 1 and 12);

-- Libellé et URL externe des photos (v7).
create table if not exists plant_photos (
  id uuid primary key,
  plant_id uuid not null references plants(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  storage_path text not null,          -- plant-photos/{garden_id}/{plant_id}/{id}.jpg
  thumb_path text not null,
  label text,                          -- titre libre (v7)
  remote_url text,                     -- photo hébergée ailleurs (v7)
  width int not null,
  height int not null,
  taken_at timestamptz not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists action_types (
  key text primary key,
  garden_id uuid references gardens(id) on delete cascade,  -- null = intégré
  label text,
  emoji text not null,
  is_builtin boolean not null default false,
  schedulable boolean not null default true,
  sort_order int not null default 0
);

create table if not exists plant_actions (
  id uuid primary key,
  plant_id uuid not null references plants(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  type_key text not null,
  occurred_at timestamptz not null,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  photo_id uuid references plant_photos(id) on delete set null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists care_schedules (
  id uuid primary key,
  plant_id uuid not null references plants(id) on delete cascade,
  type_key text not null,
  strategy text not null check (strategy in ('fixed','seasonal','weather','manual')),
  interval_days int not null,
  seasonal_rules jsonb,
  next_due_at timestamptz,
  last_completed_at timestamptz,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists tags (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists plant_tags (
  plant_id uuid not null references plants(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  primary key (plant_id, tag_id)
);

create table if not exists measurements (
  id uuid primary key,
  plant_id uuid not null references plants(id) on delete cascade,
  action_id uuid references plant_actions(id) on delete set null,
  kind text not null,
  value numeric not null,
  unit text not null default '',
  measured_at timestamptz not null
);

create table if not exists inventory_groups (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  label text not null,
  emoji text not null default '📦',
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_inventory_groups_garden on inventory_groups(garden_id, updated_at);

create table if not exists inventory_items (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  category_key text not null,
  name text not null,
  quantity numeric not null default 0,
  unit text not null default '',
  low_threshold numeric,
  location_id uuid references locations(id) on delete set null,
  group_id uuid references inventory_groups(id) on delete set null,
  notes text,
  photo_path text,
  thumb_path text,
  fertilizer_form text check (fertilizer_form in ('liquid','granules','sticks','solublePowder','foliar','other')),
  fertilizer_origin text check (fertilizer_origin in ('mineral','organic','organomineral')),
  nitrogen numeric check (nitrogen between 0 and 100),
  phosphorus numeric check (phosphorus between 0 and 100),
  potassium numeric check (potassium between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
-- Projets créés avant les groupes d'inventaire : la colonne manquait, et
-- PostgREST refusait alors chaque objet poussé par l'app (« Could not find
-- the 'group_id' column »), ce qui arrêtait toute la synchronisation.
alter table inventory_items add column if not exists group_id uuid references inventory_groups(id) on delete set null;
-- Caractérisation des engrais (schéma local v12) : mêmes colonnes, même
-- raison de les ajouter après coup aux projets déjà en place.
alter table inventory_items add column if not exists fertilizer_form text
  check (fertilizer_form in ('liquid','granules','sticks','solublePowder','foliar','other'));
alter table inventory_items add column if not exists fertilizer_origin text
  check (fertilizer_origin in ('mineral','organic','organomineral'));
alter table inventory_items add column if not exists nitrogen numeric check (nitrogen between 0 and 100);
alter table inventory_items add column if not exists phosphorus numeric check (phosphorus between 0 and 100);
alter table inventory_items add column if not exists potassium numeric check (potassium between 0 and 100);

create table if not exists tasks (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  plant_id uuid references plants(id) on delete set null,
  title text not null,
  description text,
  due_at timestamptz,
  all_day boolean not null default true,
  recurrence_value integer,
  recurrence_unit text,
  done boolean not null default false,
  done_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_tasks_garden_updated on tasks(garden_id, updated_at);

create table if not exists attribute_schemas (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  label text not null,
  datatype text not null,
  active boolean not null default true,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_attr_schemas_garden_updated on attribute_schemas(garden_id, updated_at);

create table if not exists plant_attributes (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  plant_id uuid not null references plants(id) on delete cascade,
  label text not null,
  datatype text not null,
  value text,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_plant_attributes_plant on plant_attributes(plant_id);
create index if not exists idx_plant_attributes_garden_updated on plant_attributes(garden_id, updated_at);

create table if not exists event_categories (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  label text not null,
  emoji text not null default '📅',
  color_key text,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_event_categories_garden on event_categories(garden_id, updated_at);

create table if not exists calendar_entries (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  plant_id uuid references plants(id) on delete set null,
  category_id uuid references event_categories(id) on delete set null,
  title text not null,
  notes text,
  start_at timestamptz not null,
  end_at timestamptz,
  all_day boolean not null default true,
  reminder_minutes integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_calendar_entries_garden on calendar_entries(garden_id, start_at);

create table if not exists inventory_tags (
  item_id uuid not null references inventory_items(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  primary key (item_id, tag_id)
);

create table if not exists location_logs (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  location_id uuid not null references locations(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_location_logs_location on location_logs(location_id, created_at desc);

create table if not exists plant_attachments (
  id uuid primary key,
  garden_id uuid not null references gardens(id) on delete cascade,
  plant_id uuid not null references plants(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  label text not null,
  file_path text not null,
  mime_type text,
  size_bytes bigint,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_plant_attachments_plant on plant_attachments(plant_id);
create index if not exists idx_plant_attachments_garden_updated on plant_attachments(garden_id, updated_at);

-- Partage public d'une photo ou d'une plante par lien révocable.
-- `kind` vaut 'photo' ou 'plant'. Un lien « non listé » (unlisted) porte un
-- en-tête noindex sur la page publique.
create table if not exists shared_links (
  id uuid primary key default gen_random_uuid(),
  garden_id uuid not null references gardens(id) on delete cascade,
  plant_id uuid not null references plants(id) on delete cascade,
  photo_id uuid references plant_photos(id) on delete cascade,
  kind text not null default 'plant',
  token text not null unique,
  title text,
  description text,
  keywords text,
  unlisted boolean not null default true,
  expires_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  revoked_at timestamptz
);
create index if not exists idx_shared_links_garden on shared_links(garden_id, created_at desc);

alter table shared_links enable row level security;
drop policy if exists "shared links read" on shared_links;
create policy "shared links read" on shared_links for select using (is_member(garden_id));
drop policy if exists "shared links write" on shared_links;
create policy "shared links write" on shared_links for all using (can_edit(garden_id)) with check (can_edit(garden_id));

-- Lecture publique d'un lien vivant, sans exposer la table : la fonction est
-- security definer et ne rend que ce qui est nécessaire à la page publique.
create or replace function public_shared_link(p_token text)
returns table (
  kind text,
  title text,
  description text,
  keywords text,
  unlisted boolean,
  plant_name text,
  species_name text,
  photo_path text,
  photo_label text,
  taken_at timestamptz
) language sql security definer set search_path = public as $$
  select s.kind, s.title, s.description, s.keywords, s.unlisted,
         p.name, p.species_name, ph.storage_path, ph.label, ph.taken_at
  from shared_links s
  join plants p on p.id = s.plant_id
  left join plant_photos ph on ph.id = s.photo_id
  where s.token = p_token
    and s.revoked_at is null
    and (s.expires_at is null or s.expires_at > now())
    and p.deleted_at is null;
$$;
revoke all on function public_shared_link(text) from public;
grant execute on function public_shared_link(text) to anon, authenticated;

-- Index de synchronisation (delta par updated_at) et d'accès.
create index if not exists idx_plants_garden_updated on plants(garden_id, updated_at);
create unique index if not exists idx_plants_number on plants(garden_id, number) where number > 0;
create index if not exists idx_locations_garden_updated on locations(garden_id, updated_at);
create index if not exists idx_actions_plant on plant_actions(plant_id, occurred_at);
create index if not exists idx_schedules_plant on care_schedules(plant_id);
create index if not exists idx_photos_plant on plant_photos(plant_id);
create index if not exists idx_inventory_garden on inventory_items(garden_id, updated_at);

-- updated_at automatique côté serveur : le client n'est jamais cru sur l'horloge.
create or replace function set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
do $$ declare t text; begin
  foreach t in array array['gardens','locations','plants','care_schedules','inventory_items','tasks','attribute_schemas','plant_attributes','plant_attachments','location_logs','inventory_groups','event_categories','calendar_entries'] loop
    execute format('drop trigger if exists trg_%s_updated on %s', t, t);
    execute format('create trigger trg_%s_updated before update on %s for each row execute function set_updated_at()', t, t);
  end loop;
end $$;

-- Le créateur d'un jardin en devient owner.
create or replace function add_owner_membership() returns trigger language plpgsql security definer as $$
begin
  insert into garden_members(garden_id, user_id, role) values (new.id, new.owner_id, 'owner') on conflict do nothing;
  return new;
end $$;
drop trigger if exists trg_garden_owner on gardens;
create trigger trg_garden_owner after insert on gardens for each row execute function add_owner_membership();

-- ---------- Row Level Security ----------
alter table profiles enable row level security;
drop policy if exists "own profile" on profiles;
create policy "own profile" on profiles for all using (id = auth.uid()) with check (id = auth.uid());

alter table gardens enable row level security;
drop policy if exists "gardens read" on gardens;
create policy "gardens read" on gardens for select using (is_member(id) or owner_id = auth.uid());
drop policy if exists "gardens insert" on gardens;
create policy "gardens insert" on gardens for insert with check (owner_id = auth.uid());
drop policy if exists "gardens update" on gardens;
create policy "gardens update" on gardens for update using (owner_id = auth.uid());

alter table garden_members enable row level security;
drop policy if exists "members read" on garden_members;
create policy "members read" on garden_members for select using (is_member(garden_id));
drop policy if exists "members manage" on garden_members;
create policy "members manage" on garden_members for all
  using (exists(select 1 from gardens g where g.id = garden_id and g.owner_id = auth.uid()))
  with check (exists(select 1 from gardens g where g.id = garden_id and g.owner_id = auth.uid()));

-- Tables portant garden_id.
do $$ declare t text; begin
  foreach t in array array['locations','plants','tags','inventory_items','tasks','attribute_schemas','plant_attributes','plant_attachments','location_logs','inventory_groups','event_categories','calendar_entries'] loop
    execute format('alter table %s enable row level security', t);
    execute format('drop policy if exists "%s read" on %s', t, t);
    execute format('create policy "%s read" on %s for select using (is_member(garden_id))', t, t);
    execute format('drop policy if exists "%s write" on %s', t, t);
    execute format('create policy "%s write" on %s for all using (can_edit(garden_id)) with check (can_edit(garden_id))', t, t);
  end loop;
end $$;

-- Tables filles de plants.
do $$ declare t text; begin
  foreach t in array array['plant_photos','plant_actions','care_schedules','plant_tags','measurements','shared_links'] loop
    execute format('alter table %s enable row level security', t);
    execute format('drop policy if exists "%s read" on %s', t, t);
    execute format('create policy "%s read" on %s for select using (is_member(plant_garden(plant_id)))', t, t);
    execute format('drop policy if exists "%s write" on %s', t, t);
    execute format('create policy "%s write" on %s for all using (can_edit(plant_garden(plant_id))) with check (can_edit(plant_garden(plant_id)))', t, t);
  end loop;
end $$;

alter table action_types enable row level security;
drop policy if exists "types read" on action_types;
create policy "types read" on action_types for select using (garden_id is null or is_member(garden_id));
drop policy if exists "types write" on action_types;
create policy "types write" on action_types for all using (garden_id is not null and can_edit(garden_id)) with check (garden_id is not null and can_edit(garden_id));

-- Storage : bucket privé, chemin plant-photos/{garden_id}/... ; accès par appartenance au jardin.
insert into storage.buckets (id, name, public) values ('plant-photos', 'plant-photos', false) on conflict do nothing;
drop policy if exists "photos read" on storage.objects;
create policy "photos read" on storage.objects for select using (bucket_id = 'plant-photos' and is_member((storage.foldername(name))[1]::uuid));
drop policy if exists "photos write" on storage.objects;
create policy "photos write" on storage.objects for insert with check (bucket_id = 'plant-photos' and can_edit((storage.foldername(name))[1]::uuid));
drop policy if exists "photos delete" on storage.objects;
create policy "photos delete" on storage.objects for delete using (bucket_id = 'plant-photos' and can_edit((storage.foldername(name))[1]::uuid));

-- ---------- Retours pour Iris ----------
-- Une identification que la personne a enregistrée : ses photos, ce qu'Iris
-- croyait, le nom retenu. Le geste d'enregistrer étiquette la photo sans rien
-- demander de plus (docs/09 § 13.3, chantier 2). Consentement explicite côté
-- application, éteint par défaut ; les lignes et les fichiers ne sont lisibles
-- que par leur auteur, et partent avec le compte.
create table if not exists iris_feedback (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,          -- iris-feedback/{user_id}/{id}/{n}.jpg, n < photos
  photos int not null check (photos between 1 and 3),
  species_id text not null,            -- identifiant interne, ex. hoya-kerrii
  species_name text not null,
  kind text not null check (kind in ('corrigee', 'confirmee', 'reclassee')),
  chosen_source text not null check (chosen_source in ('local', 'remote', 'picker')),
  local_top5 jsonb not null,           -- [{id, name, score}] ce qu'Iris croyait, dans l'ordre
  remote_top1 jsonb,                   -- {name, score} ce que Pl@ntNet a répondu, s'il a été appelé
  model_version text not null,
  app_version text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_iris_feedback_created on iris_feedback(created_at);

alter table iris_feedback enable row level security;
drop policy if exists "own feedback" on iris_feedback;
create policy "own feedback" on iris_feedback for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Storage : bucket privé, chemin iris-feedback/{user_id}/... ; l'auteur seul.
-- Pas le seau des photos de jardin : celui-là est partagé avec les membres.
insert into storage.buckets (id, name, public) values ('iris-feedback', 'iris-feedback', false) on conflict do nothing;
drop policy if exists "feedback read" on storage.objects;
create policy "feedback read" on storage.objects for select using (bucket_id = 'iris-feedback' and (storage.foldername(name))[1]::uuid = auth.uid());
drop policy if exists "feedback write" on storage.objects;
create policy "feedback write" on storage.objects for insert with check (bucket_id = 'iris-feedback' and (storage.foldername(name))[1]::uuid = auth.uid());
drop policy if exists "feedback delete" on storage.objects;
create policy "feedback delete" on storage.objects for delete using (bucket_id = 'iris-feedback' and (storage.foldername(name))[1]::uuid = auth.uid());

-- ---------- Profils & invitations ----------
-- Un profil par utilisateur, créé à l'inscription (nom d'affichage pour « Arrosée par Laura »).
--
-- Le déclencheur s'exécute dans la transaction qui insère la ligne
-- `auth.users` : ce qu'il laisse échouer emporte la création du compte, et
-- GoTrue répond « Database error saving new user ». Un nom d'affichage ne
-- vaut pas un compte, donc rien ici ne remonte.
--   - `display_name` est `not null` : le nom se replie jusqu'à la chaîne
--     vide. Une connexion par Apple n'apporte pas de `display_name`, et son
--     jeton d'identité ne porte pas toujours la revendication `email` —
--     `split_part(null, '@', 1)` vaut null, que la colonne refusait.
--   - Le reste est attrapé et ignoré : l'application réécrit ce profil juste
--     après la connexion (`SupabaseAuthRepository.updateDisplayName`).
create or replace function handle_new_user() returns trigger language plpgsql security definer as $$
begin
  insert into profiles(id, display_name) values (new.id, coalesce(
      nullif(new.raw_user_meta_data->>'display_name', ''),
      nullif(new.raw_user_meta_data->>'full_name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      ''))
  on conflict (id) do nothing;
  return new;
exception when others then
  return new;
end $$;
drop trigger if exists trg_new_user on auth.users;
create trigger trg_new_user after insert on auth.users for each row execute function handle_new_user();

-- Les membres d'un même jardin peuvent lire les profils des autres membres.
drop policy if exists "own profile" on profiles;
drop policy if exists "profiles read" on profiles;
create policy "profiles read" on profiles for select using (
  id = auth.uid() or exists (
    select 1 from garden_members a join garden_members b on a.garden_id = b.garden_id
    where a.user_id = auth.uid() and b.user_id = profiles.id)
);
drop policy if exists "profiles write" on profiles;
create policy "profiles write" on profiles for all using (id = auth.uid()) with check (id = auth.uid());

-- Inviter par e-mail : seul le propriétaire du jardin ; l'invité doit déjà avoir un compte.
create or replace function invite_member(p_garden_id uuid, p_email text, p_role text)
returns void language plpgsql security definer as $$
declare v_user uuid;
begin
  if not exists (select 1 from gardens where id = p_garden_id and owner_id = auth.uid()) then
    raise exception 'not_owner';
  end if;
  if p_role not in ('member','viewer') then raise exception 'bad_role'; end if;
  select id into v_user from auth.users where lower(email) = lower(p_email) limit 1;
  if v_user is null then raise exception 'user_not_found'; end if;
  insert into garden_members(garden_id, user_id, role) values (p_garden_id, v_user, p_role)
  on conflict (garden_id, user_id) do update set role = excluded.role;
end $$;

-- Membres d'un jardin avec leur nom (lecture pour tout membre).
create or replace function garden_members_with_names(p_garden_id uuid)
returns table(user_id uuid, role text, display_name text, email text) language sql stable security definer as $$
  select m.user_id, m.role, coalesce(p.display_name, ''), u.email::text
  from garden_members m
  left join profiles p on p.id = m.user_id
  left join auth.users u on u.id = m.user_id
  where m.garden_id = p_garden_id and is_member(p_garden_id);
$$;

-- ---------- Invitations : partager un jardin par lien ----------
-- Une invitation porte un code court, à usage unique, éventuellement lié à une
-- adresse e-mail et à une date d'expiration. L'invité n'a pas besoin d'avoir
-- déjà un compte : il en crée un, puis échange le code contre une place dans le
-- jardin. Le code est tiré côté serveur : le client ne peut pas le deviner.
create table if not exists garden_invites (
  id uuid primary key default gen_random_uuid(),
  garden_id uuid not null references gardens(id) on delete cascade,
  code text not null unique,
  email text,                                  -- si renseigné, seul ce compte peut accepter
  role text not null check (role in ('member','viewer')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id) on delete set null,
  revoked_at timestamptz
);
create index if not exists idx_garden_invites_garden on garden_invites(garden_id, created_at desc);

alter table garden_invites enable row level security;
drop policy if exists "invites read" on garden_invites;
create policy "invites read" on garden_invites for select using (is_member(garden_id));
drop policy if exists "invites write" on garden_invites;
create policy "invites write" on garden_invites for all
  using (exists (select 1 from gardens g where g.id = garden_id and g.owner_id = auth.uid()))
  with check (exists (select 1 from gardens g where g.id = garden_id and g.owner_id = auth.uid()));

-- Code à 8 caractères, sans I, L, O, 0 ni 1 : il se dicte au téléphone.
-- Tirage par rejet pour rester uniforme (256 n'est pas multiple de 31).
-- `gen_random_bytes` vient de pgcrypto, que Supabase installe dans le schéma
-- `extensions` : sans lui dans le search_path, « function gen_random_bytes
-- does not exist », et aucune invitation ne se crée. Un schéma absent du
-- search_path est ignoré : le fichier reste valable sur un Postgres nu.
create or replace function new_invite_code() returns text language plpgsql set search_path = public, extensions as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  code text := '';
  b int;
begin
  for _i in 1..8 loop
    loop
      b := get_byte(gen_random_bytes(1), 0);
      exit when b < 248;
    end loop;
    code := code || substr(alphabet, 1 + (b % 31), 1);
  end loop;
  return code;
end $$;

create or replace function create_invite(p_garden_id uuid, p_email text default null, p_role text default 'member', p_days int default 14)
returns garden_invites language plpgsql security definer set search_path = public, extensions as $$
declare v garden_invites; v_code text;
begin
  if not exists (select 1 from gardens where id = p_garden_id and owner_id = auth.uid()) then raise exception 'not_owner'; end if;
  if p_role not in ('member','viewer') then raise exception 'bad_role'; end if;
  loop
    v_code := new_invite_code();
    exit when not exists (select 1 from garden_invites where code = v_code);
  end loop;
  insert into garden_invites(garden_id, code, email, role, created_by, expires_at)
  values (p_garden_id, v_code, nullif(lower(trim(coalesce(p_email, ''))), ''), p_role, auth.uid(),
          case when coalesce(p_days, 0) <= 0 then null else now() + make_interval(days => p_days) end)
  returning * into v;
  return v;
end $$;

-- Ce que voit l'invité avant d'accepter : le nom du jardin, celui qui l'invite,
-- le rôle proposé. Aucune ligne = code inconnu, révoqué, expiré ou déjà utilisé.
create or replace function preview_invite(p_code text)
returns table (garden_id uuid, garden_name text, owner_name text, role text, email text, already_member boolean)
language sql stable security definer set search_path = public as $$
  select i.garden_id, g.name, coalesce(p.display_name, ''), i.role, i.email,
         exists (select 1 from garden_members m where m.garden_id = i.garden_id and m.user_id = auth.uid())
  from garden_invites i
  join gardens g on g.id = i.garden_id
  left join profiles p on p.id = g.owner_id
  where upper(i.code) = upper(trim(p_code))
    and i.revoked_at is null and i.accepted_at is null
    and (i.expires_at is null or i.expires_at > now())
    and g.deleted_at is null;
$$;

-- Échange du code contre une place dans le jardin. Un membre déjà présent
-- garde son rôle : une invitation ne rétrograde jamais un propriétaire.
create or replace function accept_invite(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v garden_invites; v_email text;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  select * into v from garden_invites
   where upper(code) = upper(trim(p_code))
     and revoked_at is null and accepted_at is null
     and (expires_at is null or expires_at > now())
   for update;
  if v.id is null then raise exception 'invalid_code'; end if;
  select lower(email) into v_email from auth.users where id = auth.uid();
  if v.email is not null and v.email is distinct from v_email then raise exception 'wrong_email'; end if;
  insert into garden_members(garden_id, user_id, role) values (v.garden_id, auth.uid(), v.role)
  on conflict (garden_id, user_id) do nothing;
  update garden_invites set accepted_at = now(), accepted_by = auth.uid() where id = v.id;
  return v.garden_id;
end $$;

create or replace function revoke_invite(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update garden_invites i set revoked_at = now()
   where i.id = p_id and i.revoked_at is null
     and exists (select 1 from gardens g where g.id = i.garden_id and g.owner_id = auth.uid());
end $$;

-- Les jardins auxquels le compte a accès : le sien d'abord, puis ceux qu'on
-- lui a partagés. Sert au sélecteur de jardin de l'application.
create or replace function my_gardens()
returns table (id uuid, name text, owner_id uuid, owner_name text, role text, member_count int, plant_count int)
language sql stable security definer set search_path = public as $$
  select g.id, g.name, g.owner_id, coalesce(p.display_name, ''), m.role,
         (select count(*)::int from garden_members x where x.garden_id = g.id),
         (select count(*)::int from plants pl where pl.garden_id = g.id and pl.deleted_at is null and pl.status = 'active')
  from garden_members m
  join gardens g on g.id = m.garden_id
  left join profiles p on p.id = g.owner_id
  where m.user_id = auth.uid() and g.deleted_at is null
  order by (g.owner_id = auth.uid()) desc, g.name;
$$;

-- Changer le rôle d'un membre, ou le retirer : le propriétaire seulement, et
-- jamais sur lui-même — un jardin garde toujours son propriétaire.
create or replace function set_member_role(p_garden_id uuid, p_user_id uuid, p_role text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from gardens where id = p_garden_id and owner_id = auth.uid()) then raise exception 'not_owner'; end if;
  if p_role not in ('member','viewer') then raise exception 'bad_role'; end if;
  if p_user_id = auth.uid() then raise exception 'not_yourself'; end if;
  update garden_members set role = p_role
   where garden_id = p_garden_id and user_id = p_user_id and role <> 'owner';
end $$;

create or replace function remove_member(p_garden_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from gardens where id = p_garden_id and owner_id = auth.uid()) then raise exception 'not_owner'; end if;
  if p_user_id = auth.uid() then raise exception 'not_yourself'; end if;
  delete from garden_members where garden_id = p_garden_id and user_id = p_user_id and role <> 'owner';
end $$;

-- Quitter un jardin partagé. Le propriétaire ne peut pas quitter le sien.
create or replace function leave_garden(p_garden_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from gardens where id = p_garden_id and owner_id = auth.uid()) then raise exception 'owner_cannot_leave'; end if;
  delete from garden_members where garden_id = p_garden_id and user_id = auth.uid();
end $$;

-- Supprimer un jardin : le propriétaire seulement, et jamais le dernier — un
-- compte garde toujours un jardin à ouvrir. Tout part avec la ligne : les
-- plantes, le journal, les membres, les invitations (cascades). Les fichiers
-- du bucket, eux, sont retirés par l'appareil avant l'appel : le stockage ne
-- connaît pas les cascades.
--
-- Un jardin déjà absent n'est pas une erreur : l'appareil qui rejoue sa
-- demande doit pouvoir finir son ménage.
create or replace function delete_garden(p_garden_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from gardens where id = p_garden_id) then return; end if;
  if not exists (select 1 from gardens where id = p_garden_id and owner_id = auth.uid()) then raise exception 'not_owner'; end if;
  if (select count(*) from garden_members m join gardens g on g.id = m.garden_id
       where m.user_id = auth.uid() and g.deleted_at is null) < 2 then raise exception 'last_garden'; end if;
  delete from gardens where id = p_garden_id;
end $$;

do $$ declare f text; begin
  foreach f in array array[
    'create_invite(uuid,text,text,int)', 'preview_invite(text)', 'accept_invite(text)', 'revoke_invite(uuid)',
    'my_gardens()', 'set_member_role(uuid,uuid,text)', 'remove_member(uuid,uuid)', 'leave_garden(uuid)',
    'delete_garden(uuid)'] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Aperçu public d'une invitation, pour la page d'atterrissage du lien : qui
-- invite, dans quel jardin, à quel titre. Rien de plus, et rien sur le contenu
-- du jardin — de toute façon, qui tient le code peut le rejoindre.
create or replace function public_invite(p_code text)
returns table (garden_name text, owner_name text, role text, needs_email boolean)
language sql stable security definer set search_path = public as $$
  select g.name, coalesce(p.display_name, ''), i.role, i.email is not null
  from garden_invites i
  join gardens g on g.id = i.garden_id
  left join profiles p on p.id = g.owner_id
  where upper(i.code) = upper(trim(p_code))
    and i.revoked_at is null and i.accepted_at is null
    and (i.expires_at is null or i.expires_at > now())
    and g.deleted_at is null;
$$;
revoke all on function public_invite(text) from public;
grant execute on function public_invite(text) to anon, authenticated;

-- ---------- Conseils de la communauté ----------
-- La seule table de l'application que `garden_members` ne gouverne pas : un
-- conseil est rattaché à une espèce, pas à un jardin, et se lit depuis
-- n'importe quel compte. La lecture est ouverte à la clé anonyme — la fiche
-- d'entretien s'ouvre sans être connecté —, l'écriture demande un compte.
--
-- Une personne, un conseil par espèce (`unique (species_id, user_id)`) : on
-- revient sur ce qu'on a écrit plutôt que d'en empiler un second. Les bornes
-- de longueur sont celles du client
-- (`lib/domain/community/species_tip.dart`), tenues ici aussi : un client
-- modifié ne fait pas passer un roman.
create table if not exists species_tips (
  id uuid primary key default gen_random_uuid(),
  species_id text not null,             -- clé interne du catalogue, ex. hoya-kerrii
  species_name text not null,           -- nom scientifique tel qu'il a été saisi
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 10 and 300),
  votes int not null default 0,
  reports int not null default 0,
  hidden_at timestamptz,                -- assez signalé pour ne plus paraître aux autres
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (species_id, user_id)
);
create index if not exists idx_species_tips_species on species_tips(species_id, votes desc, created_at desc);

-- Une voix par personne et par conseil, un signalement par personne et par
-- conseil : la clé primaire suffit à le dire. Ces deux tables ne sont touchées
-- que par les fonctions plus bas — RLS activée, aucune politique, rien n'y
-- accède directement.
create table if not exists species_tip_votes (
  tip_id uuid not null references species_tips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (tip_id, user_id)
);

create table if not exists species_tip_reports (
  tip_id uuid not null references species_tips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (tip_id, user_id)
);

alter table species_tips enable row level security;
alter table species_tip_votes enable row level security;
alter table species_tip_reports enable row level security;

-- Lire : ce qui n'est pas masqué, et son propre conseil même masqué — sans
-- quoi son auteur le croirait encore en ligne. Écrire ne passe jamais par la
-- table : les fonctions s'en chargent, et elles seules.
drop policy if exists "tips read" on species_tips;
create policy "tips read" on species_tips for select using (hidden_at is null or user_id = auth.uid());

-- Combien de signalements masquent un conseil. Le client annonce le même
-- nombre (`speciesTipReportsToHide`) : les deux doivent rester d'accord.
create or replace function species_tip_reports_to_hide() returns int language sql immutable as $$ select 3 $$;

-- Un conseil tel que l'application le lit : l'auteur, le compte des voix, et
-- ce que le compte courant en a déjà fait. En jsonb pour que PostgREST rende
-- un objet — une fonction `returns table` rendrait un tableau d'une ligne.
create or replace function species_tip_row(p_id uuid) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', t.id,
    'species_id', t.species_id,
    'author_name', coalesce(p.display_name, ''),
    'body', t.body,
    'votes', t.votes,
    'created_at', t.created_at,
    'mine', coalesce(t.user_id = auth.uid(), false),
    'voted', (exists (select 1 from species_tip_votes v where v.tip_id = t.id and v.user_id = auth.uid())),
    'hidden', t.hidden_at is not null)
  from species_tips t
  left join profiles p on p.id = t.user_id
  where t.id = p_id;
$$;

-- Les conseils d'une espèce : le sien d'abord — c'est celui qu'on vient
-- reprendre —, puis les plus utiles, puis les plus récents. Le nom de la
-- fonction ne reprend pas celui de la table : deux objets homonymes se
-- lisent mal dans les journaux, et `/rpc/` seul les distinguerait.
create or replace function species_tips_for(p_species_id text)
returns table (id uuid, species_id text, author_name text, body text, votes int, created_at timestamptz,
               mine boolean, voted boolean, hidden boolean)
language sql stable security definer set search_path = public as $$
  select t.id, t.species_id, coalesce(p.display_name, ''), t.body, t.votes, t.created_at,
         coalesce(t.user_id = auth.uid(), false),
         exists (select 1 from species_tip_votes v where v.tip_id = t.id and v.user_id = auth.uid()),
         t.hidden_at is not null
  from species_tips t
  left join profiles p on p.id = t.user_id
  where t.species_id = btrim(coalesce(p_species_id, ''))
    and (t.hidden_at is null or t.user_id = auth.uid())
  order by coalesce(t.user_id = auth.uid(), false) desc, t.votes desc, t.created_at desc
  limit 50;
$$;

-- Publier, ou remplacer le conseil qu'on avait déjà écrit sur cette espèce.
-- Un conseil masqué reste masqué quand on le réécrit : les signalements ne
-- s'effacent pas d'un coup de clavier.
create or replace function publish_species_tip(p_species_id text, p_species_name text, p_body text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_body text; v_species text;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  v_species := btrim(coalesce(p_species_id, ''));
  v_body := btrim(coalesce(p_body, ''));
  if v_species = '' then raise exception 'bad_species'; end if;
  if char_length(v_body) < 10 or char_length(v_body) > 300 then raise exception 'bad_length'; end if;
  insert into species_tips (species_id, species_name, user_id, body)
  values (v_species, btrim(coalesce(p_species_name, '')), auth.uid(), v_body)
  on conflict (species_id, user_id) do update
    set body = excluded.body, species_name = excluded.species_name, updated_at = now()
  returning id into v_id;
  return species_tip_row(v_id);
end $$;

create or replace function withdraw_species_tip(p_id uuid)
returns void language sql security definer set search_path = public as $$
  delete from species_tips where id = p_id and user_id = auth.uid();
$$;

-- Donner sa voix, ou la reprendre. Le compte est recalculé plutôt
-- qu'incrémenté : deux appuis rapides ne le laissent pas de travers.
create or replace function vote_species_tip(p_id uuid, p_helpful boolean default true)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  if exists (select 1 from species_tips where id = p_id and user_id = auth.uid()) then raise exception 'own_tip'; end if;
  if coalesce(p_helpful, true) then
    insert into species_tip_votes (tip_id, user_id) values (p_id, auth.uid()) on conflict do nothing;
  else
    delete from species_tip_votes where tip_id = p_id and user_id = auth.uid();
  end if;
  update species_tips set votes = (select count(*) from species_tip_votes v where v.tip_id = p_id) where id = p_id;
  return species_tip_row(p_id);
end $$;

-- Signaler. Au seuil, le conseil cesse de paraître aux autres ; son auteur le
-- voit encore, avec la mention qui le dit. Rien n'est supprimé : la
-- vérification se fait sur la table, et `hidden_at` se remet à null à la main
-- quand le conseil était bon.
create or replace function report_species_tip(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_count int;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  insert into species_tip_reports (tip_id, user_id) values (p_id, auth.uid()) on conflict do nothing;
  select count(*) into v_count from species_tip_reports where tip_id = p_id;
  update species_tips
     set reports = v_count,
         hidden_at = case when v_count >= species_tip_reports_to_hide() then coalesce(hidden_at, now()) else hidden_at end
   where id = p_id;
end $$;

-- ---------- Modération ----------
-- Le signalement masque tout seul au troisième ; il faut ensuite quelqu'un
-- pour trancher. D'où une table de modérateurs, et non une colonne sur le
-- profil : `profiles` est écrit par son propriétaire (politique « profiles
-- write »), et un drapeau posé là se donnerait à soi-même en une requête.
-- Ici, aucune politique n'est déclarée : rien ne lit ni n'écrit la table hors
-- de l'éditeur SQL et des fonctions `security definer` ci-dessous.
--
-- Nommer un modérateur, c'est une ligne dans l'éditeur SQL du projet :
--   insert into moderators (user_id) values ('<uuid du compte>');
-- L'uuid se lit dans Authentication › Users.
create table if not exists moderators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table moderators enable row level security;

create or replace function is_moderator() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from moderators where user_id = auth.uid());
$$;

-- Ce qu'un modérateur a à regarder : les conseils signalés au moins une fois,
-- les plus signalés d'abord, masqués ou non. Pour quelqu'un d'autre, zéro
-- ligne — pas une erreur : l'application ne montre pas l'écran, et qui le
-- sollicite quand même n'en tire rien.
create or replace function reported_species_tips()
returns table (id uuid, species_id text, species_name text, author_name text, body text,
               votes int, reports int, created_at timestamptz, hidden boolean)
language sql stable security definer set search_path = public as $$
  select t.id, t.species_id, t.species_name, coalesce(p.display_name, ''), t.body,
         t.votes, t.reports, t.created_at, t.hidden_at is not null
  from species_tips t
  left join profiles p on p.id = t.user_id
  where is_moderator() and t.reports > 0
  order by t.reports desc, t.created_at desc
  limit 100;
$$;

-- Masquer, ou rétablir. Rétablir efface les signalements : sans cela le
-- conseil repasserait le seuil à la première humeur, et le même dossier
-- reviendrait indéfiniment.
create or replace function moderate_species_tip(p_id uuid, p_hidden boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_moderator() then raise exception 'not_moderator'; end if;
  if p_hidden then
    update species_tips set hidden_at = coalesce(hidden_at, now()) where id = p_id;
  else
    delete from species_tip_reports where tip_id = p_id;
    update species_tips set reports = 0, hidden_at = null where id = p_id;
  end if;
end $$;

-- Retirer pour de bon : ce qu'aucun rétablissement ne rattrape, et que
-- `withdraw_species_tip` ne permet qu'à l'auteur.
create or replace function remove_species_tip(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_moderator() then raise exception 'not_moderator'; end if;
  delete from species_tips where id = p_id;
end $$;

do $$ declare f text; begin
  foreach f in array array[
    'publish_species_tip(text,text,text)', 'withdraw_species_tip(uuid)',
    'vote_species_tip(uuid,boolean)', 'report_species_tip(uuid)',
    'is_moderator()', 'reported_species_tips()', 'moderate_species_tip(uuid,boolean)',
    'remove_species_tip(uuid)'] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Lire ne demande pas de compte : la fiche d'entretien s'ouvre sans être
-- connecté, et ce qu'elle montre là est déjà public.
revoke all on function species_tips_for(text) from public;
grant execute on function species_tips_for(text) to anon, authenticated;

-- Appelée seulement depuis les fonctions ci-dessus, qui s'exécutent sous le
-- propriétaire : personne d'autre n'a besoin d'y toucher.
revoke all on function species_tip_row(uuid) from public;

-- PostgREST sert les colonnes qu'il a en cache, pas celles de la base : après
-- un `alter table`, tant que le cache n'est pas relu, l'API répond encore
-- « Could not find the '…' column of '…' in the schema cache » (PGRST204).
-- Supabase le relit de lui-même sur les changements de schéma ; le dire ici
-- rend le rejeu de ce fichier effectif tout de suite, sans attendre.
notify pgrst, 'reload schema';

-- ============================================================
-- Le relais des clés (docs/19-relais-des-cles.md)
-- ============================================================
-- Trois clés d'éditeur — Pl@ntNet, les AI Services d'Infomaniak, OpenRouter —
-- ne sont plus dans le binaire : la fonction Edge `relay` les tient, et
-- l'application ne parle qu'à elle. Restent deux questions, et ces tables y
-- répondent : à qui le relais accepte de parler, et combien il laisse
-- consommer.
--
-- Aucune politique n'est déclarée ici, et aucun droit n'est donné à `anon` ni
-- à `authenticated` : rien de tout cela ne se lit depuis l'application.
-- Seule la fonction Edge, qui se présente avec la clé de service, y touche.

-- Un appareil dont l'attestation App Attest a tenu. `key_id` est ce que
-- `DCAppAttestService` a rendu : le condensé de la clé publique, que la
-- Secure Enclave ne peut pas fabriquer deux fois.
create table if not exists relay_devices (
  key_id text primary key,
  -- Le point de la courbe, en base64 : PostgREST rend un `bytea` sous une
  -- forme qui demande d'être défaite des deux côtés, et cette clé n'est pas
  -- un secret — c'est la partie publique.
  public_key text not null,
  -- Le compteur de signatures de l'enclave. Il ne redescend jamais ; une
  -- assertion qui ne le fait pas monter est un rejeu.
  counter bigint not null default 0,
  environment text not null,
  -- Le reçu d'Apple, gardé tel quel : il ouvre le service de risque d'Apple,
  -- que le relais n'interroge pas encore.
  receipt text,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

-- Les défis en cours. On n'y range que leur condensé : la table n'a pas
-- besoin de savoir ce qui a été envoyé, seulement de reconnaître ce qui
-- revient — et une fois.
create table if not exists relay_challenges (
  id text primary key,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);
create index if not exists relay_challenges_expiry on relay_challenges (expires_at);

-- Ce que chaque appareil a consommé, par jour et par route. C'est la seule
-- chose qui borne la facture le jour où quelqu'un contourne l'attestation.
create table if not exists relay_usage (
  device text not null,
  day date not null,
  route text not null,
  calls int not null default 0,
  primary key (device, day, route)
);
create index if not exists relay_usage_day on relay_usage (day, route);

alter table relay_devices enable row level security;
alter table relay_challenges enable row level security;
alter table relay_usage enable row level security;

do $$ declare t text; begin
  foreach t in array array['relay_devices', 'relay_challenges', 'relay_usage'] loop
    execute format('revoke all on table %I from anon, authenticated', t);
    execute format('grant all on table %I to service_role', t);
  end loop;
end $$;

-- Un défi ne vaut qu'une fois, et le prouver demande que la lecture et
-- l'effacement soient le même geste : deux requêtes laisseraient la place
-- d'un rejeu entre les deux.
create or replace function relay_claim_challenge(p_id text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_claimed boolean;
begin
  delete from relay_challenges where id = p_id and expires_at > now() returning true into v_claimed;
  return coalesce(v_claimed, false);
end $$;

-- Le compteur ne monte que s'il monte. La condition est dans le `where` pour
-- que deux assertions arrivées ensemble ne puissent pas passer toutes les
-- deux : la seconde ne trouvera plus de ligne à mettre à jour.
create or replace function relay_bump_counter(p_key_id text, p_counter bigint)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_bumped boolean;
begin
  update relay_devices set counter = p_counter, last_seen_at = now()
    where key_id = p_key_id and counter < p_counter
    returning true into v_bumped;
  return coalesce(v_bumped, false);
end $$;

-- Un appel, compté et pesé contre deux plafonds : celui de l'appareil, et
-- celui de la journée tous appareils confondus. Le second est le vrai filet —
-- il tient même si quelqu'un trouve le moyen de se faire passer pour mille
-- appareils.
--
-- Le verrou consultatif sérialise les appels d'une même route. Sans lui, deux
-- requêtes simultanées liraient le même total avant de l'écrire, et le
-- plafond se franchirait de quelques appels ; à ce volume, le verrou ne coûte
-- rien et la borne devient exacte.
create or replace function relay_consume(p_device text, p_route text, p_limit int, p_global int)
returns table(allowed boolean, device_calls int, route_calls int)
language plpgsql security definer set search_path = public as $$
declare
  v_day date := (now() at time zone 'utc')::date;
  v_device int;
  v_route int;
begin
  perform pg_advisory_xact_lock(hashtext('relay_consume:' || p_route));
  select coalesce(sum(calls), 0) into v_route from relay_usage where day = v_day and route = p_route;
  select coalesce(calls, 0) into v_device from relay_usage
    where device = p_device and day = v_day and route = p_route;

  if v_device >= p_limit or v_route >= p_global then
    return query select false, v_device, v_route;
    return;
  end if;

  insert into relay_usage (device, day, route, calls) values (p_device, v_day, p_route, 1)
    on conflict (device, day, route) do update set calls = relay_usage.calls + 1
    returning calls into v_device;
  return query select true, v_device, v_route + 1;
end $$;

-- Ce qui n'a plus à être gardé. Les défis expirent en minutes ; l'usage, lui,
-- sert à lire une tendance et à retrouver un abus, trois mois suffisent. À
-- appeler depuis un cron Supabase, ou à la main.
create or replace function relay_purge()
returns void language sql security definer set search_path = public as $$
  delete from relay_challenges where expires_at < now() - interval '1 hour';
  delete from relay_usage where day < (now() at time zone 'utc')::date - 90;
$$;

do $$ declare f text; begin
  foreach f in array array[
    'relay_claim_challenge(text)', 'relay_bump_counter(text,bigint)',
    'relay_consume(text,text,int,int)', 'relay_purge()'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
    execute format('grant execute on function %s to service_role', f);
  end loop;
end $$;

notify pgrst, 'reload schema';

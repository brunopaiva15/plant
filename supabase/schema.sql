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
  strategy text not null check (strategy in ('fixed','seasonal','manual')),
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
  notes text,
  photo_path text,
  thumb_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

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
create or replace function is_member(g uuid) returns boolean language sql stable security definer as $$
  select exists(select 1 from garden_members where garden_id = g and user_id = auth.uid());
$$;
create or replace function can_edit(g uuid) returns boolean language sql stable security definer as $$
  select exists(select 1 from garden_members where garden_id = g and user_id = auth.uid() and role in ('owner','member'));
$$;
create or replace function plant_garden(p uuid) returns uuid language sql stable security definer as $$
  select garden_id from plants where id = p;
$$;

alter table profiles enable row level security;
create policy "own profile" on profiles for all using (id = auth.uid()) with check (id = auth.uid());

alter table gardens enable row level security;
create policy "gardens read" on gardens for select using (is_member(id) or owner_id = auth.uid());
create policy "gardens insert" on gardens for insert with check (owner_id = auth.uid());
create policy "gardens update" on gardens for update using (owner_id = auth.uid());

alter table garden_members enable row level security;
create policy "members read" on garden_members for select using (is_member(garden_id));
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
create policy "types read" on action_types for select using (garden_id is null or is_member(garden_id));
create policy "types write" on action_types for all using (garden_id is not null and can_edit(garden_id)) with check (garden_id is not null and can_edit(garden_id));

-- Storage : bucket privé, chemin plant-photos/{garden_id}/... ; accès par appartenance au jardin.
insert into storage.buckets (id, name, public) values ('plant-photos', 'plant-photos', false) on conflict do nothing;
create policy "photos read" on storage.objects for select using (bucket_id = 'plant-photos' and is_member((storage.foldername(name))[1]::uuid));
create policy "photos write" on storage.objects for insert with check (bucket_id = 'plant-photos' and can_edit((storage.foldername(name))[1]::uuid));
create policy "photos delete" on storage.objects for delete using (bucket_id = 'plant-photos' and can_edit((storage.foldername(name))[1]::uuid));

-- ---------- Profils & invitations ----------
-- Un profil par utilisateur, créé à l'inscription (nom d'affichage pour « Arrosée par Laura »).
create or replace function handle_new_user() returns trigger language plpgsql security definer as $$
begin
  insert into profiles(id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists trg_new_user on auth.users;
create trigger trg_new_user after insert on auth.users for each row execute function handle_new_user();

-- Les membres d'un même jardin peuvent lire les profils des autres membres.
drop policy if exists "own profile" on profiles;
create policy "profiles read" on profiles for select using (
  id = auth.uid() or exists (
    select 1 from garden_members a join garden_members b on a.garden_id = b.garden_id
    where a.user_id = auth.uid() and b.user_id = profiles.id)
);
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
create or replace function new_invite_code() returns text language plpgsql as $$
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
returns garden_invites language plpgsql security definer set search_path = public as $$
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

do $$ declare f text; begin
  foreach f in array array[
    'create_invite(uuid,text,text,int)', 'preview_invite(text)', 'accept_invite(text)', 'revoke_invite(uuid)',
    'my_gardens()', 'set_member_role(uuid,uuid,text)', 'remove_member(uuid,uuid)', 'leave_garden(uuid)'] loop
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

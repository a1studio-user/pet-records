-- 宠刻 Supabase 数据模型
-- 设计原则：全部生活记录均由用户主动输入；不包含任何医疗建议或判断字段。

create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  onboarding_completed boolean not null default false,
  migration_completed_at timestamptz,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.pets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 40),
  species text not null check (species in ('cat', 'dog')),
  gender text not null default 'unknown' check (gender in ('male', 'female', 'unknown')),
  neutered_status text not null default 'unknown' check (neutered_status in ('neutered', 'not_neutered', 'unknown')),
  breed_name text not null,
  birthday date not null check (birthday <= current_date),
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

create table public.deworm_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pet_id uuid not null,
  medicine_name text not null,
  treatment_scope text not null check (treatment_scope in ('internal', 'external', 'both')),
  purchase_price numeric(10,2) check (purchase_price >= 0),
  used_at date not null,
  photo_path text,
  reminder_at timestamptz,
  frequency_months integer check (frequency_months between 1 and 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (pet_id, user_id) references public.pets(id, user_id) on delete cascade
);

create table public.vaccine_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pet_id uuid not null,
  vaccine_name text not null,
  injected_at timestamptz not null,
  dose_number integer not null check (dose_number > 0),
  photo_path text,
  reminder_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (pet_id, user_id) references public.pets(id, user_id) on delete cascade
);

create table public.food_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pet_id uuid not null,
  product_name text not null,
  package_weight_kg numeric(7,3) not null check (package_weight_kg > 0),
  purchase_price numeric(10,2) not null check (purchase_price >= 0),
  purchased_on date not null,
  started_on date,
  finished_on date,
  photo_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (finished_on is null or started_on is not null),
  check (finished_on is null or finished_on >= started_on),
  foreign key (pet_id, user_id) references public.pets(id, user_id) on delete cascade
);

create table public.taste_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pet_id uuid not null,
  brand_name text not null,
  product_name text not null,
  category_name text not null,
  rating numeric(2,1) not null check (rating between 0.5 and 5 and rating * 2 = trunc(rating * 2)),
  tasted_on date not null default current_date,
  photo_path text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (pet_id, user_id) references public.pets(id, user_id) on delete cascade
);

create index pets_user_id_idx on public.pets(user_id);
create index deworm_records_user_id_idx on public.deworm_records(user_id);
create index deworm_records_pet_user_idx on public.deworm_records(pet_id, user_id);
create index deworm_records_pet_date_idx on public.deworm_records(pet_id, used_at desc);
create index vaccine_records_user_id_idx on public.vaccine_records(user_id);
create index vaccine_records_pet_user_idx on public.vaccine_records(pet_id, user_id);
create index vaccine_records_pet_date_idx on public.vaccine_records(pet_id, injected_at desc);
create index food_records_user_id_idx on public.food_records(user_id);
create index food_records_pet_user_idx on public.food_records(pet_id, user_id);
create index food_records_pet_date_idx on public.food_records(pet_id, purchased_on desc);
create index taste_records_user_id_idx on public.taste_records(user_id);
create index taste_records_pet_user_idx on public.taste_records(pet_id, user_id);
create index taste_records_pet_rating_idx on public.taste_records(pet_id, rating desc);

alter table public.profiles enable row level security;
alter table public.pets enable row level security;
alter table public.deworm_records enable row level security;
alter table public.vaccine_records enable row level security;
alter table public.food_records enable row level security;
alter table public.taste_records enable row level security;

grant usage on schema public to authenticated;
revoke all on table public.profiles, public.pets, public.deworm_records,
  public.vaccine_records, public.food_records, public.taste_records from anon, authenticated;
grant select, insert, update, delete on table public.profiles, public.pets,
  public.deworm_records, public.vaccine_records, public.food_records,
  public.taste_records to authenticated;

create policy "profiles_select_own" on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy "profiles_insert_own" on public.profiles for insert to authenticated
  with check ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "profiles_delete_own" on public.profiles for delete to authenticated
  using ((select auth.uid()) = id);

create policy "pets_select_own" on public.pets for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "pets_insert_own" on public.pets for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "pets_update_own" on public.pets for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "pets_delete_own" on public.pets for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "deworm_select_own" on public.deworm_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "deworm_insert_own" on public.deworm_records for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "deworm_update_own" on public.deworm_records for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "deworm_delete_own" on public.deworm_records for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "vaccine_select_own" on public.vaccine_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "vaccine_insert_own" on public.vaccine_records for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "vaccine_update_own" on public.vaccine_records for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "vaccine_delete_own" on public.vaccine_records for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "food_select_own" on public.food_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "food_insert_own" on public.food_records for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "food_update_own" on public.food_records for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "food_delete_own" on public.food_records for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "taste_select_own" on public.taste_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "taste_insert_own" on public.taste_records for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "taste_update_own" on public.taste_records for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "taste_delete_own" on public.taste_records for delete to authenticated
  using ((select auth.uid()) = user_id);

-- 路径固定为 <auth.uid()>/<pet_id>/<uuid>.<ext>，严禁在客户端使用 service_role key。
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('pet-media', 'pet-media', false, 10485760, array['image/jpeg', 'image/png', 'image/heic', 'image/heif'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "pet_media_select_own" on storage.objects for select to authenticated
  using (bucket_id = 'pet-media' and owner_id = (select auth.uid()::text));
create policy "pet_media_insert_own" on storage.objects for insert to authenticated
  with check (bucket_id = 'pet-media' and (storage.foldername(name))[1] = (select auth.uid()::text));
create policy "pet_media_update_own" on storage.objects for update to authenticated
  using (bucket_id = 'pet-media' and owner_id = (select auth.uid()::text))
  with check (bucket_id = 'pet-media' and (storage.foldername(name))[1] = (select auth.uid()::text));
create policy "pet_media_delete_own" on storage.objects for delete to authenticated
  using (bucket_id = 'pet-media' and owner_id = (select auth.uid()::text));

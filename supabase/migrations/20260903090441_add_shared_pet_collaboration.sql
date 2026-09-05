-- Shared-pet collaboration for Pawprint Diary.
-- `pets.user_id` remains the immutable owner id. Record `user_id` values also
-- remain the pet owner's id so existing rows and composite foreign keys stay valid.

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table public.pet_members (
  pet_id uuid not null references public.pets(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'caregiver')),
  joined_at timestamptz not null default now(),
  primary key (pet_id, user_id)
);

create index pet_members_user_id_pet_id_idx
  on public.pet_members(user_id, pet_id);

create table public.pet_share_codes (
  pet_id uuid primary key references public.pets(id) on delete cascade,
  share_code text not null unique check (share_code ~ '^[0-9]{8}$'),
  updated_at timestamptz not null default now()
);

alter table public.pet_members enable row level security;
alter table public.pet_share_codes enable row level security;

revoke all on table public.pet_members, public.pet_share_codes from anon, authenticated;
grant select on table public.pet_members, public.pet_share_codes to authenticated;

create or replace function private.current_user_pet_ids()
returns setof uuid
language sql
security definer
set search_path = ''
stable
as $$
  select membership.pet_id
  from public.pet_members as membership
  where membership.user_id = (select auth.uid());
$$;

create or replace function private.is_pet_owner(p_pet_id uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.pets as pet
    where pet.id = p_pet_id
      and pet.user_id = (select auth.uid())
  );
$$;

create or replace function private.pet_owner_id(p_pet_id uuid)
returns uuid
language sql
security definer
set search_path = ''
stable
as $$
  select pet.user_id
  from public.pets as pet
  where pet.id = p_pet_id;
$$;

create or replace function private.generate_unique_pet_share_code()
returns text
language plpgsql
security definer
set search_path = ''
volatile
as $$
declare
  candidate text;
begin
  -- Serializing this very small operation makes the read-before-insert check
  -- race-free. The UNIQUE constraint is a second, absolute safeguard.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('pawprint_diary_pet_share_code', 0)
  );
  loop
    candidate := pg_catalog.lpad(
      pg_catalog.floor(pg_catalog.random() * 100000000)::bigint::text,
      8,
      '0'
    );
    exit when not exists (
      select 1
      from public.pet_share_codes as code
      where code.share_code = candidate
    );
  end loop;
  return candidate;
end;
$$;

create or replace function private.bootstrap_pet_sharing()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.pet_members (pet_id, user_id, role)
  values (new.id, new.user_id, 'owner')
  on conflict (pet_id, user_id) do update set role = 'owner';

  insert into public.pet_share_codes (pet_id, share_code)
  values (new.id, private.generate_unique_pet_share_code())
  on conflict (pet_id) do nothing;
  return new;
end;
$$;

drop trigger if exists pets_bootstrap_sharing on public.pets;
create trigger pets_bootstrap_sharing
after insert on public.pets
for each row execute function private.bootstrap_pet_sharing();

-- Preserve existing pets by making their original creator the owner.
insert into public.pet_members (pet_id, user_id, role)
select pet.id, pet.user_id, 'owner'
from public.pets as pet
on conflict (pet_id, user_id) do update set role = 'owner';

do $$
declare
  pet_row record;
begin
  for pet_row in
    select pet.id
    from public.pets as pet
    where not exists (
      select 1 from public.pet_share_codes as code where code.pet_id = pet.id
    )
  loop
    insert into public.pet_share_codes (pet_id, share_code)
    values (pet_row.id, private.generate_unique_pet_share_code());
  end loop;
end;
$$;

drop policy if exists "pets_select_own" on public.pets;
drop policy if exists "pets_insert_own" on public.pets;
drop policy if exists "pets_update_own" on public.pets;
drop policy if exists "pets_delete_own" on public.pets;

create policy "pets_select_for_members" on public.pets for select to authenticated
  using (id in (select private.current_user_pet_ids()));
create policy "pets_insert_by_owner" on public.pets for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "pets_update_by_owner" on public.pets for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "pets_delete_by_owner" on public.pets for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "pet_members_select_owner_or_self" on public.pet_members for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_pet_owner(pet_id))
  );

create policy "pet_share_codes_select_owner" on public.pet_share_codes for select to authenticated
  using ((select private.is_pet_owner(pet_id)));

drop policy if exists "deworm_select_own" on public.deworm_records;
drop policy if exists "deworm_insert_own" on public.deworm_records;
drop policy if exists "deworm_update_own" on public.deworm_records;
drop policy if exists "deworm_delete_own" on public.deworm_records;
drop policy if exists "vaccine_select_own" on public.vaccine_records;
drop policy if exists "vaccine_insert_own" on public.vaccine_records;
drop policy if exists "vaccine_update_own" on public.vaccine_records;
drop policy if exists "vaccine_delete_own" on public.vaccine_records;
drop policy if exists "food_select_own" on public.food_records;
drop policy if exists "food_insert_own" on public.food_records;
drop policy if exists "food_update_own" on public.food_records;
drop policy if exists "food_delete_own" on public.food_records;
drop policy if exists "taste_select_own" on public.taste_records;
drop policy if exists "taste_insert_own" on public.taste_records;
drop policy if exists "taste_update_own" on public.taste_records;
drop policy if exists "taste_delete_own" on public.taste_records;

create policy "deworm_select_for_members" on public.deworm_records for select to authenticated
  using (pet_id in (select private.current_user_pet_ids()));
create policy "deworm_insert_for_members" on public.deworm_records for insert to authenticated
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "deworm_update_for_members" on public.deworm_records for update to authenticated
  using (pet_id in (select private.current_user_pet_ids()))
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "deworm_delete_for_members" on public.deworm_records for delete to authenticated
  using (pet_id in (select private.current_user_pet_ids()));

create policy "vaccine_select_for_members" on public.vaccine_records for select to authenticated
  using (pet_id in (select private.current_user_pet_ids()));
create policy "vaccine_insert_for_members" on public.vaccine_records for insert to authenticated
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "vaccine_update_for_members" on public.vaccine_records for update to authenticated
  using (pet_id in (select private.current_user_pet_ids()))
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "vaccine_delete_for_members" on public.vaccine_records for delete to authenticated
  using (pet_id in (select private.current_user_pet_ids()));

create policy "food_select_for_members" on public.food_records for select to authenticated
  using (pet_id in (select private.current_user_pet_ids()));
create policy "food_insert_for_members" on public.food_records for insert to authenticated
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "food_update_for_members" on public.food_records for update to authenticated
  using (pet_id in (select private.current_user_pet_ids()))
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "food_delete_for_members" on public.food_records for delete to authenticated
  using (pet_id in (select private.current_user_pet_ids()));

create policy "taste_select_for_members" on public.taste_records for select to authenticated
  using (pet_id in (select private.current_user_pet_ids()));
create policy "taste_insert_for_members" on public.taste_records for insert to authenticated
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "taste_update_for_members" on public.taste_records for update to authenticated
  using (pet_id in (select private.current_user_pet_ids()))
  with check (
    pet_id in (select private.current_user_pet_ids())
    and user_id = (select private.pet_owner_id(pet_id))
  );
create policy "taste_delete_for_members" on public.taste_records for delete to authenticated
  using (pet_id in (select private.current_user_pet_ids()));

create or replace function public.join_pet_by_share_code(p_share_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  target_pet_id uuid;
  owner_id uuid;
begin
  if caller is null then
    raise exception using errcode = '28000', message = '请先登录。';
  end if;
  if p_share_code is null or p_share_code !~ '^[0-9]{8}$' then
    raise exception using errcode = '22023', message = '请输入八位数字分享码。';
  end if;

  select code.pet_id into target_pet_id
  from public.pet_share_codes as code
  where code.share_code = p_share_code;
  if target_pet_id is null then
    raise exception using errcode = 'P0001', message = '分享码不存在或已失效。';
  end if;

  select pet.user_id into owner_id
  from public.pets as pet
  where pet.id = target_pet_id;

  insert into public.pet_members (pet_id, user_id, role)
  values (target_pet_id, caller, case when caller = owner_id then 'owner' else 'caregiver' end)
  on conflict (pet_id, user_id) do nothing;
  return target_pet_id;
end;
$$;

create or replace function public.reset_pet_share_code(p_pet_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  next_code text;
begin
  if (select auth.uid()) is null or not private.is_pet_owner(p_pet_id) then
    raise exception using errcode = '42501', message = '只有主饲养员可以重置分享码。';
  end if;
  next_code := private.generate_unique_pet_share_code();
  update public.pet_share_codes
  set share_code = next_code, updated_at = now()
  where pet_id = p_pet_id;
  return next_code;
end;
$$;

create or replace function public.list_pet_members(p_pet_id uuid)
returns table (
  user_id uuid,
  display_name text,
  role text,
  joined_at timestamptz
)
language plpgsql
security definer
set search_path = ''
stable
as $$
begin
  if (select auth.uid()) is null or not private.is_pet_owner(p_pet_id) then
    raise exception using errcode = '42501', message = '只有主饲养员可以查看共同饲养员。';
  end if;
  return query
  select member.user_id,
         coalesce(profile.display_name, '共同饲养员 ' || right(member.user_id::text, 4)),
         member.role,
         member.joined_at
  from public.pet_members as member
  left join public.profiles as profile on profile.id = member.user_id
  where member.pet_id = p_pet_id
  order by (member.role = 'owner') desc, member.joined_at asc;
end;
$$;

create or replace function public.remove_pet_member(p_pet_id uuid, p_member_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null or not private.is_pet_owner(p_pet_id) then
    raise exception using errcode = '42501', message = '只有主饲养员可以移除成员。';
  end if;
  if p_member_user_id = (select auth.uid()) then
    raise exception using errcode = '22023', message = '主饲养员不能移除自己。';
  end if;
  delete from public.pet_members
  where pet_id = p_pet_id
    and user_id = p_member_user_id
    and role = 'caregiver';
end;
$$;

create or replace function public.leave_shared_pet(p_pet_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '28000', message = '请先登录。';
  end if;
  if private.is_pet_owner(p_pet_id) then
    raise exception using errcode = '22023', message = '主饲养员不能退出自己的宠物共享。';
  end if;
  delete from public.pet_members
  where pet_id = p_pet_id
    and user_id = (select auth.uid())
    and role = 'caregiver';
end;
$$;

revoke all on function public.join_pet_by_share_code(text) from public, anon;
revoke all on function public.reset_pet_share_code(uuid) from public, anon;
revoke all on function public.list_pet_members(uuid) from public, anon;
revoke all on function public.remove_pet_member(uuid, uuid) from public, anon;
revoke all on function public.leave_shared_pet(uuid) from public, anon;
grant execute on function public.join_pet_by_share_code(text) to authenticated;
grant execute on function public.reset_pet_share_code(uuid) to authenticated;
grant execute on function public.list_pet_members(uuid) to authenticated;
grant execute on function public.remove_pet_member(uuid, uuid) to authenticated;
grant execute on function public.leave_shared_pet(uuid) to authenticated;

revoke all on function private.current_user_pet_ids() from public, anon;
revoke all on function private.is_pet_owner(uuid) from public, anon;
revoke all on function private.pet_owner_id(uuid) from public, anon;
revoke all on function private.generate_unique_pet_share_code() from public, anon, authenticated;
revoke all on function private.bootstrap_pet_sharing() from public, anon, authenticated;
grant execute on function private.current_user_pet_ids() to authenticated;
grant execute on function private.is_pet_owner(uuid) to authenticated;
grant execute on function private.pet_owner_id(uuid) to authenticated;

drop policy if exists "pet_media_select_own" on storage.objects;
drop policy if exists "pet_media_insert_own" on storage.objects;
drop policy if exists "pet_media_update_own" on storage.objects;
drop policy if exists "pet_media_delete_own" on storage.objects;

create policy "pet_media_select_for_members" on storage.objects for select to authenticated
  using (
    bucket_id = 'pet-media'
    and exists (
      select 1
      from private.current_user_pet_ids() as accessible(pet_id)
      where accessible.pet_id::text = (storage.foldername(name))[2]
    )
  );
create policy "pet_media_insert_for_members" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'pet-media'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
    and exists (
      select 1
      from private.current_user_pet_ids() as accessible(pet_id)
      where accessible.pet_id::text = (storage.foldername(name))[2]
    )
  );
create policy "pet_media_update_own_uploads" on storage.objects for update to authenticated
  using (bucket_id = 'pet-media' and owner_id = (select auth.uid()::text))
  with check (
    bucket_id = 'pet-media'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
    and exists (
      select 1
      from private.current_user_pet_ids() as accessible(pet_id)
      where accessible.pet_id::text = (storage.foldername(name))[2]
    )
  );
create policy "pet_media_delete_own_uploads" on storage.objects for delete to authenticated
  using (bucket_id = 'pet-media' and owner_id = (select auth.uid()::text));

comment on table public.pet_members is
  'Users allowed to record data for a pet. Only the owner may edit the pet profile or manage members.';
comment on table public.pet_share_codes is
  'Owner-only eight digit sharing codes; caregivers cannot select this table.';

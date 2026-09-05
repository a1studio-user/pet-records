-- Reliable per-record cloud synchronization and share-code recovery.
-- Record data remains user-entered only; no medical advice fields are added.

create table if not exists public.record_tombstones (
  record_kind text not null check (record_kind in ('deworm', 'vaccine', 'food', 'taste')),
  record_id uuid not null,
  pet_id uuid not null,
  user_id uuid not null,
  deleted_at timestamptz not null,
  created_at timestamptz not null default now(),
  primary key (record_kind, record_id),
  foreign key (pet_id, user_id)
    references public.pets(id, user_id) on delete cascade
);

create index if not exists record_tombstones_pet_deleted_idx
  on public.record_tombstones(pet_id, deleted_at desc);
create index if not exists record_tombstones_pet_user_idx
  on public.record_tombstones(pet_id, user_id);

alter table public.record_tombstones enable row level security;
revoke all on table public.record_tombstones from public, anon, authenticated;
grant select on table public.record_tombstones to authenticated;

drop policy if exists "record_tombstones_select_for_members" on public.record_tombstones;
create policy "record_tombstones_select_for_members"
on public.record_tombstones for select to authenticated
using (pet_id in (select private.current_user_pet_ids()));

-- Explicit Data API grants. RLS remains the authorization boundary.
grant select, insert, update, delete on table
  public.profiles,
  public.pets,
  public.deworm_records,
  public.vaccine_records,
  public.food_records,
  public.taste_records
to authenticated;
grant select on table public.pet_members, public.pet_share_codes to authenticated;

create or replace function private.reject_stale_pet_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.updated_at <= old.updated_at then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists pets_reject_stale_update on public.pets;
create trigger pets_reject_stale_update
before update on public.pets
for each row execute function private.reject_stale_pet_update();

create or replace function private.reject_stale_record_write()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  latest_deletion timestamptz;
begin
  if tg_op = 'UPDATE' and new.updated_at <= old.updated_at then
    return old;
  end if;

  select tombstone.deleted_at into latest_deletion
  from public.record_tombstones as tombstone
  where tombstone.record_kind = tg_argv[0]
    and tombstone.record_id = new.id;

  if latest_deletion is not null and new.updated_at <= latest_deletion then
    return null;
  end if;
  return new;
end;
$$;

create or replace function private.clear_superseded_record_tombstone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.record_tombstones
  where record_kind = tg_argv[0]
    and record_id = new.id
    and deleted_at < new.updated_at;
  return new;
end;
$$;

create or replace function private.capture_record_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.record_tombstones (
    record_kind, record_id, pet_id, user_id, deleted_at
  ) values (
    tg_argv[0], old.id, old.pet_id, old.user_id, now()
  )
  on conflict (record_kind, record_id) do update
  set pet_id = excluded.pet_id,
      user_id = excluded.user_id,
      deleted_at = greatest(public.record_tombstones.deleted_at, excluded.deleted_at);
  return old;
end;
$$;

do $$
declare
  item record;
begin
  for item in
    select * from (values
      ('deworm_records', 'deworm'),
      ('vaccine_records', 'vaccine'),
      ('food_records', 'food'),
      ('taste_records', 'taste')
    ) as entries(table_name, record_kind)
  loop
    execute format('drop trigger if exists %I on public.%I',
      item.table_name || '_reject_stale_write', item.table_name);
    execute format('create trigger %I before insert or update on public.%I '
      || 'for each row execute function private.reject_stale_record_write(%L)',
      item.table_name || '_reject_stale_write', item.table_name, item.record_kind);

    execute format('drop trigger if exists %I on public.%I',
      item.table_name || '_clear_old_tombstone', item.table_name);
    execute format('create trigger %I after insert or update on public.%I '
      || 'for each row execute function private.clear_superseded_record_tombstone(%L)',
      item.table_name || '_clear_old_tombstone', item.table_name, item.record_kind);

    execute format('drop trigger if exists %I on public.%I',
      item.table_name || '_capture_delete', item.table_name);
    execute format('create trigger %I after delete on public.%I '
      || 'for each row execute function private.capture_record_delete(%L)',
      item.table_name || '_capture_delete', item.table_name, item.record_kind);
  end loop;
end;
$$;

create or replace function public.ensure_pet_share_code(p_pet_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_code text;
begin
  if (select auth.uid()) is null or not private.is_pet_owner(p_pet_id) then
    raise exception using errcode = '42501', message = '只有主饲养员可以查看分享码。';
  end if;

  insert into public.pet_share_codes (pet_id, share_code)
  values (p_pet_id, private.generate_unique_pet_share_code())
  on conflict (pet_id) do update set pet_id = excluded.pet_id
  returning share_code into result_code;
  return result_code;
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
  insert into public.pet_share_codes (pet_id, share_code, updated_at)
  values (p_pet_id, next_code, now())
  on conflict (pet_id) do update
  set share_code = excluded.share_code, updated_at = excluded.updated_at;
  return next_code;
end;
$$;

create or replace function public.delete_pet_record(
  p_record_kind text,
  p_record_id uuid,
  p_pet_id uuid,
  p_deleted_at timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  owner_id uuid;
  record_updated_at timestamptz;
begin
  if caller is null then
    raise exception using errcode = '28000', message = '请先登录。';
  end if;
  if p_record_kind not in ('deworm', 'vaccine', 'food', 'taste')
     or p_record_id is null or p_pet_id is null or p_deleted_at is null then
    raise exception using errcode = '22023', message = '删除参数无效。';
  end if;
  if not exists (
    select 1 from public.pet_members
    where pet_id = p_pet_id and user_id = caller
  ) then
    raise exception using errcode = '42501', message = '你没有操作该宠物记录的权限。';
  end if;

  owner_id := private.pet_owner_id(p_pet_id);
  if owner_id is null then
    raise exception using errcode = 'P0002', message = '宠物不存在。';
  end if;

  case p_record_kind
    when 'deworm' then
      select updated_at into record_updated_at from public.deworm_records
      where id = p_record_id and pet_id = p_pet_id for update;
    when 'vaccine' then
      select updated_at into record_updated_at from public.vaccine_records
      where id = p_record_id and pet_id = p_pet_id for update;
    when 'food' then
      select updated_at into record_updated_at from public.food_records
      where id = p_record_id and pet_id = p_pet_id for update;
    when 'taste' then
      select updated_at into record_updated_at from public.taste_records
      where id = p_record_id and pet_id = p_pet_id for update;
  end case;

  if record_updated_at is not null and record_updated_at > p_deleted_at then
    return false;
  end if;

  insert into public.record_tombstones (
    record_kind, record_id, pet_id, user_id, deleted_at
  ) values (
    p_record_kind, p_record_id, p_pet_id, owner_id, p_deleted_at
  )
  on conflict (record_kind, record_id) do update
  set pet_id = excluded.pet_id,
      user_id = excluded.user_id,
      deleted_at = greatest(public.record_tombstones.deleted_at, excluded.deleted_at);

  case p_record_kind
    when 'deworm' then
      delete from public.deworm_records where id = p_record_id and pet_id = p_pet_id;
    when 'vaccine' then
      delete from public.vaccine_records where id = p_record_id and pet_id = p_pet_id;
    when 'food' then
      delete from public.food_records where id = p_record_id and pet_id = p_pet_id;
    when 'taste' then
      delete from public.taste_records where id = p_record_id and pet_id = p_pet_id;
  end case;
  return true;
end;
$$;

revoke all on function public.ensure_pet_share_code(uuid) from public, anon;
revoke all on function public.delete_pet_record(text, uuid, uuid, timestamptz) from public, anon;
grant execute on function public.ensure_pet_share_code(uuid) to authenticated;
grant execute on function public.delete_pet_record(text, uuid, uuid, timestamptz) to authenticated;

revoke all on function private.reject_stale_pet_update() from public, anon, authenticated;
revoke all on function private.reject_stale_record_write() from public, anon, authenticated;
revoke all on function private.clear_superseded_record_tombstone() from public, anon, authenticated;
revoke all on function private.capture_record_delete() from public, anon, authenticated;

comment on table public.record_tombstones is
  'Deletion markers used to keep offline and shared clients from restoring deleted pet records.';

-- Add user-entered bath records to the same shared, offline-safe record model.

create table if not exists public.bath_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pet_id uuid not null,
  bathed_at timestamptz not null,
  price numeric(10,2) check (price >= 0),
  notes text check (notes is null or char_length(notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (pet_id, user_id)
    references public.pets(id, user_id) on delete cascade
);

create index if not exists bath_records_user_id_idx
  on public.bath_records(user_id);
create index if not exists bath_records_pet_user_idx
  on public.bath_records(pet_id, user_id);
create index if not exists bath_records_pet_date_idx
  on public.bath_records(pet_id, bathed_at desc);

alter table public.bath_records enable row level security;
revoke all on table public.bath_records from public, anon, authenticated;
grant select, insert, update, delete on table public.bath_records to authenticated;

drop policy if exists "bath_select_for_members" on public.bath_records;
create policy "bath_select_for_members"
on public.bath_records for select to authenticated
using (pet_id in (select private.current_user_pet_ids()));

drop policy if exists "bath_insert_for_members" on public.bath_records;
create policy "bath_insert_for_members"
on public.bath_records for insert to authenticated
with check (
  pet_id in (select private.current_user_pet_ids())
  and user_id = (select private.pet_owner_id(pet_id))
);

drop policy if exists "bath_update_for_members" on public.bath_records;
create policy "bath_update_for_members"
on public.bath_records for update to authenticated
using (pet_id in (select private.current_user_pet_ids()))
with check (
  pet_id in (select private.current_user_pet_ids())
  and user_id = (select private.pet_owner_id(pet_id))
);

drop policy if exists "bath_delete_for_members" on public.bath_records;
create policy "bath_delete_for_members"
on public.bath_records for delete to authenticated
using (pet_id in (select private.current_user_pet_ids()));

alter table public.record_tombstones
  drop constraint if exists record_tombstones_record_kind_check;
alter table public.record_tombstones
  add constraint record_tombstones_record_kind_check
  check (record_kind in ('deworm', 'vaccine', 'food', 'taste', 'bath'));

drop trigger if exists bath_records_reject_stale_write on public.bath_records;
create trigger bath_records_reject_stale_write
before insert or update on public.bath_records
for each row execute function private.reject_stale_record_write('bath');

drop trigger if exists bath_records_clear_old_tombstone on public.bath_records;
create trigger bath_records_clear_old_tombstone
after insert or update on public.bath_records
for each row execute function private.clear_superseded_record_tombstone('bath');

drop trigger if exists bath_records_capture_delete on public.bath_records;
create trigger bath_records_capture_delete
after delete on public.bath_records
for each row execute function private.capture_record_delete('bath');

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
  if p_record_kind not in ('deworm', 'vaccine', 'food', 'taste', 'bath')
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
    when 'bath' then
      select updated_at into record_updated_at from public.bath_records
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
    when 'bath' then
      delete from public.bath_records where id = p_record_id and pet_id = p_pet_id;
  end case;
  return true;
end;
$$;

revoke all on function public.delete_pet_record(text, uuid, uuid, timestamptz)
  from public, anon;
grant execute on function public.delete_pet_record(text, uuid, uuid, timestamptz)
  to authenticated;

comment on table public.bath_records is
  'User-entered pet bath time, optional price, and optional notes.';

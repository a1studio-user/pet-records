-- A record deleted as part of deleting its parent pet must not create a
-- tombstone: the pet row is already gone and its ON DELETE CASCADE cleanup
-- should be allowed to finish normally.
create or replace function private.capture_record_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.pets
    where id = old.pet_id
      and user_id = old.user_id
  ) then
    return old;
  end if;

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

revoke all on function private.capture_record_delete() from public, anon, authenticated;

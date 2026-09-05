-- Production-safe integration test: all temporary users and rows are removed.

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) values
  ('d1000000-0000-4000-8000-000000000001','authenticated','authenticated','qa-bath-owner@invalid.example','',now(),'{"provider":"apple","providers":["apple"]}'::jsonb,'{}'::jsonb,now(),now(),false,false),
  ('d1000000-0000-4000-8000-000000000002','authenticated','authenticated','qa-bath-caregiver@invalid.example','',now(),'{"provider":"apple","providers":["apple"]}'::jsonb,'{}'::jsonb,now(),now(),false,false);

insert into public.profiles (id, display_name, onboarding_completed)
values
  ('d1000000-0000-4000-8000-000000000001','QA Bath Owner',true),
  ('d1000000-0000-4000-8000-000000000002','QA Bath Caregiver',true);

select set_config('request.jwt.claim.sub','d1000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"d1000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
set local role authenticated;

insert into public.pets (
  id,user_id,name,species,gender,neutered_status,breed_name,birthday,updated_at
) values (
  'd2000000-0000-4000-8000-000000000001',
  'd1000000-0000-4000-8000-000000000001',
  'QA洗澡共享宠物','dog','female','neutered','其它','2024-01-01','2026-09-05T00:00:00Z'
);

select set_config(
  'qa.bath_share_code',
  (select share_code from public.pet_share_codes where pet_id='d2000000-0000-4000-8000-000000000001'),
  true
);

reset role;
select set_config('request.jwt.claim.sub','d1000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"d1000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
set local role authenticated;

select public.join_pet_by_share_code(current_setting('qa.bath_share_code'));

insert into public.bath_records (
  id,user_id,pet_id,bathed_at,price,notes,updated_at
) values (
  'd3000000-0000-4000-8000-000000000001',
  'd1000000-0000-4000-8000-000000000001',
  'd2000000-0000-4000-8000-000000000001',
  '2026-09-05T01:00:00Z',88.5,'共同饲养员新增','2026-09-05T01:00:00Z'
);

update public.bath_records
set price=99, notes='共同饲养员编辑', updated_at='2026-09-05T01:01:00Z'
where id='d3000000-0000-4000-8000-000000000001';

do $$
begin
  if (select count(*) from public.bath_records where id='d3000000-0000-4000-8000-000000000001') <> 1 then
    raise exception 'caregiver cannot create or read bath record';
  end if;
  if (select notes from public.bath_records where id='d3000000-0000-4000-8000-000000000001') <> '共同饲养员编辑' then
    raise exception 'caregiver cannot edit bath record';
  end if;
  if not public.delete_pet_record(
    'bath',
    'd3000000-0000-4000-8000-000000000001',
    'd2000000-0000-4000-8000-000000000001',
    '2030-09-05T01:02:00Z'
  ) then
    raise exception 'bath delete rejected';
  end if;
  if exists (select 1 from public.bath_records where id='d3000000-0000-4000-8000-000000000001') then
    raise exception 'bath record was not deleted';
  end if;
  if not exists (
    select 1 from public.record_tombstones
    where record_kind='bath' and record_id='d3000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'bath tombstone was not created';
  end if;
end $$;

insert into public.bath_records (
  id,user_id,pet_id,bathed_at,price,notes,updated_at
) values (
  'd3000000-0000-4000-8000-000000000001',
  'd1000000-0000-4000-8000-000000000001',
  'd2000000-0000-4000-8000-000000000001',
  '2026-09-05T01:00:00Z',1,'过期离线副本','2029-09-05T01:01:00Z'
);

do $$
begin
  if exists (select 1 from public.bath_records where id='d3000000-0000-4000-8000-000000000001') then
    raise exception 'stale bath record resurrected after delete';
  end if;
end $$;

insert into public.bath_records (
  id,user_id,pet_id,bathed_at,price,notes,updated_at
) values (
  'd3000000-0000-4000-8000-000000000001',
  'd1000000-0000-4000-8000-000000000001',
  'd2000000-0000-4000-8000-000000000001',
  '2031-09-05T01:00:00Z',120,'较新的离线编辑','2031-09-05T01:01:00Z'
);

do $$
begin
  if not exists (
    select 1 from public.bath_records
    where id='d3000000-0000-4000-8000-000000000001' and notes='较新的离线编辑'
  ) then
    raise exception 'newer bath record did not win';
  end if;
  if exists (
    select 1 from public.record_tombstones
    where record_kind='bath' and record_id='d3000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'superseded bath tombstone was not cleared';
  end if;
end $$;

reset role;
delete from auth.users
where id in (
  'd1000000-0000-4000-8000-000000000001',
  'd1000000-0000-4000-8000-000000000002'
);

do $$
begin
  if exists (select 1 from auth.users where email like 'qa-bath-%')
     or exists (select 1 from public.pets where id='d2000000-0000-4000-8000-000000000001')
     or exists (select 1 from public.bath_records where id='d3000000-0000-4000-8000-000000000001')
     or exists (select 1 from public.record_tombstones where record_id='d3000000-0000-4000-8000-000000000001') then
    raise exception 'temporary bath integration data was not removed';
  end if;
end $$;

begin;

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous
) values
  ('a0000000-0000-4000-8000-000000000001','authenticated','authenticated','qa-owner@invalid.example','',now(),'{"provider":"apple","providers":["apple"]}'::jsonb,'{}'::jsonb,now(),now(),false,false),
  ('a0000000-0000-4000-8000-000000000002','authenticated','authenticated','qa-caregiver@invalid.example','',now(),'{"provider":"apple","providers":["apple"]}'::jsonb,'{}'::jsonb,now(),now(),false,false);

insert into public.profiles (id, display_name, onboarding_completed)
values
  ('a0000000-0000-4000-8000-000000000001','QA Owner',true),
  ('a0000000-0000-4000-8000-000000000002','QA Caregiver',true);

select set_config('request.jwt.claim.sub','a0000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"a0000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
set local role authenticated;

insert into public.pets (id,user_id,name,species,gender,neutered_status,breed_name,birthday,updated_at)
values
  ('b0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000001','QA共享宠物','cat','female','neutered','其它','2024-01-01','2026-09-04T10:00:00Z'),
  ('b0000000-0000-4000-8000-000000000002','a0000000-0000-4000-8000-000000000001','QA唯一码宠物','dog','male','not_neutered','其它','2023-01-01','2026-09-04T10:00:00Z');

do $$
declare first_code text; second_code text;
begin
  select share_code into first_code from public.pet_share_codes where pet_id='b0000000-0000-4000-8000-000000000001';
  select share_code into second_code from public.pet_share_codes where pet_id='b0000000-0000-4000-8000-000000000002';
  if first_code !~ '^[0-9]{8}$' or second_code !~ '^[0-9]{8}$' or first_code = second_code then
    raise exception 'share-code generation or uniqueness failed';
  end if;
  if (select count(*) from public.pet_members where pet_id='b0000000-0000-4000-8000-000000000001' and role='owner') <> 1 then
    raise exception 'owner membership bootstrap failed';
  end if;
end $$;

select set_config('qa.first_share_code',(select share_code from public.pet_share_codes where pet_id='b0000000-0000-4000-8000-000000000001'),true);
insert into public.deworm_records (id,user_id,pet_id,medicine_name,treatment_scope,purchase_price,used_at,updated_at)
values ('c0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001','QA驱虫药','internal',12.50,'2026-09-04','2026-09-04T10:01:00Z');

reset role;
select set_config('request.jwt.claim.sub','a0000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"a0000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select public.join_pet_by_share_code(current_setting('qa.first_share_code'));

do $$
declare affected integer;
begin
  if (select count(*) from public.pets where id='b0000000-0000-4000-8000-000000000001') <> 1 then
    raise exception 'caregiver cannot read shared pet';
  end if;
  if (select count(*) from public.pet_share_codes where pet_id='b0000000-0000-4000-8000-000000000001') <> 0 then
    raise exception 'caregiver can read owner share code';
  end if;
  update public.pets set name='ILLEGAL',updated_at='2026-09-04T10:02:00Z'
  where id='b0000000-0000-4000-8000-000000000001';
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'caregiver edited pet profile'; end if;
  begin
    perform public.reset_pet_share_code('b0000000-0000-4000-8000-000000000001');
    raise exception 'caregiver reset share code';
  exception when insufficient_privilege then null;
  end;
end $$;

insert into public.vaccine_records (id,user_id,pet_id,vaccine_name,injected_at,dose_number,updated_at)
values ('c0000000-0000-4000-8000-000000000002','a0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001','QA疫苗','2026-09-04T10:03:00Z',1,'2026-09-04T10:03:00Z');
insert into public.food_records (id,user_id,pet_id,product_name,package_weight_kg,purchase_price,purchased_on,updated_at)
values ('c0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001','QA主粮',1.5,99,'2026-09-04','2026-09-04T10:04:00Z');
insert into public.taste_records (id,user_id,pet_id,brand_name,product_name,category_name,rating,tasted_on,updated_at)
values ('c0000000-0000-4000-8000-000000000004','a0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001','QA品牌','QA产品','罐头',4.5,'2026-09-04','2026-09-04T10:05:00Z');
insert into public.bath_records (id,user_id,pet_id,bathed_at,price,notes,updated_at)
values ('c0000000-0000-4000-8000-000000000005','a0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001','2026-09-04T10:05:30Z',88,'QA洗澡','2026-09-04T10:05:30Z');
update public.deworm_records set medicine_name='QA共同编辑',updated_at='2026-09-04T10:06:00Z'
where id='c0000000-0000-4000-8000-000000000001';

do $$
begin
  if not public.delete_pet_record('food','c0000000-0000-4000-8000-000000000003','b0000000-0000-4000-8000-000000000001','2026-09-04T10:07:00Z') then
    raise exception 'valid shared delete rejected';
  end if;
  if exists (select 1 from public.food_records where id='c0000000-0000-4000-8000-000000000003') then raise exception 'record not deleted'; end if;
  if not exists (select 1 from public.record_tombstones where record_kind='food' and record_id='c0000000-0000-4000-8000-000000000003') then
    raise exception 'tombstone not visible to caregiver';
  end if;
end $$;

insert into public.food_records (id,user_id,pet_id,product_name,package_weight_kg,purchase_price,purchased_on,updated_at)
values ('c0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001','STALE',1.5,99,'2026-09-04','2026-09-04T10:06:30Z');
do $$ begin
  if exists (select 1 from public.food_records where id='c0000000-0000-4000-8000-000000000003') then raise exception 'stale record resurrected after delete'; end if;
end $$;

insert into public.food_records (id,user_id,pet_id,product_name,package_weight_kg,purchase_price,purchased_on,updated_at)
values ('c0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000001','b0000000-0000-4000-8000-000000000001','QA较新离线编辑',1.5,99,'2026-09-04','2030-09-04T10:08:00Z');
do $$ begin
  if not exists (select 1 from public.food_records where id='c0000000-0000-4000-8000-000000000003' and product_name='QA较新离线编辑') then raise exception 'newer offline record did not win'; end if;
  if exists (select 1 from public.record_tombstones where record_kind='food' and record_id='c0000000-0000-4000-8000-000000000003') then raise exception 'superseded tombstone was not cleared'; end if;
end $$;

select public.leave_shared_pet('b0000000-0000-4000-8000-000000000001');
do $$ begin
  if exists (select 1 from public.pets where id='b0000000-0000-4000-8000-000000000001') then raise exception 'caregiver still sees pet after leaving'; end if;
end $$;
select public.join_pet_by_share_code(current_setting('qa.first_share_code'));

reset role;
select set_config('request.jwt.claim.sub','a0000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"a0000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
set local role authenticated;
do $$
declare member_count integer; old_code text; new_code text;
begin
  select count(*) into member_count from public.list_pet_members('b0000000-0000-4000-8000-000000000001');
  if member_count <> 2 then raise exception 'owner member list count wrong'; end if;
  old_code := public.ensure_pet_share_code('b0000000-0000-4000-8000-000000000001');
  new_code := public.reset_pet_share_code('b0000000-0000-4000-8000-000000000001');
  if old_code = new_code or new_code !~ '^[0-9]{8}$' then raise exception 'share-code reset failed'; end if;
  if (select medicine_name from public.deworm_records where id='c0000000-0000-4000-8000-000000000001') <> 'QA共同编辑' then raise exception 'owner did not receive caregiver edit'; end if;
  if (select count(*) from public.vaccine_records where pet_id='b0000000-0000-4000-8000-000000000001') <> 1
     or (select count(*) from public.food_records where pet_id='b0000000-0000-4000-8000-000000000001') <> 1
     or (select count(*) from public.taste_records where pet_id='b0000000-0000-4000-8000-000000000001') <> 1
     or (select count(*) from public.bath_records where pet_id='b0000000-0000-4000-8000-000000000001') <> 1 then
    raise exception 'shared record types did not synchronize';
  end if;
  perform public.remove_pet_member('b0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000002');
end $$;

reset role;
select set_config('request.jwt.claim.sub','a0000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"a0000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
set local role authenticated;
do $$ begin
  if exists (select 1 from public.pets where id='b0000000-0000-4000-8000-000000000001') then raise exception 'removed caregiver still sees pet'; end if;
  if exists (select 1 from public.deworm_records where pet_id='b0000000-0000-4000-8000-000000000001') then raise exception 'removed caregiver still sees records'; end if;
end $$;

reset role;
rollback;
select 'PASS: two-user share, permissions, record sync, conflict and tombstone tests rolled back cleanly' as result;

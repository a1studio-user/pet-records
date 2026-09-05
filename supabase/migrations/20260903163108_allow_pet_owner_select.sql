-- Let an owner see a newly inserted pet before the AFTER INSERT sharing
-- trigger has finished bootstrapping its pet_members row. Caregivers continue
-- to receive access exclusively through membership.
drop policy if exists "pets_select_for_members" on public.pets;

create policy "pets_select_for_owner_or_members"
on public.pets
for select
to authenticated
using (
  user_id = (select auth.uid())
  or id in (select private.current_user_pet_ids())
);

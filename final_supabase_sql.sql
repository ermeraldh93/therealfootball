-- The Real Football final launch SQL
-- Run this once in Supabase SQL Editor before testing updated picks/results.

-- Prevent duplicate picks per player per match and allow updates via upsert.
delete from picks
where id in (
  select id from (
    select id,
           row_number() over (partition by participant_id, match_id order by created_at desc) as rn
    from picks
  ) x
  where x.rn > 1
);

alter table picks
add constraint if not exists picks_participant_match_unique
unique (participant_id, match_id);

-- Policies needed for update/upsert behavior.
drop policy if exists "Allow public pick update" on picks;
create policy "Allow public pick update"
on picks for update
to public
using (true)
with check (true);

drop policy if exists "Allow public result insert" on results;
create policy "Allow public result insert"
on results for insert
to public
with check (true);

drop policy if exists "Allow public result update" on results;
create policy "Allow public result update"
on results for update
to public
using (true)
with check (true);

drop policy if exists "Allow public result viewing" on results;
create policy "Allow public result viewing"
on results for select
to public
using (true);

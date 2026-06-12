-- Run this once in Supabase SQL Editor before deploying the new website files.

alter table participants add column if not exists first_name text;
alter table participants add column if not exists last_name text;
alter table participants add column if not exists birth_date date;

-- Your old email column was originally required. Drop the requirement so new users can register without email.
alter table participants alter column email drop not null;

-- Keep name populated for leaderboard compatibility.
update participants
set first_name = split_part(name, ' ', 1)
where first_name is null and name is not null;

update participants
set last_name = nullif(trim(replace(name, split_part(name, ' ', 1), '')), '')
where last_name is null and name is not null;

-- Prevent duplicate registrations with same first name, last name, and birth date.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'participants_name_birthdate_unique'
  ) then
    alter table participants
    add constraint participants_name_birthdate_unique
    unique (first_name, last_name, birth_date);
  end if;
end $$;

-- Replace leaderboard view so it keeps working with first/last names.
create or replace view leaderboard as
select
  p.id,
  coalesce(nullif(trim(coalesce(p.first_name,'') || ' ' || coalesce(p.last_name,'')), ''), p.name) as name,
  count(r.id) as correct_picks
from participants p
left join picks pk
  on p.id = pk.participant_id
left join results r
  on pk.match_id = r.match_id
 and pk.selected_team = r.winning_team
group by p.id, p.first_name, p.last_name, p.name
order by correct_picks desc;

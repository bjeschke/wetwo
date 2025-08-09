-- Profil automatisch bei neuem auth.users-Eintrag anlegen
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as 19360
begin
  insert into public.profiles (id, name, zodiac_sign, birth_date)
  values (new.id, '', 'unknown', current_date);
  return new;
end;
19360;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
-- lösche verwaiste/alte Profile ohne passenden auth.users-Eintrag
delete from public.profiles p
where not exists (select 1 from auth.users u where u.id = p.id);

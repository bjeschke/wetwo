-- Auto Profile Creation Trigger
-- Run this in your Supabase SQL Editor

-- Create function to handle new user creation (merged with existing subscription logic)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Log the trigger execution
  raise log 'Trigger handle_new_user executed for user ID: %', new.id;
  
  begin
    -- First create the profile (required for foreign key constraints)
    insert into public.profiles (id, name, zodiac_sign, birth_date)
    values (new.id, '', 'unknown', current_date);
    
    raise log 'Profile created successfully for user ID: %', new.id;
  exception when others then
    raise log 'Error creating profile for user ID %: %', new.id, sqlerrm;
    raise;
  end;
  
  begin
    -- Then create the subscription (existing functionality)
    insert into subscriptions (user_id, plan_type, status)
    values (new.id, 'free', 'active');
    
    raise log 'Subscription created successfully for user ID: %', new.id;
  exception when others then
    raise log 'Error creating subscription for user ID %: %', new.id, sqlerrm;
    raise;
  end;
  
  return new;
end;
$$;

-- Create trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Verify the trigger was created
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

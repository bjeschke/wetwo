-- Auto Profile Creation Trigger - COMPREHENSIVE FIX
-- Run this in your Supabase SQL Editor to replace the conflicting trigger

-- First, drop the existing conflicting trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create the new comprehensive function that handles both profiles and subscriptions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    profile_count INTEGER;
    subscription_count INTEGER;
BEGIN
  -- Log the trigger execution
  RAISE LOG 'Trigger handle_new_user executed for user ID: %', NEW.id;
  
  -- Check if profile already exists (shouldn't happen, but safety check)
  SELECT COUNT(*) INTO profile_count FROM profiles WHERE id = NEW.id;
  IF profile_count > 0 THEN
    RAISE LOG 'Profile already exists for user ID: %, skipping profile creation', NEW.id;
  ELSE
    BEGIN
      -- Create the profile (required for foreign key constraints)
      INSERT INTO public.profiles (id, name, zodiac_sign, birth_date)
      VALUES (NEW.id, '', 'unknown', CURRENT_DATE);
      
      RAISE LOG 'Profile created successfully for user ID: %', NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating profile for user ID %: %', NEW.id, SQLERRM;
      -- Don't raise here, continue with subscription creation
    END;
  END IF;
  
  -- Check if subscription already exists (shouldn't happen, but safety check)
  SELECT COUNT(*) INTO subscription_count FROM subscriptions WHERE user_id = NEW.id;
  IF subscription_count > 0 THEN
    RAISE LOG 'Subscription already exists for user ID: %, skipping subscription creation', NEW.id;
  ELSE
    BEGIN
      -- Create the subscription (existing functionality)
      INSERT INTO subscriptions (user_id, plan_type, status)
      VALUES (NEW.id, 'free', 'active');
      
      RAISE LOG 'Subscription created successfully for user ID: %', NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating subscription for user ID %: %', NEW.id, SQLERRM;
      -- Don't raise here, allow the user creation to succeed
    END;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Grant necessary permissions to the function
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon;

-- Create the new trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verify the trigger was created
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Verify the function exists
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- Auto Profile Creation Trigger - ENHANCED VERSION
-- Run this in your Supabase SQL Editor to replace the existing trigger

-- First, drop the existing conflicting trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create the enhanced function that handles both profiles and subscriptions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    profile_count INTEGER;
    subscription_count INTEGER;
    profile_id UUID;
BEGIN
  -- Log the trigger execution
  RAISE LOG 'Trigger handle_new_user executed for user ID: %', NEW.id;
  
  -- Set the profile_id to the new user's ID
  profile_id := NEW.id;
  
  -- Check if profile already exists (shouldn't happen, but safety check)
  SELECT COUNT(*) INTO profile_count FROM profiles WHERE id = profile_id;
  IF profile_count > 0 THEN
    RAISE LOG 'Profile already exists for user ID: %, skipping profile creation', profile_id;
  ELSE
    BEGIN
      -- Create the profile with better error handling
      INSERT INTO public.profiles (
        id, 
        name, 
        zodiac_sign, 
        birth_date,
        created_at,
        updated_at
      )
      VALUES (
        profile_id, 
        COALESCE(NEW.raw_user_meta_data->>'name', 'User'), 
        'unknown', 
        CURRENT_DATE,
        NOW(),
        NOW()
      );
      
      RAISE LOG 'Profile created successfully for user ID: % with name: %', 
        profile_id, 
        COALESCE(NEW.raw_user_meta_data->>'name', 'User');
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating profile for user ID %: %', profile_id, SQLERRM;
      -- Re-raise the error to prevent user creation if profile creation fails
      RAISE EXCEPTION 'Failed to create profile for user %: %', profile_id, SQLERRM;
    END;
  END IF;
  
  -- Check if subscription already exists (shouldn't happen, but safety check)
  SELECT COUNT(*) INTO subscription_count FROM subscriptions WHERE user_id = profile_id;
  IF subscription_count > 0 THEN
    RAISE LOG 'Subscription already exists for user ID: %, skipping subscription creation', profile_id;
  ELSE
    BEGIN
      -- Create the subscription (existing functionality)
      INSERT INTO subscriptions (user_id, plan_type, status)
      VALUES (profile_id, 'free', 'active');
      
      RAISE LOG 'Subscription created successfully for user ID: %', profile_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'Error creating subscription for user ID %: %', profile_id, SQLERRM;
      -- Don't raise here, allow the user creation to succeed even if subscription fails
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

-- Test the trigger by checking if it's properly set up
DO $$
BEGIN
    RAISE LOG 'Auto profile trigger setup completed successfully';
END $$;

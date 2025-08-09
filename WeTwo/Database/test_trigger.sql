-- Test script to verify the trigger is working
-- Run this in your Supabase SQL Editor after applying the trigger fix

-- 1. Check if the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 2. Check if the function exists
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- 3. Check current profiles count
SELECT COUNT(*) as current_profiles FROM profiles;

-- 4. Check current subscriptions count
SELECT COUNT(*) as current_subscriptions FROM subscriptions;

-- 5. Check RLS policies on profiles table
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 6. Check RLS policies on subscriptions table
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'subscriptions';

-- 7. Verify table structure
\d profiles
\d subscriptions

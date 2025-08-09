-- Debug script to identify trigger issues
-- Run this in your Supabase SQL Editor

-- 1. Check if the trigger exists and is active
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 2. Check if the function exists and has correct permissions
SELECT 
    routine_name,
    routine_type,
    data_type,
    security_type,
    is_deterministic
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- 3. Check function permissions
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.routine_privileges 
WHERE routine_name = 'handle_new_user';

-- 4. Check if tables exist and have correct structure
SELECT 
    table_name,
    table_type,
    is_insertable_into
FROM information_schema.tables 
WHERE table_name IN ('profiles', 'subscriptions')
ORDER BY table_name;

-- 5. Check RLS status on tables
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('profiles', 'subscriptions');

-- 6. Check RLS policies
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
WHERE tablename IN ('profiles', 'subscriptions')
ORDER BY tablename, policyname;

-- 7. Check for any existing profiles or subscriptions
SELECT 'profiles' as table_name, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'subscriptions' as table_name, COUNT(*) as count FROM subscriptions;

-- 8. Check the most recent database logs (if accessible)
-- Note: This might not work in Supabase depending on your plan
SELECT 
    log_time,
    log_level,
    log_message
FROM pg_stat_activity 
WHERE log_message IS NOT NULL
ORDER BY log_time DESC
LIMIT 10;

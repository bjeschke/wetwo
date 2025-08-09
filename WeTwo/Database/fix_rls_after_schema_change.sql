-- Fix RLS Policies after Schema Change
-- Run this in your Supabase SQL Editor

-- 1. Drop all existing policies for profiles table
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view partner profiles" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;
DROP POLICY IF EXISTS "Enable insert for signup process" ON profiles;

-- 2. Create new policies that work with the current schema
CREATE POLICY "Enable read access for all users" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for signup process" ON profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for users based on id" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- 3. Verify the policies are created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

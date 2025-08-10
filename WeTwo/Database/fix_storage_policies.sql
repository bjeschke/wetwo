-- Fix Storage Policies for Profile Photos
-- IMPORTANT: This must be run by a Supabase admin or through the Supabase CLI
-- If you get permission errors, use the Supabase Dashboard Storage section instead

-- 1. Ensure the profile-photos bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies if they exist (requires admin privileges)
DROP POLICY IF EXISTS "Users can upload their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Partners can view each other's profile photos" ON storage.objects;

-- 4. Create new storage policies for profile photos (flat file structure)
CREATE POLICY "Users can upload their own profile photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = split_part(name, '_', 1)
    );

CREATE POLICY "Users can view their own profile photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = split_part(name, '_', 1)
    );

CREATE POLICY "Users can update their own profile photos" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = split_part(name, '_', 1)
    );

CREATE POLICY "Users can delete their own profile photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = split_part(name, '_', 1)
    );

-- 5. Allow partners to view each other's profile photos
CREATE POLICY "Partners can view each other's profile photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-photos' AND 
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id::text = split_part(name, '_', 1)) 
               OR (partner_id = auth.uid() AND user_id::text = split_part(name, '_', 1))
        )
    );

-- 6. Verify the policies were created
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
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;

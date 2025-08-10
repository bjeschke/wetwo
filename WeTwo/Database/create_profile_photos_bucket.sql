-- Create Profile Photos Bucket with Robust Folder-Based Policies
-- Run this in your Supabase SQL Editor

-- 1. Create the profile-photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-photos', 
    'profile-photos', 
    true, 
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies if they exist
DROP POLICY IF EXISTS "pp_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "pp_select_own" ON storage.objects;
DROP POLICY IF EXISTS "pp_update_own" ON storage.objects;
DROP POLICY IF EXISTS "pp_delete_own" ON storage.objects;
DROP POLICY IF EXISTS "pp_select_partner" ON storage.objects;

-- 4. Create robust folder-based policies
-- Upload (INSERT)
CREATE POLICY "pp_insert_own"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'profile-photos'
    AND position(auth.uid()::text || '/' in name) = 1
);

-- View (SELECT)
CREATE POLICY "pp_select_own"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'profile-photos'
    AND position(auth.uid()::text || '/' in name) = 1
);

-- Update
CREATE POLICY "pp_update_own"
ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'profile-photos'
    AND position(auth.uid()::text || '/' in name) = 1
);

-- Delete
CREATE POLICY "pp_delete_own"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'profile-photos'
    AND position(auth.uid()::text || '/' in name) = 1
);

-- Partner View (directionless partnership check)
CREATE POLICY "pp_select_partner"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'profile-photos'
    AND EXISTS (
        SELECT 1
        FROM public.partnerships p
        WHERE least(p.user_id, p.partner_id) = least(auth.uid(), (split_part(name,'/',1))::uuid)
          AND greatest(p.user_id, p.partner_id) = greatest(auth.uid(), (split_part(name,'/',1))::uuid)
    )
);

-- 5. Verify the bucket was created
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'profile-photos';

-- 6. Verify the policies were created
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE 'pp_%'
ORDER BY policyname;

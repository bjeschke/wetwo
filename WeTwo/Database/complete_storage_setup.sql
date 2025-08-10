-- Complete Storage Setup for WeTwo App
-- Run this in your Supabase SQL Editor to set up storage properly

-- ========================================
-- STORAGE BUCKETS SETUP
-- ========================================

-- 1. Create profile-photos bucket
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

-- 2. Create memory-photos bucket (for memory photos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'memory-photos', 
    'memory-photos', 
    true, 
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ========================================
-- ROW LEVEL SECURITY SETUP
-- ========================================

-- 3. Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ========================================
-- STORAGE POLICIES FOR PROFILE PHOTOS
-- ========================================

-- 4. Drop existing profile photo policies (if they exist)
DROP POLICY IF EXISTS "Users can upload their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Partners can view each other's profile photos" ON storage.objects;

-- 5. Create new profile photo policies
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

-- 6. Allow partners to view each other's profile photos
CREATE POLICY "Partners can view each other's profile photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-photos' AND 
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id::text = split_part(name, '_', 1)) 
               OR (partner_id = auth.uid() AND user_id::text = split_part(name, '_', 1))
        )
    );

-- ========================================
-- STORAGE POLICIES FOR MEMORY PHOTOS
-- ========================================

-- 7. Drop existing memory photo policies (if they exist)
DROP POLICY IF EXISTS "Users can upload their own memory photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view memory photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own memory photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own memory photos" ON storage.objects;

-- 8. Create new memory photo policies
CREATE POLICY "Users can upload their own memory photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'memory-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view memory photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'memory-photos' AND (
            auth.uid()::text = (storage.foldername(name))[1] OR
            EXISTS (
                SELECT 1 FROM memories m
                JOIN partnerships p ON (p.user_id = auth.uid() AND p.partner_id = m.user_id) 
                                   OR (p.partner_id = auth.uid() AND p.user_id = m.user_id)
                WHERE m.id::text = (storage.foldername(name))[2] AND m.is_shared = 'true'
            )
        )
    );

CREATE POLICY "Users can update their own memory photos" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'memory-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own memory photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'memory-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ========================================
-- VERIFICATION
-- ========================================

-- 9. Verify buckets were created
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id IN ('profile-photos', 'memory-photos')
ORDER BY id;

-- 10. Verify policies were created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%profile%' OR policyname LIKE '%memory%'
ORDER BY policyname;

-- ========================================
-- TEST DATA (Optional)
-- ========================================

-- 11. Create a test profile if needed (uncomment if you want to test)
/*
INSERT INTO profiles (id, name, zodiac_sign, birth_date)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Test User',
    'Aries',
    '1990-01-01'
)
ON CONFLICT (id) DO NOTHING;
*/

-- Storage Setup for Profile Photos
-- Run this in your Supabase SQL Editor

-- 1. Create profile-photos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Create storage policies for profile photos
CREATE POLICY "Users can upload their own profile photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view their own profile photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can update their own profile photos" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own profile photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- 4. Allow partners to view each other's profile photos
CREATE POLICY "Partners can view each other's profile photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-photos' AND 
        EXISTS (
            SELECT 1 FROM partnerships 
            WHERE (user_id = auth.uid() AND partner_id::text = (storage.foldername(name))[1]) 
               OR (partner_id = auth.uid() AND user_id::text = (storage.foldername(name))[1])
        )
    );

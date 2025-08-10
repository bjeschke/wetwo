# Storage Setup Guide for WeTwo App

## 🚀 Quick Setup Instructions

### Option 1: Using SQL Script (Recommended)

1. **Go to Supabase Dashboard**
   - Open your Supabase project
   - Click on **"SQL Editor"** in the left sidebar

2. **Run the Complete Setup Script**
   - Click **"New query"**
   - Copy and paste the entire contents of `complete_storage_setup.sql`
   - Click **"Run"**

3. **Verify Setup**
   - Check the results to ensure buckets and policies were created
   - You should see 2 buckets and 9 policies created

### Option 2: Manual Setup via Dashboard

If the SQL script doesn't work due to permissions, use the dashboard:

#### Step 1: Create Storage Buckets

1. Go to **"Storage"** in Supabase Dashboard
2. Click **"New bucket"**
3. Create `profile-photos` bucket:
   - Name: `profile-photos`
   - Public: ✅ **Enabled**
   - File size limit: `10MB`
   - Allowed MIME types: `image/jpeg, image/png, image/webp`

4. Create `memory-photos` bucket:
   - Name: `memory-photos`
   - Public: ✅ **Enabled**
   - File size limit: `10MB`
   - Allowed MIME types: `image/jpeg, image/png, image/webp`

#### Step 2: Add Storage Policies

For each bucket, go to the **"Policies"** tab and add these policies:

**For `profile-photos` bucket:**

1. **Upload Policy**
   - Name: `Users can upload their own profile photos`
   - Operation: `INSERT`
   - Policy: `bucket_id = 'profile-photos' AND auth.uid()::text = split_part(name, '_', 1)`

2. **View Policy**
   - Name: `Users can view their own profile photos`
   - Operation: `SELECT`
   - Policy: `bucket_id = 'profile-photos' AND auth.uid()::text = split_part(name, '_', 1)`

3. **Update Policy**
   - Name: `Users can update their own profile photos`
   - Operation: `UPDATE`
   - Policy: `bucket_id = 'profile-photos' AND auth.uid()::text = split_part(name, '_', 1)`

4. **Delete Policy**
   - Name: `Users can delete their own profile photos`
   - Operation: `DELETE`
   - Policy: `bucket_id = 'profile-photos' AND auth.uid()::text = split_part(name, '_', 1)`

5. **Partner View Policy**
   - Name: `Partners can view each other's profile photos`
   - Operation: `SELECT`
   - Policy: `bucket_id = 'profile-photos' AND EXISTS (SELECT 1 FROM partnerships WHERE (user_id = auth.uid() AND partner_id::text = split_part(name, '_', 1)) OR (partner_id = auth.uid() AND user_id::text = split_part(name, '_', 1)))`

## 🔍 Verification

After setup, verify everything is working:

1. **Check Buckets**: Go to Storage → Buckets, you should see both buckets
2. **Check Policies**: Go to Storage → Policies, you should see all policies listed
3. **Test Upload**: Try uploading a profile photo in your app

## 📁 File Structure

The storage is configured for these file patterns:

- **Profile Photos**: `userId_profile.jpg` (e.g., `123e4567-e89b-12d3-a456-426614174000_profile.jpg`)
- **Memory Photos**: `userId/memoryId/filename.jpg` (folder structure)

## 🛠️ Troubleshooting

### Common Issues:

1. **Permission Error**: Use the dashboard method instead of SQL
2. **RLS Policy Error**: Ensure all policies are created correctly
3. **File Not Found**: Check that file names match the expected pattern

### Debug Steps:

1. Check Supabase logs in the dashboard
2. Verify user authentication is working
3. Test with a simple file upload first

## ✅ Success Indicators

When everything is set up correctly, you should see:

- ✅ No more "row-level security policy" errors
- ✅ Profile photos upload successfully
- ✅ Photos are accessible to the correct users
- ✅ Partner sharing works for profile photos

## 📞 Need Help?

If you're still having issues:

1. Check the Supabase logs in the dashboard
2. Verify your app's authentication is working
3. Test with a simple file upload first
4. Make sure the file naming matches the expected pattern

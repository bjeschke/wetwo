# Robust Storage Setup with Folder-Based Policies

## 🎯 **Improved Approach**

Based on the excellent suggestion, we've implemented a **robust folder-based storage structure** that's much more reliable than underscore-based naming.

## 📁 **File Structure**

Instead of: `userId_profile.jpg`
We now use: `userId/profile.jpg`

**Benefits:**
- ✅ **Robust**: Works with any filename (no underscore dependency)
- ✅ **Scalable**: Easy to add more files per user
- ✅ **Clear**: Obvious ownership structure
- ✅ **Future-proof**: Supports subfolders if needed

## 🔧 **SQL Policies**

The new policies use `position(auth.uid()::text || '/' in name) = 1` which:
- Checks if the user's ID appears at the start of the path
- Works with any filename structure
- Is much more reliable than `split_part()`

### **Key Policy Logic:**

```sql
-- Upload: User can only upload to their own folder
position(auth.uid()::text || '/' in name) = 1

-- View: User can view files in their own folder
position(auth.uid()::text || '/' in name) = 1

-- Partner View: Partners can view each other's files
EXISTS (
    SELECT 1 FROM partnerships p
    WHERE least(p.user_id, p.partner_id) = least(auth.uid(), (split_part(name,'/',1))::uuid)
      AND greatest(p.user_id, p.partner_id) = greatest(auth.uid(), (split_part(name,'/',1))::uuid)
)
```

## 📱 **Swift Implementation**

### **Upload Path:**
```swift
let path = "\(userId.uuidString)/profile.jpg"
// Results in: "123e4567-e89b-12d3-a456-426614174000/profile.jpg"
```

### **Storage Operations:**
- **Upload**: `upload(path: "\(userId)/profile.jpg")`
- **Download**: `download(path: "\(userId)/profile.jpg")`
- **Delete**: `remove(paths: ["\(userId)/profile.jpg"])`
- **List**: `list(path: userId.uuidString)`

## 🚀 **Setup Instructions**

1. **Run the SQL script** `create_profile_photos_bucket.sql`
2. **The app code is already updated** to use the new folder structure
3. **Test the upload** - it should work without RLS errors

## 🔍 **Verification**

After running the SQL, verify:
- ✅ Bucket `profile-photos` exists
- ✅ 5 policies created (pp_insert_own, pp_select_own, pp_update_own, pp_delete_own, pp_select_partner)
- ✅ RLS is enabled on storage.objects

## 🛡️ **Security Benefits**

- **User Isolation**: Users can only access their own folder
- **Partner Sharing**: Partners can view each other's photos
- **No Path Traversal**: Folder structure prevents unauthorized access
- **Robust Validation**: Position-based checking is more reliable

## 📊 **File Examples**

```
profile-photos/
├── 123e4567-e89b-12d3-a456-426614174000/
│   ├── profile.jpg
│   └── avatar.png
├── 987fcdeb-51a2-43c1-b567-789012345678/
│   └── profile.jpg
└── ...
```

## 🎉 **Result**

This approach eliminates the RLS permission issues and provides a much more robust, scalable storage solution for profile photos!

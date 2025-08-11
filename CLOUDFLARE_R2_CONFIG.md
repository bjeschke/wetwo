# Cloudflare R2 Storage Configuration

## Overview
WeTwo uses Cloudflare R2 for file storage, specifically for profile photos and memory photos. This document outlines the configuration and implementation details.

## Bucket Configuration

### Profile Photos Bucket
- **Bucket URL**: `https://fa151e87de0b5708a9317ae0e5be1cd6.r2.cloudflarestorage.com/profile-photos`
- **Bucket Name**: `profile-photos`
- **Region**: `auto`
- **Purpose**: Store user profile photos

## Environment Variables

Add these to your Railway environment variables:

```bash
# Cloudflare R2 Configuration
CLOUDFLARE_R2_ACCOUNT_ID=your_account_id
CLOUDFLARE_R2_ACCESS_KEY_ID=your_access_key_id
CLOUDFLARE_R2_SECRET_ACCESS_KEY=your_secret_access_key
CLOUDFLARE_R2_BUCKET_NAME=profile-photos
CLOUDFLARE_R2_BUCKET_URL=https://fa151e87de0b5708a9317ae0e5be1cd6.r2.cloudflarestorage.com/profile-photos

# Optional: Additional buckets
CLOUDFLARE_R2_MEMORY_PHOTOS_BUCKET=memory-photos
CLOUDFLARE_R2_MOOD_PHOTOS_BUCKET=mood-photos
```

## File Structure

### Profile Photos
```
profile-photos/
├── {user_id}/
│   ├── profile.jpg
│   └── profile_thumb.jpg (optional thumbnail)
```

### Memory Photos
```
memory-photos/
├── {user_id}/
│   ├── {memory_id}/
│   │   ├── original.jpg
│   │   └── thumbnail.jpg
```

### Mood Photos
```
mood-photos/
├── {user_id}/
│   ├── {date}/
│   │   └── mood.jpg
```

## Implementation Guidelines

### 1. File Upload Process
```javascript
// Example Node.js implementation
const uploadProfilePhoto = async (userId, fileBuffer, fileName) => {
  const filePath = `${userId}/${fileName}`;
  const fileUrl = `${CLOUDFLARE_R2_BUCKET_URL}/${filePath}`;
  
  // Upload to R2
  await r2.put(filePath, fileBuffer, {
    httpMetadata: {
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=31536000'
    }
  });
  
  // Save metadata to database
  await db.storage_files.create({
    user_id: userId,
    file_name: fileName,
    file_path: filePath,
    file_url: fileUrl,
    file_size: fileBuffer.length,
    mime_type: 'image/jpeg',
    file_type: 'profile_photo',
    bucket_name: 'profile-photos'
  });
  
  return fileUrl;
};
```

### 2. File Access
```javascript
// Public access (no authentication required)
const getProfilePhotoUrl = (userId) => {
  return `${CLOUDFLARE_R2_BUCKET_URL}/${userId}/profile.jpg`;
};

// Private access (requires authentication)
const getPrivateFileUrl = async (fileId, userId) => {
  const file = await db.storage_files.findByPk(fileId);
  if (file.user_id !== userId) {
    throw new Error('Unauthorized');
  }
  return file.file_url;
};
```

### 3. File Deletion
```javascript
const deleteProfilePhoto = async (userId) => {
  // Delete from R2
  await r2.delete(`${userId}/profile.jpg`);
  
  // Delete from database
  await db.storage_files.destroy({
    where: {
      user_id: userId,
      file_type: 'profile_photo'
    }
  });
};
```

## Security Considerations

### 1. CORS Configuration
Configure CORS in your R2 bucket:
```json
{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
```

### 2. Public vs Private Access
- **Profile Photos**: Public access for fast loading
- **Memory Photos**: Private access with authentication
- **Mood Photos**: Private access with authentication

### 3. File Validation
```javascript
const validateImageFile = (file) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
  const maxSize = 10 * 1024 * 1024; // 10MB
  
  if (!allowedTypes.includes(file.mimetype)) {
    throw new Error('Invalid file type');
  }
  
  if (file.size > maxSize) {
    throw new Error('File too large');
  }
  
  return true;
};
```

## Performance Optimization

### 1. Image Processing
```javascript
const sharp = require('sharp');

const processProfilePhoto = async (fileBuffer) => {
  // Resize to standard size
  const processed = await sharp(fileBuffer)
    .resize(400, 400, { fit: 'cover' })
    .jpeg({ quality: 80 })
    .toBuffer();
    
  return processed;
};
```

### 2. Caching
```javascript
// Set appropriate cache headers
const cacheHeaders = {
  'Cache-Control': 'public, max-age=31536000, immutable',
  'ETag': generateETag(fileBuffer)
};
```

### 3. CDN Integration
Cloudflare R2 automatically provides CDN capabilities:
- Global edge locations
- Automatic compression
- Image optimization

## Error Handling

### 1. Upload Failures
```javascript
const uploadWithRetry = async (fileBuffer, filePath, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await r2.put(filePath, fileBuffer);
      return true;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
};
```

### 2. Database Consistency
```javascript
const uploadWithTransaction = async (userId, fileBuffer, fileName) => {
  const transaction = await db.sequelize.transaction();
  
  try {
    // Upload to R2
    const fileUrl = await uploadToR2(fileBuffer, fileName);
    
    // Save to database
    await db.storage_files.create({
      user_id: userId,
      file_url: fileUrl,
      // ... other fields
    }, { transaction });
    
    await transaction.commit();
    return fileUrl;
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
};
```

## Monitoring and Logging

### 1. Upload Metrics
```javascript
const uploadMetrics = {
  totalUploads: 0,
  successfulUploads: 0,
  failedUploads: 0,
  averageUploadTime: 0
};
```

### 2. Error Logging
```javascript
const logUploadError = (error, userId, fileName) => {
  console.error('Upload failed:', {
    error: error.message,
    userId,
    fileName,
    timestamp: new Date().toISOString()
  });
};
```

## Testing

### 1. Upload Test
```javascript
const testUpload = async () => {
  const testBuffer = Buffer.from('test image data');
  const userId = 'test-user-id';
  const fileName = 'test.jpg';
  
  try {
    const fileUrl = await uploadProfilePhoto(userId, testBuffer, fileName);
    console.log('Upload successful:', fileUrl);
    
    // Verify file exists
    const exists = await r2.head(`${userId}/${fileName}`);
    console.log('File exists:', !!exists);
  } catch (error) {
    console.error('Upload test failed:', error);
  }
};
```

### 2. Performance Test
```javascript
const performanceTest = async () => {
  const startTime = Date.now();
  const fileBuffer = generateTestImage(1024, 1024); // 1MB image
  
  await uploadProfilePhoto('test-user', fileBuffer, 'perf-test.jpg');
  
  const endTime = Date.now();
  console.log(`Upload took ${endTime - startTime}ms`);
};
```

## Migration from Supabase Storage

If migrating from Supabase storage:

1. **Download existing files** from Supabase
2. **Upload to R2** with same file structure
3. **Update database** with new URLs
4. **Verify all files** are accessible
5. **Update iOS app** to use new URLs

```javascript
const migrateFromSupabase = async () => {
  const files = await supabase.storage.list('profile-photos');
  
  for (const file of files) {
    const fileData = await supabase.storage.download(file.name);
    await uploadToR2(fileData, file.name);
    
    // Update database
    await db.storage_files.update({
      file_url: `${CLOUDFLARE_R2_BUCKET_URL}/${file.name}`
    }, {
      where: { file_path: file.name }
    });
  }
};
```

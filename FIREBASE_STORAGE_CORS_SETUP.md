# Firebase Storage CORS Configuration

If images are still not loading on web, you may need to configure CORS (Cross-Origin Resource Sharing) for Firebase Storage.

## Setting up CORS for Firebase Storage

1. **Create a CORS configuration file** (`cors.json`):

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

2. **Apply CORS configuration using gsutil**:

```bash
# Install gsutil if you haven't already
# https://cloud.google.com/storage/docs/gsutil_install

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Apply CORS configuration
gsutil cors set cors.json gs://YOUR_PROJECT_ID.appspot.com
```

3. **Or use the Firebase Console**:

- Go to Firebase Console → Storage
- Click on the Settings gear icon
- Look for CORS configuration option
- Add the CORS rules manually

## Alternative: Use Firebase Storage Rules

Make sure your storage rules allow public read access for images:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to read images
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Testing CORS

After configuring CORS, test if images load:

1. Open browser DevTools (F12)
2. Go to Network tab
3. Try loading an image
4. Check if there are any CORS errors in the Console tab

## Troubleshooting

- **CORS errors**: Make sure CORS is properly configured
- **403 Forbidden**: Check Firebase Storage security rules
- **404 Not Found**: Verify the image URL is correct
- **Network errors**: Check if Firebase Storage is accessible

## Note

The code changes made use `CachedNetworkImage` which handles CORS better than `Image.network` on web. However, proper CORS configuration is still required for Firebase Storage.


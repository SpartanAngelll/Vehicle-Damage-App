# Firebase to Supabase Sync Setup Guide

This guide explains how to configure Firebase Functions to automatically sync events from Firebase to your Supabase database.

## 🔧 Configuration Required

### 1. Get Supabase Service Role Key

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Navigate to **Settings** → **API**
3. Copy the **`service_role`** key (NOT the `anon` key)
   - ⚠️ **Important**: The service role key has admin privileges and bypasses RLS policies
   - Keep this key secure and never expose it in client-side code

### 2. Configure Firebase Functions

You have two options to set the Supabase credentials:

#### Option A: Using Firebase Functions Config (Recommended for Production)

```bash
# Set Supabase URL
firebase functions:config:set supabase.url="https://rodzemxwopecqpazkjyk.supabase.co"

# Set Supabase Service Role Key
firebase functions:config:set supabase.service_role_key="your-service-role-key-here"
```

#### Option B: Using Environment Variables (For Local Development)

Create a `.env` file in the `backend/functions/` directory:

```env
SUPABASE_URL=https://rodzemxwopecqpazkjyk.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

Then load it in your Firebase Functions (already configured in `index.js`).

### 3. Install Dependencies

Navigate to the `backend/functions/` directory and install the Supabase client:

```bash
cd backend/functions
npm install
```

This will install `@supabase/supabase-js` which was added to `package.json`.

### 4. Deploy Firebase Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:onUserCreate,functions:onChatRoomCreated,functions:onChatMessageCreatedSubcollection,functions:onChatMessageCreatedTopLevel
```

## 📋 What Gets Synced

### ✅ User Sign-ups
- **Trigger**: `onUserCreate` - Firebase Auth user creation
- **Destination**: Supabase `users` table
- **Data Synced**:
  - Firebase UID → `firebase_uid`
  - Email → `email`
  - Display name → `full_name`, `display_name`
  - Photo URL → `profile_photo_url`
  - User data from Firestore (if available)

### ✅ Chat Rooms
- **Trigger**: `onChatRoomCreated` - Firestore `chatRooms/{roomId}` creation
- **Destination**: Supabase `chat_rooms` table
- **Data Synced**:
  - Customer and Professional IDs (mapped from Firebase UIDs to Supabase user IDs)
  - Booking ID
  - Last message info
  - Metadata (includes Firestore room ID for reference)

### ✅ Chat Messages (Two Paths)

#### Path 1: Subcollection Messages
- **Trigger**: `onChatMessageCreatedSubcollection`
- **Firestore Path**: `chatRooms/{roomId}/messages/{messageId}`
- **Destination**: Supabase `chat_messages` table

#### Path 2: Top-Level Collection Messages
- **Trigger**: `onChatMessageCreatedTopLevel`
- **Firestore Path**: `chat_messages/{messageId}`
- **Destination**: Supabase `chat_messages` table

**Data Synced**:
- Message text/content
- Sender ID (mapped from Firebase UID to Supabase user ID)
- Message type (text/image/file)
- Media URL
- Read status
- Timestamp
- Metadata (includes Firestore message ID for reference)

## 🔍 How It Works

1. **Firebase Event Occurs**: User signs up, chat room created, or message sent
2. **Firebase Function Triggers**: The corresponding Cloud Function is automatically triggered
3. **User ID Mapping**: Functions look up Supabase user IDs using Firebase UIDs
4. **Data Transformation**: Firestore data is transformed to match Supabase schema
5. **Supabase Insert**: Data is inserted into Supabase using the REST API
6. **Error Handling**: Errors are logged but don't fail the original Firebase operation

## 🧪 Testing the Sync

### Test User Sign-up Sync

1. Create a new user in your app
2. Check Firebase Functions logs:
   ```bash
   firebase functions:log --only onUserCreate
   ```
3. Verify in Supabase:
   ```sql
   SELECT * FROM users 
   WHERE firebase_uid = 'your-firebase-uid'
   ORDER BY created_at DESC;
   ```

### Test Chat Room Sync

1. Create a chat room in your app
2. Check Firebase Functions logs:
   ```bash
   firebase functions:log --only onChatRoomCreated
   ```
3. Verify in Supabase:
   ```sql
   SELECT * FROM chat_rooms 
   WHERE metadata->>'firestore_room_id' = 'your-firestore-room-id'
   ORDER BY created_at DESC;
   ```

### Test Chat Message Sync

1. Send a message in your app
2. Check Firebase Functions logs:
   ```bash
   firebase functions:log --only onChatMessageCreatedSubcollection
   # or
   firebase functions:log --only onChatMessageCreatedTopLevel
   ```
3. Verify in Supabase:
   ```sql
   SELECT * FROM chat_messages 
   WHERE metadata->>'firestore_message_id' = 'your-firestore-message-id'
   ORDER BY created_at DESC;
   ```

## 🐛 Troubleshooting

### Issue: Functions Not Triggering

**Check:**
1. Functions are deployed: `firebase functions:list`
2. Functions have correct triggers configured
3. Firestore security rules allow the operations

### Issue: Supabase Sync Failing

**Check:**
1. Service role key is correctly configured
2. Supabase URL is correct
3. Check Firebase Functions logs for errors:
   ```bash
   firebase functions:log
   ```
4. Verify Supabase table schemas match expected format
5. Check RLS policies (service role key bypasses RLS, but verify table structure)

### Issue: User ID Mapping Fails

**Symptoms**: Chat rooms/messages sync but with NULL user IDs

**Solution**: 
- Ensure users are synced to Supabase first (via `onUserCreate`)
- Check that `firebase_uid` column exists and is populated in `users` table

### Issue: Duplicate Records

**Solution**: 
- Functions check for existing records before inserting
- If duplicates occur, check the unique constraints in Supabase schema

## 📊 Monitoring

### View Function Logs

```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only onUserCreate

# Real-time logs
firebase functions:log --follow
```

### Check Supabase Logs

1. Go to Supabase Dashboard → **Logs** → **Postgres Logs**
2. Filter for errors or specific table operations

## 🔐 Security Notes

1. **Service Role Key**: 
   - Has admin privileges
   - Bypasses Row Level Security (RLS)
   - Never expose in client-side code
   - Only use in server-side Firebase Functions

2. **RLS Policies**: 
   - Service role key bypasses RLS
   - Ensure your Supabase RLS policies are correctly configured for client access
   - Functions use service role for admin operations

3. **Error Handling**: 
   - Sync failures don't block Firebase operations
   - Errors are logged for debugging
   - Failed syncs can be retried manually if needed

## ✅ Verification Checklist

- [ ] Supabase service role key configured in Firebase Functions
- [ ] Supabase URL configured
- [ ] Dependencies installed (`npm install` in `backend/functions/`)
- [ ] Functions deployed (`firebase deploy --only functions`)
- [ ] Test user sign-up sync works
- [ ] Test chat room sync works
- [ ] Test chat message sync works
- [ ] Check Firebase Functions logs for errors
- [ ] Verify data appears in Supabase tables

## 🎯 Next Steps

After setup is complete:

1. **Monitor**: Watch Firebase Functions logs for the first few days
2. **Verify**: Spot-check data in Supabase matches Firestore
3. **Optimize**: Adjust sync logic if needed based on usage patterns
4. **Scale**: Functions automatically scale with your usage

---

**Need Help?** Check the Firebase Functions logs first, then verify your Supabase configuration matches this guide.





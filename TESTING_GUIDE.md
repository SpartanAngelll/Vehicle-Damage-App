# Testing Guide - Firebase + Supabase Integration

## ⚠️ CRITICAL SETUP REQUIRED BEFORE TESTING

### 1. Supabase JWT Configuration
Supabase needs to be configured to accept Firebase JWT tokens:

1. Go to Supabase Dashboard → Settings → API
2. Find "JWT Settings" section
3. Set JWT Secret to your Firebase project's JWT secret:
   - Firebase Console → Project Settings → Service Accounts
   - Copy the private key and use it as JWT secret
4. OR use a custom JWT verifier function (see `database/supabase_jwt_config.sql`)

### 2. Database Setup Order
Run these SQL files in Supabase SQL Editor in this exact order:

```sql
1. database/complete_schema_supabase.sql
2. database/firebase_uid_migration.sql  
3. database/rls_policies_firebase.sql
4. database/workflow_functions.sql
5. database/setup_complete.sql (verification)
```

### 3. Initialize Services in main.dart
Add Supabase initialization to `lib/main.dart`:

```dart
Future<void> _initializeApp() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ADD THIS:
  await FirebaseSupabaseService.instance.initialize(
    supabaseUrl: 'YOUR_SUPABASE_URL',
    supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // ... rest of initialization
}
```

### 4. Update Firestore Rules
Deploy `firebase/firestore.rules` to Firebase:
```bash
firebase deploy --only firestore:rules
```

---

## 🧪 TESTING CHECKLIST

### Phase 1: Authentication & User Setup

#### Test 1.1: Firebase Sign Up
- [ ] Create new user account with email/password
- [ ] Verify user created in Firebase Auth
- [ ] Verify user record created in Supabase `users` table
- [ ] Check `firebase_uid` matches Firebase UID
- [ ] Verify RLS allows user to read own profile

**Expected Result:**
```dart
final auth = FirebaseAuthServiceWrapper.instance;
final user = await auth.signUpWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
  fullName: 'Test User',
  role: 'owner',
);
// User should exist in both Firebase and Supabase
```

#### Test 1.2: Firebase Sign In
- [ ] Sign in with existing credentials
- [ ] Verify Supabase session refreshed
- [ ] Check Firebase token passed to Supabase headers
- [ ] Verify user can query own data

**Expected Result:**
```dart
final auth = FirebaseAuthServiceWrapper.instance;
final user = await auth.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);
// Should successfully authenticate and sync to Supabase
```

#### Test 1.3: User Profile Sync
- [ ] Update profile in Firebase
- [ ] Verify changes sync to Supabase `users` table
- [ ] Check RLS prevents accessing other users' data

---

### Phase 2: Job Request Workflow

#### Test 2.1: Create Job Request
```dart
final workflow = SupabaseWorkflowService.instance;
final requestId = await workflow.createJobRequest(
  customerId: currentUserId,
  serviceCategoryId: 'category-uuid',
  title: 'Fix car door',
  description: 'Door dent needs repair',
  location: '123 Main St',
  budgetMin: 100.0,
  budgetMax: 500.0,
);
```

**Verify:**
- [ ] Job request created in `job_requests` table
- [ ] `customer_id` matches Firebase UID
- [ ] Status is 'pending'
- [ ] RLS allows customer to view own requests

#### Test 2.2: Professional Views Job Requests
- [ ] Professional can see pending job requests
- [ ] RLS allows read access to active requests
- [ ] Professional cannot see completed/cancelled requests

#### Test 2.3: Create Estimate
```dart
// Professional creates estimate
final estimateId = await _supabase.insert(
  table: 'estimates',
  data: {
    'job_request_id': requestId,
    'professional_id': professionalId,
    'title': 'Door Repair',
    'price': 350.0,
    'status': 'pending',
  },
);
```

**Verify:**
- [ ] Estimate created with correct `professional_id`
- [ ] Customer can view estimate for their request
- [ ] RLS enforces proper access

---

### Phase 3: Booking Workflow

#### Test 3.1: Accept Request (Creates Booking + Chat)
```dart
final bookingId = await workflow.acceptRequest(
  estimateId: estimateId,
  customerId: currentUserId,
);
```

**Verify:**
- [ ] Booking created in `bookings` table
- [ ] Estimate status updated to 'accepted'
- [ ] Job request status updated to 'in_progress'
- [ ] Chat room created in Firestore
- [ ] `chat_room_id` stored in booking record
- [ ] Both customer and professional can access booking

#### Test 3.2: Complete Job
```dart
await workflow.completeJob(
  bookingId: bookingId,
  professionalId: professionalId,
  notes: 'Job completed successfully',
);
```

**Verify:**
- [ ] Booking status updated to 'completed'
- [ ] `job_completed_at` timestamp set
- [ ] Only professional can complete their own jobs
- [ ] RLS prevents unauthorized updates

---

### Phase 4: Payment Workflow

#### Test 4.1: Record Payment
```dart
await workflow.recordPayment(
  bookingId: bookingId,
  type: 'full',
  amount: 350.0,
  currency: 'JMD',
  paymentMethod: 'cash',
);
```

**Verify:**
- [ ] Payment record created in `payment_records`
- [ ] Professional balance updated
- [ ] `available_balance` increased
- [ ] `total_earned` increased
- [ ] Both parties can view payment records

#### Test 4.2: View Professional Balance
```dart
final balance = await _supabase.query(
  table: 'professional_balances',
  filters: {'professional_id': professionalId},
);
```

**Verify:**
- [ ] Professional can view own balance
- [ ] Balance shows correct amounts
- [ ] RLS prevents viewing other professionals' balances

---

### Phase 5: Review System

#### Test 5.1: Leave Review
```dart
await workflow.leaveReview(
  bookingId: bookingId,
  reviewerId: customerId,
  rating: 5,
  title: 'Great service!',
  comment: 'Very professional',
);
```

**Verify:**
- [ ] Review created in `reviews` table
- [ ] Professional's average rating updated
- [ ] `total_reviews` count updated
- [ ] Booking status updated to 'reviewed'
- [ ] Only booking participants can leave reviews

---

### Phase 6: Chat System (Firestore)

#### Test 6.1: Chat Room Creation
- [ ] Verify chat room auto-created when booking accepted
- [ ] Check Firestore rules allow access
- [ ] Both participants can access room

#### Test 6.2: Send Message
```dart
final chat = FirebaseChatService.instance;
await chat.sendMessage(
  roomId: chatRoomId,
  text: 'Hello, when can you start?',
);
```

**Verify:**
- [ ] Message saved in Firestore
- [ ] `lastMessage` updated in chat room
- [ ] Only room participants can send messages
- [ ] Firestore rules enforce security

#### Test 6.3: Real-time Message Updates
```dart
chat.getMessagesStream(roomId).listen((snapshot) {
  // Should receive real-time updates
});
```

**Verify:**
- [ ] Real-time updates work
- [ ] Messages appear instantly
- [ ] Read receipts update correctly

---

### Phase 7: RLS Policy Testing

#### Test 7.1: Unauthorized Access
- [ ] Try to access another user's bookings (should fail)
- [ ] Try to update another user's profile (should fail)
- [ ] Try to view other professionals' balances (should fail)

#### Test 7.2: Authorized Access
- [ ] User can read own data
- [ ] User can update own profile
- [ ] Professional can view own bookings
- [ ] Customer can view own bookings

---

### Phase 8: Error Handling

#### Test 8.1: Network Errors
- [ ] Handle offline scenarios
- [ ] Retry failed requests
- [ ] Show appropriate error messages

#### Test 8.2: Invalid Data
- [ ] Reject invalid booking IDs
- [ ] Validate required fields
- [ ] Handle missing relationships

---

## 🔍 DEBUGGING TIPS

### Check Supabase Connection
```dart
final supabase = FirebaseSupabaseService.instance;
print('Supabase initialized: ${supabase.client != null}');
print('Current UID: ${supabase.currentFirebaseUid}');
```

### Check RLS Policies
```sql
-- In Supabase SQL Editor
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

### Check Firebase Token
```dart
final token = await FirebaseSupabaseService.instance.getFirebaseIdToken();
print('Token: ${token?.substring(0, 50)}...');
```

### View Supabase Logs
- Go to Supabase Dashboard → Logs → API Logs
- Check for authentication errors
- Verify JWT token format

---

## ✅ READINESS CHECKLIST

Before launching, ensure:

- [ ] All SQL migrations run successfully
- [ ] RLS policies tested and working
- [ ] Firebase authentication working
- [ ] Supabase connection established
- [ ] Firestore rules deployed
- [ ] Chat system functional
- [ ] Booking workflow end-to-end tested
- [ ] Payment recording works
- [ ] Review system functional
- [ ] Error handling implemented
- [ ] Security policies enforced
- [ ] Performance acceptable

---

## 🚨 COMMON ISSUES

### Issue: "JWT expired" or "Invalid token"
**Solution:** Ensure Supabase JWT secret matches Firebase project

### Issue: "RLS policy violation"
**Solution:** Check `auth.firebase_uid()` function works correctly

### Issue: "Chat room not created"
**Solution:** Verify Firestore rules allow creation

### Issue: "Cannot read own data"
**Solution:** Check RLS policies use correct Firebase UID comparison


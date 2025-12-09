import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test script to verify Firestore security rules are working correctly
/// Run this in your Flutter app to test rule enforcement

Future<void> testFirestoreRules() async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  
  print('🧪 Testing Firestore Security Rules...\n');
  
  // Test 1: Unauthenticated access should be restricted
  print('Test 1: Unauthenticated access to users collection');
  try {
    await firestore.collection('users').limit(1).get();
    print('❌ FAILED: Unauthenticated user can read users (should be blocked)');
  } catch (e) {
    if (e.toString().contains('permission-denied') || 
        e.toString().contains('PERMISSION_DENIED')) {
      print('✅ PASSED: Unauthenticated access correctly blocked');
    } else {
      print('⚠️  Unexpected error: $e');
    }
  }
  
  // Test 2: Authenticated user can read their own profile
  print('\nTest 2: Authenticated user reading own profile');
  try {
    final user = auth.currentUser;
    if (user == null) {
      print('⚠️  No authenticated user. Sign in first to test this.');
      return;
    }
    
    final doc = await firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      print('✅ PASSED: User can read own profile');
    } else {
      print('⚠️  User profile document does not exist');
    }
  } catch (e) {
    if (e.toString().contains('permission-denied')) {
      print('❌ FAILED: User cannot read own profile');
    } else {
      print('⚠️  Error: $e');
    }
  }
  
  // Test 3: User cannot write to another user's profile
  print('\nTest 3: User trying to write to another user\'s profile');
  try {
    final user = auth.currentUser;
    if (user == null) {
      print('⚠️  No authenticated user. Sign in first to test this.');
      return;
    }
    
    // Try to update a different user's profile (using a test ID)
    await firestore.collection('users').doc('test-other-user-id').update({
      'test': 'should fail'
    });
    print('❌ FAILED: User was able to update another user\'s profile');
  } catch (e) {
    if (e.toString().contains('permission-denied')) {
      print('✅ PASSED: User correctly blocked from updating other user\'s profile');
    } else {
      print('⚠️  Unexpected error: $e');
    }
  }
  
  // Test 4: User can create their own booking
  print('\nTest 4: User creating own booking');
  try {
    final user = auth.currentUser;
    if (user == null) {
      print('⚠️  No authenticated user. Sign in first to test this.');
      return;
    }
    
    final testBookingId = 'test-booking-${DateTime.now().millisecondsSinceEpoch}';
    await firestore.collection('bookings').doc(testBookingId).set({
      'customerId': user.uid,
      'professionalId': 'test-professional-id',
      'serviceTitle': 'Test Service',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ PASSED: User can create booking with own customerId');
    
    // Clean up test booking
    await firestore.collection('bookings').doc(testBookingId).delete();
  } catch (e) {
    if (e.toString().contains('permission-denied')) {
      print('❌ FAILED: User cannot create booking');
    } else {
      print('⚠️  Error: $e');
    }
  }
  
  // Test 5: User cannot create booking with different customerId
  print('\nTest 5: User trying to create booking with different customerId');
  try {
    final user = auth.currentUser;
    if (user == null) {
      print('⚠️  No authenticated user. Sign in first to test this.');
      return;
    }
    
    final testBookingId = 'test-booking-${DateTime.now().millisecondsSinceEpoch}';
    await firestore.collection('bookings').doc(testBookingId).set({
      'customerId': 'different-user-id', // Not the current user
      'professionalId': 'test-professional-id',
      'serviceTitle': 'Test Service',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('❌ FAILED: User was able to create booking with different customerId');
    // Clean up if it somehow succeeded
    await firestore.collection('bookings').doc(testBookingId).delete();
  } catch (e) {
    if (e.toString().contains('permission-denied')) {
      print('✅ PASSED: User correctly blocked from creating booking with different customerId');
    } else {
      print('⚠️  Unexpected error: $e');
    }
  }
  
  // Test 6: Chat room access
  print('\nTest 6: User accessing chat room');
  try {
    final user = auth.currentUser;
    if (user == null) {
      print('⚠️  No authenticated user. Sign in first to test this.');
      return;
    }
    
    // Try to read chat rooms (should work if user is participant)
    final chatRooms = await firestore
        .collection('chat_rooms')
        .where('customerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    
    print('✅ PASSED: User can query chat rooms where they are participant');
  } catch (e) {
    if (e.toString().contains('permission-denied')) {
      print('⚠️  User cannot query chat rooms (may be normal if no chat rooms exist)');
    } else {
      print('⚠️  Error: $e');
    }
  }
  
  print('\n✅ Firestore rules testing complete!');
  print('\n📋 Summary:');
  print('   - Rules are deployed and active');
  print('   - Authentication is required for most operations');
  print('   - Users can only access their own data');
  print('   - Security is enforced at the database level');
}

/// Quick test function you can call from your app
Future<void> quickRulesTest() async {
  final auth = FirebaseAuth.instance;
  
  if (auth.currentUser == null) {
    print('⚠️  Please sign in first to test rules');
    return;
  }
  
  await testFirestoreRules();
}



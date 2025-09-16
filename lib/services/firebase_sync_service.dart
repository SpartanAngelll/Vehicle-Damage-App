import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payout_models.dart';
import 'payout_service.dart';

class FirebaseSyncService {
  static FirebaseSyncService? _instance;
  final FirebaseFirestore _firestore;
  final PayoutService _payoutService;

  FirebaseSyncService._()
      : _firestore = FirebaseFirestore.instance,
        _payoutService = PayoutService.instance;

  static FirebaseSyncService get instance {
    _instance ??= FirebaseSyncService._();
    return _instance!;
  }

  /// Sync payout to Firebase
  Future<void> syncPayoutToFirebase(Payout payout) async {
    try {
      await _firestore
          .collection('payouts')
          .doc(payout.id)
          .set(payout.toFirestoreMap());
      
      print('✅ [FirebaseSync] Synced payout to Firebase: ${payout.id}');
    } catch (e) {
      print('❌ [FirebaseSync] Failed to sync payout to Firebase: $e');
    }
  }

  /// Sync professional balance to Firebase
  Future<void> syncProfessionalBalanceToFirebase(ProfessionalBalance balance) async {
    try {
      await _firestore
          .collection('professional_balances')
          .doc(balance.professionalId)
          .set(balance.toFirestoreMap());
      
      print('✅ [FirebaseSync] Synced professional balance to Firebase: ${balance.professionalId}');
    } catch (e) {
      print('❌ [FirebaseSync] Failed to sync professional balance to Firebase: $e');
    }
  }

  /// Sync payout status update to Firebase
  Future<void> syncPayoutStatusUpdate({
    required String payoutId,
    required PayoutStatus status,
    String? errorMessage,
    String? transactionId,
    Map<String, dynamic>? processorResponse,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      if (transactionId != null) {
        updateData['paymentProcessorTransactionId'] = transactionId;
      }

      if (processorResponse != null) {
        updateData['paymentProcessorResponse'] = processorResponse;
      }

      if (status != PayoutStatus.pending) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('payouts')
          .doc(payoutId)
          .update(updateData);
      
      print('✅ [FirebaseSync] Synced payout status update to Firebase: $payoutId -> ${status.name}');
    } catch (e) {
      print('❌ [FirebaseSync] Failed to sync payout status update to Firebase: $e');
    }
  }

  /// Sync professional balance update to Firebase
  Future<void> syncProfessionalBalanceUpdate({
    required String professionalId,
    required double availableBalance,
    required double totalEarned,
    required double totalPaidOut,
  }) async {
    try {
      await _firestore
          .collection('professional_balances')
          .doc(professionalId)
          .update({
        'availableBalance': availableBalance,
        'totalEarned': totalEarned,
        'totalPaidOut': totalPaidOut,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ [FirebaseSync] Synced professional balance update to Firebase: $professionalId');
    } catch (e) {
      print('❌ [FirebaseSync] Failed to sync professional balance update to Firebase: $e');
    }
  }

  /// Get payout stream for real-time updates
  Stream<List<Payout>> getPayoutsStream(String professionalId) {
    return _firestore
        .collection('payouts')
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payout.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get professional balance stream for real-time updates
  Stream<ProfessionalBalance?> getProfessionalBalanceStream(String professionalId) {
    return _firestore
        .collection('professional_balances')
        .doc(professionalId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return ProfessionalBalance.fromFirestore(snapshot.data()!, snapshot.id);
        });
  }

  /// Get payout by ID from Firebase
  Future<Payout?> getPayoutFromFirebase(String payoutId) async {
    try {
      final doc = await _firestore
          .collection('payouts')
          .doc(payoutId)
          .get();

      if (!doc.exists) return null;

      return Payout.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ [FirebaseSync] Failed to get payout from Firebase: $e');
      return null;
    }
  }

  /// Get professional balance from Firebase
  Future<ProfessionalBalance?> getProfessionalBalanceFromFirebase(String professionalId) async {
    try {
      final doc = await _firestore
          .collection('professional_balances')
          .doc(professionalId)
          .get();

      if (!doc.exists) return null;

      return ProfessionalBalance.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ [FirebaseSync] Failed to get professional balance from Firebase: $e');
      return null;
    }
  }

  /// Sync all payouts for a professional to Firebase
  Future<void> syncAllPayoutsToFirebase(String professionalId) async {
    try {
      final payouts = await _payoutService.getPayoutHistory(professionalId);
      
      final batch = _firestore.batch();
      
      for (final payout in payouts) {
        final docRef = _firestore.collection('payouts').doc(payout.id);
        batch.set(docRef, payout.toFirestoreMap());
      }
      
      await batch.commit();
      
      print('✅ [FirebaseSync] Synced all payouts to Firebase for professional: $professionalId');
    } catch (e) {
      print('❌ [FirebaseSync] Failed to sync all payouts to Firebase: $e');
    }
  }

  /// Sync professional balance to Firebase by ID
  Future<void> syncProfessionalBalanceToFirebaseById(String professionalId) async {
    try {
      final balance = await _payoutService.getProfessionalBalance(professionalId);
      if (balance != null) {
        await syncProfessionalBalanceToFirebase(balance);
      }
    } catch (e) {
      print('❌ [FirebaseSync] Failed to sync professional balance to Firebase: $e');
    }
  }

  /// Initialize Firebase collections with proper indexes
  Future<void> initializeFirebaseCollections() async {
    try {
      // Create payout document with initial data to ensure collection exists
      await _firestore
          .collection('payouts')
          .doc('_initialization')
          .set({
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create professional_balances document with initial data
      await _firestore
          .collection('professional_balances')
          .doc('_initialization')
          .set({
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ [FirebaseSync] Firebase collections initialized');
    } catch (e) {
      print('❌ [FirebaseSync] Failed to initialize Firebase collections: $e');
    }
  }

  /// Clean up initialization documents
  Future<void> cleanupInitializationDocuments() async {
    try {
      await _firestore
          .collection('payouts')
          .doc('_initialization')
          .delete();

      await _firestore
          .collection('professional_balances')
          .doc('_initialization')
          .delete();

      print('✅ [FirebaseSync] Cleaned up initialization documents');
    } catch (e) {
      print('❌ [FirebaseSync] Failed to cleanup initialization documents: $e');
    }
  }

  /// Get payout statistics from Firebase
  Future<Map<String, dynamic>> getPayoutStatsFromFirebase(String professionalId) async {
    try {
      final payoutsSnapshot = await _firestore
          .collection('payouts')
          .where('professionalId', isEqualTo: professionalId)
          .get();

      final payouts = payoutsSnapshot.docs
          .map((doc) => Payout.fromFirestore(doc.data(), doc.id))
          .toList();

      final pendingCount = payouts.where((p) => p.isPending).length;
      final successCount = payouts.where((p) => p.isSuccess).length;
      final failedCount = payouts.where((p) => p.isFailed).length;

      return {
        'totalPayouts': payouts.length,
        'pendingPayouts': pendingCount,
        'successPayouts': successCount,
        'failedPayouts': failedCount,
        'successRate': payouts.isNotEmpty ? successCount / payouts.length : 0.0,
      };
    } catch (e) {
      print('❌ [FirebaseSync] Failed to get payout stats from Firebase: $e');
      return {
        'totalPayouts': 0,
        'pendingPayouts': 0,
        'successPayouts': 0,
        'failedPayouts': 0,
        'successRate': 0.0,
      };
    }
  }

  /// Listen for payout updates and sync to Postgres
  void startPayoutSyncListener(String professionalId) {
    _firestore
        .collection('payouts')
        .where('professionalId', isEqualTo: professionalId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || 
            change.type == DocumentChangeType.modified) {
          final payout = Payout.fromFirestore(change.doc.data()!, change.doc.id);
          print('📡 [FirebaseSync] Payout update received: ${payout.id} - ${payout.status}');
          
          // Here you could sync back to Postgres if needed
          // This is useful for maintaining data consistency
        }
      }
    });
  }

  /// Listen for balance updates and sync to Postgres
  void startBalanceSyncListener(String professionalId) {
    _firestore
        .collection('professional_balances')
        .doc(professionalId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final balance = ProfessionalBalance.fromFirestore(snapshot.data()!, snapshot.id);
        print('📡 [FirebaseSync] Balance update received: ${balance.professionalId} - \$${balance.availableBalance}');
        
        // Here you could sync back to Postgres if needed
        // This is useful for maintaining data consistency
      }
    });
  }
}

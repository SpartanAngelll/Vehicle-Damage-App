import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banking_details.dart';

class BankingDetailsService {
  static BankingDetailsService? _instance;
  final FirebaseFirestore _firestore;

  BankingDetailsService._() : _firestore = FirebaseFirestore.instance;

  static BankingDetailsService get instance {
    _instance ??= BankingDetailsService._();
    return _instance!;
  }

  // Collection reference
  CollectionReference get _bankingDetailsCollection => 
    _firestore.collection('banking_details');

  /// Save banking details for a service professional
  Future<String> saveBankingDetails(BankingDetails bankingDetails) async {
    try {
      print('🔍 [BankingDetailsService] Saving banking details for professional: ${bankingDetails.professionalId}');
      
      // Check if banking details already exist for this professional
      final existingQuery = await _bankingDetailsCollection
          .where('professionalId', isEqualTo: bankingDetails.professionalId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing banking details
        final docId = existingQuery.docs.first.id;
        await _bankingDetailsCollection.doc(docId).update(bankingDetails.toMap());
        print('✅ [BankingDetailsService] Banking details updated: $docId');
        return docId;
      } else {
        // Create new banking details
        final docRef = await _bankingDetailsCollection.add(bankingDetails.toMap());
        print('✅ [BankingDetailsService] Banking details created: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      print('❌ [BankingDetailsService] Error saving banking details: $e');
      rethrow;
    }
  }

  /// Get banking details for a service professional
  Future<BankingDetails?> getBankingDetails(String professionalId) async {
    try {
      print('🔍 [BankingDetailsService] Getting banking details for professional: $professionalId');
      
      final querySnapshot = await _bankingDetailsCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ [BankingDetailsService] No banking details found for professional: $professionalId');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final bankingDetails = BankingDetails.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      print('✅ [BankingDetailsService] Banking details retrieved: ${bankingDetails.id}');
      return bankingDetails;
    } catch (e) {
      print('❌ [BankingDetailsService] Error getting banking details: $e');
      rethrow;
    }
  }

  /// Update banking details
  Future<void> updateBankingDetails(String bankingDetailsId, BankingDetails bankingDetails) async {
    try {
      print('🔍 [BankingDetailsService] Updating banking details: $bankingDetailsId');
      
      await _bankingDetailsCollection.doc(bankingDetailsId).update(bankingDetails.toMap());
      print('✅ [BankingDetailsService] Banking details updated successfully');
    } catch (e) {
      print('❌ [BankingDetailsService] Error updating banking details: $e');
      rethrow;
    }
  }

  /// Deactivate banking details (soft delete)
  Future<void> deactivateBankingDetails(String bankingDetailsId) async {
    try {
      print('🔍 [BankingDetailsService] Deactivating banking details: $bankingDetailsId');
      
      await _bankingDetailsCollection.doc(bankingDetailsId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [BankingDetailsService] Banking details deactivated successfully');
    } catch (e) {
      print('❌ [BankingDetailsService] Error deactivating banking details: $e');
      rethrow;
    }
  }

  /// Get all banking details for a professional (including inactive)
  Future<List<BankingDetails>> getAllBankingDetails(String professionalId) async {
    try {
      print('🔍 [BankingDetailsService] Getting all banking details for professional: $professionalId');
      
      final querySnapshot = await _bankingDetailsCollection
          .where('professionalId', isEqualTo: professionalId)
          .orderBy('createdAt', descending: true)
          .get();

      final bankingDetailsList = querySnapshot.docs.map((doc) {
        return BankingDetails.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      print('✅ [BankingDetailsService] Retrieved ${bankingDetailsList.length} banking details');
      return bankingDetailsList;
    } catch (e) {
      print('❌ [BankingDetailsService] Error getting all banking details: $e');
      rethrow;
    }
  }

  /// Check if professional has banking details
  Future<bool> hasBankingDetails(String professionalId) async {
    try {
      final bankingDetails = await getBankingDetails(professionalId);
      return bankingDetails != null;
    } catch (e) {
      print('❌ [BankingDetailsService] Error checking banking details: $e');
      return false;
    }
  }

  /// Validate banking details before saving
  BankingDetailsValidationResult validateBankingDetails(BankingDetails bankingDetails) {
    final errors = <String, String>{};
    
    final bankNameError = BankingDetails.validateBankName(bankingDetails.bankName);
    if (bankNameError != null) errors['bankName'] = bankNameError;
    
    final accountNumberError = BankingDetails.validateAccountNumber(bankingDetails.accountNumber);
    if (accountNumberError != null) errors['accountNumber'] = accountNumberError;
    
    final accountHolderNameError = BankingDetails.validateAccountHolderName(bankingDetails.accountHolderName);
    if (accountHolderNameError != null) errors['accountHolderName'] = accountHolderNameError;
    
    final routingNumberError = BankingDetails.validateRoutingNumber(bankingDetails.routingNumber);
    if (routingNumberError != null) errors['routingNumber'] = routingNumberError;
    
    final swiftCodeError = BankingDetails.validateSwiftCode(bankingDetails.swiftCode);
    if (swiftCodeError != null) errors['swiftCode'] = swiftCodeError;
    
    final ibanError = BankingDetails.validateIban(bankingDetails.iban);
    if (ibanError != null) errors['iban'] = ibanError;
    
    return BankingDetailsValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      bankingDetails: errors.isEmpty ? bankingDetails : null,
    );
  }

  /// Stream banking details for real-time updates
  Stream<BankingDetails?> streamBankingDetails(String professionalId) {
    return _bankingDetailsCollection
        .where('professionalId', isEqualTo: professionalId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return BankingDetails.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Update last used timestamp for payout tracking
  Future<void> updateLastUsedForPayout(String bankingDetailsId) async {
    try {
      print('🔍 [BankingDetailsService] Updating last used timestamp for: $bankingDetailsId');
      
      await _bankingDetailsCollection.doc(bankingDetailsId).update({
        'lastUsedForPayout': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [BankingDetailsService] Last used timestamp updated');
    } catch (e) {
      print('❌ [BankingDetailsService] Error updating last used timestamp: $e');
      rethrow;
    }
  }

  /// Get banking details by ID
  Future<BankingDetails?> getBankingDetailsById(String bankingDetailsId) async {
    try {
      print('🔍 [BankingDetailsService] Getting banking details by ID: $bankingDetailsId');
      
      final doc = await _bankingDetailsCollection.doc(bankingDetailsId).get();
      
      if (!doc.exists) {
        print('ℹ️ [BankingDetailsService] Banking details not found: $bankingDetailsId');
        return null;
      }

      final bankingDetails = BankingDetails.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      print('✅ [BankingDetailsService] Banking details retrieved: ${bankingDetails.id}');
      return bankingDetails;
    } catch (e) {
      print('❌ [BankingDetailsService] Error getting banking details by ID: $e');
      rethrow;
    }
  }
}

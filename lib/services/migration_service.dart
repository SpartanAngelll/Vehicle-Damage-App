import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_category.dart';
import '../models/service_professional.dart';
import '../models/job_request.dart';
import 'service_category_service.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ServiceCategoryService _categoryService = ServiceCategoryService();

  // Migrate existing damage reports to job requests
  Future<void> migrateDamageReportsToJobRequests() async {
    try {
      // First, ensure default categories exist
      await _categoryService.seedDefaultCategories();

      // Get all existing damage reports
      final damageReportsSnapshot = await _firestore
          .collection('damage_reports')
          .get();

      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final doc in damageReportsSnapshot.docs) {
        final damageReport = doc.data();
        
        // Convert to job request
        final jobRequest = JobRequest.fromDamageReport(damageReport);
        
        // Create new job request document
        final jobRequestRef = _firestore
            .collection('job_requests')
            .doc(jobRequest.id);
        
        batch.set(jobRequestRef, jobRequest.toMap());
        
        // Mark damage report as migrated
        final damageReportRef = _firestore
            .collection('damage_reports')
            .doc(doc.id);
        
        batch.update(damageReportRef, {
          'migratedToJobRequest': true,
          'migratedAt': FieldValue.serverTimestamp(),
          'jobRequestId': jobRequest.id,
        });

        migratedCount++;
      }

      await batch.commit();
      print('Successfully migrated $migratedCount damage reports to job requests');
    } catch (e) {
      throw Exception('Failed to migrate damage reports: $e');
    }
  }

  // Migrate existing repair professionals to service professionals
  Future<void> migrateRepairProfessionalsToServiceProfessionals() async {
    try {
      // Get all existing users with repairman role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('userType', whereIn: ['repairman', 'mechanic'])
          .get();

      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        
        // Convert to service professional
        final serviceProfessional = ServiceProfessional.fromRepairmanData(userData);
        
        // Create new service professional document
        final professionalRef = _firestore
            .collection('professionals')
            .doc(serviceProfessional.id);
        
        batch.set(professionalRef, serviceProfessional.toMap());
        
        // Update user document to mark as migrated
        final userRef = _firestore
            .collection('users')
            .doc(doc.id);
        
        batch.update(userRef, {
          'migratedToServiceProfessional': true,
          'migratedAt': FieldValue.serverTimestamp(),
          'serviceProfessionalId': serviceProfessional.id,
        });

        migratedCount++;
      }

      await batch.commit();
      print('Successfully migrated $migratedCount repair professionals to service professionals');
    } catch (e) {
      throw Exception('Failed to migrate repair professionals: $e');
    }
  }

  // Migrate existing estimates to support both systems
  Future<void> migrateEstimatesToSupportJobRequests() async {
    try {
      // Get all existing estimates
      final estimatesSnapshot = await _firestore
          .collection('estimates')
          .get();

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in estimatesSnapshot.docs) {
        final estimateData = doc.data();
        
        // Check if this estimate is for a migrated job request
        if (estimateData['reportId'] != null) {
          // Find the corresponding job request
          final jobRequestSnapshot = await _firestore
              .collection('job_requests')
              .where('customFields.vehicleMake', isEqualTo: estimateData['vehicleMake'])
              .where('customFields.vehicleModel', isEqualTo: estimateData['vehicleModel'])
              .limit(1)
              .get();

          if (jobRequestSnapshot.docs.isNotEmpty) {
            final jobRequestId = jobRequestSnapshot.docs.first.id;
            
            // Update estimate to include job request ID
            final estimateRef = _firestore
                .collection('estimates')
                .doc(doc.id);
            
            batch.update(estimateRef, {
              'jobRequestId': jobRequestId,
              'migrated': true,
              'migratedAt': FieldValue.serverTimestamp(),
            });

            updatedCount++;
          }
        }
      }

      await batch.commit();
      print('Successfully updated $updatedCount estimates to support job requests');
    } catch (e) {
      throw Exception('Failed to migrate estimates: $e');
    }
  }

  // Check migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final status = <String, dynamic>{};

      // Check damage reports migration
      final damageReportsCount = await _firestore
          .collection('damage_reports')
          .count()
          .get();

      final migratedDamageReportsCount = await _firestore
          .collection('damage_reports')
          .where('migratedToJobRequest', isEqualTo: true)
          .count()
          .get();

      status['damageReports'] = {
        'total': damageReportsCount.count ?? 0,
        'migrated': migratedDamageReportsCount.count ?? 0,
        'pending': (damageReportsCount.count ?? 0) - (migratedDamageReportsCount.count ?? 0),
      };

      // Check professionals migration
      final professionalsCount = await _firestore
          .collection('users')
          .where('userType', whereIn: ['repairman', 'mechanic'])
          .count()
          .get();

      final migratedProfessionalsCount = await _firestore
          .collection('users')
          .where('migratedToServiceProfessional', isEqualTo: true)
          .count()
          .get();

      status['professionals'] = {
        'total': professionalsCount.count ?? 0,
        'migrated': migratedProfessionalsCount.count ?? 0,
        'pending': (professionalsCount.count ?? 0) - (migratedProfessionalsCount.count ?? 0),
      };

      // Check service categories
      final categoriesCount = await _firestore
          .collection('service_categories')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      status['serviceCategories'] = {
        'total': categoriesCount.count ?? 0,
      };

      return status;
    } catch (e) {
      throw Exception('Failed to get migration status: $e');
    }
  }

  // Run full migration
  Future<void> runFullMigration() async {
    try {
      print('Starting full migration...');
      
      // Step 1: Seed default categories
      print('Step 1: Seeding default categories...');
      await _categoryService.seedDefaultCategories();
      
      // Step 2: Migrate damage reports
      print('Step 2: Migrating damage reports...');
      await migrateDamageReportsToJobRequests();
      
      // Step 3: Migrate professionals
      print('Step 3: Migrating professionals...');
      await migrateRepairProfessionalsToServiceProfessionals();
      
      // Step 4: Update estimates
      print('Step 4: Updating estimates...');
      await migrateEstimatesToSupportJobRequests();
      
      print('Full migration completed successfully!');
    } catch (e) {
      throw Exception('Full migration failed: $e');
    }
  }
}

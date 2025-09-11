import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_category_service.dart';

class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ServiceCategoryService _categoryService = ServiceCategoryService();

  // Initialize app data
  Future<void> initializeApp() async {
    try {
      print('🔧 [AppInit] Starting app initialization...');
      
      // Check if service categories exist
      await _ensureServiceCategoriesExist();
      
      print('✅ [AppInit] App initialization completed successfully');
    } catch (e) {
      print('❌ [AppInit] App initialization failed: $e');
      // Don't throw - we want the app to continue even if initialization fails
    }
  }

  // Ensure service categories exist
  Future<void> _ensureServiceCategoriesExist() async {
    try {
      print('🔧 [AppInit] Checking service categories...');
      
      // Check if any categories exist
      final categoriesSnapshot = await _firestore
          .collection('service_categories')
          .limit(1)
          .get();

      if (categoriesSnapshot.docs.isEmpty) {
        print('🔧 [AppInit] No service categories found, seeding defaults...');
        await _categoryService.seedDefaultCategories();
        print('✅ [AppInit] Default service categories seeded successfully');
      } else {
        print('✅ [AppInit] Service categories already exist');
      }
    } catch (e) {
      print('❌ [AppInit] Failed to ensure service categories: $e');
      // Try to seed categories anyway
      try {
        await _categoryService.seedDefaultCategories();
        print('✅ [AppInit] Default service categories seeded successfully (fallback)');
      } catch (seedError) {
        print('❌ [AppInit] Failed to seed categories (fallback): $seedError');
      }
    }
  }

  // Check if categories are accessible
  Future<bool> areCategoriesAccessible() async {
    try {
      await _firestore
          .collection('service_categories')
          .limit(1)
          .get();
      return true;
    } catch (e) {
      print('❌ [AppInit] Categories not accessible: $e');
      return false;
    }
  }
}

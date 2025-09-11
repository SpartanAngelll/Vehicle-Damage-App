import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/service_category.dart';

class ServiceCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'service_categories';

  // Get all active service categories
  Future<List<ServiceCategory>> getAllCategories() async {
    try {
      // First get all categories without ordering to avoid composite index requirement
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      // Convert to ServiceCategory objects and sort in memory
      final categories = querySnapshot.docs.map((doc) {
        return ServiceCategory.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by name in memory
      categories.sort((a, b) => a.name.compareTo(b.name));

      return categories;
    } catch (e) {
      throw Exception('Failed to fetch service categories: $e');
    }
  }

  // Get categories by IDs
  Future<List<ServiceCategory>> getCategoriesByIds(List<String> categoryIds) async {
    if (categoryIds.isEmpty) return [];

    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: categoryIds)
          .get();

      return querySnapshot.docs.map((doc) {
        return ServiceCategory.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories by IDs: $e');
    }
  }

  // Get a single category by ID
  Future<ServiceCategory?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return ServiceCategory.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // Create a new service category (admin only)
  Future<String> createCategory(ServiceCategory category) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(category.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create service category: $e');
    }
  }

  // Update an existing service category (admin only)
  Future<void> updateCategory(String categoryId, ServiceCategory category) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(categoryId)
          .update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update service category: $e');
    }
  }

  // Deactivate a service category (admin only)
  Future<void> deactivateCategory(String categoryId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(categoryId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to deactivate service category: $e');
    }
  }

  // Seed default categories for backward compatibility
  Future<void> seedDefaultCategories() async {
    try {
      final defaultCategories = [
        // Original categories
        ServiceCategory(
          id: 'mechanics',
          name: 'Mechanics',
          description: 'Automotive repair and maintenance services',
          icon: Icons.build,
          colorHex: '#FF5722',
        ),
        ServiceCategory(
          id: 'plumbers',
          name: 'Plumbers',
          description: 'Plumbing installation, repair, and maintenance',
          icon: Icons.plumbing,
          colorHex: '#2196F3',
        ),
        ServiceCategory(
          id: 'electricians',
          name: 'Electricians',
          description: 'Electrical installation, repair, and maintenance',
          icon: Icons.electrical_services,
          colorHex: '#FFC107',
        ),
        ServiceCategory(
          id: 'carpenters',
          name: 'Carpenters',
          description: 'Woodworking, construction, and repair services',
          icon: Icons.handyman,
          colorHex: '#795548',
        ),
        ServiceCategory(
          id: 'cleaners',
          name: 'Cleaners',
          description: 'House cleaning and maintenance services',
          icon: Icons.cleaning_services,
          colorHex: '#4CAF50',
        ),
        ServiceCategory(
          id: 'landscapers',
          name: 'Landscapers',
          description: 'Garden and outdoor maintenance services',
          icon: Icons.landscape,
          colorHex: '#8BC34A',
        ),
        ServiceCategory(
          id: 'painters',
          name: 'Painters',
          description: 'Interior and exterior painting services',
          icon: Icons.format_paint,
          colorHex: '#E91E63',
        ),
        ServiceCategory(
          id: 'technicians',
          name: 'Technicians',
          description: 'General repair and technical services',
          icon: Icons.engineering,
          colorHex: '#9C27B0',
        ),
        
        // New appliance and home service categories
        ServiceCategory(
          id: 'appliance_repair',
          name: 'Appliance Repair Technicians',
          description: 'Repair of refrigerators, washing machines, ovens, AC units, etc.',
          icon: Icons.kitchen,
          colorHex: '#009688',
        ),
        ServiceCategory(
          id: 'masons_builders',
          name: 'Masons / Builders',
          description: 'Concrete, bricklaying, tiling, and construction support.',
          icon: Icons.construction,
          colorHex: '#607D8B',
        ),
        ServiceCategory(
          id: 'roofers',
          name: 'Roofers',
          description: 'Roof installation, maintenance, and repairs (tiles, shingles, zinc).',
          icon: Icons.home,
          colorHex: '#3F51B5',
        ),
        ServiceCategory(
          id: 'welders_metalworkers',
          name: 'Welders / Metalworkers',
          description: 'Welding, fabrication, and metal repairs.',
          icon: Icons.hardware,
          colorHex: '#FF7043',
        ),
        ServiceCategory(
          id: 'hvac_specialists',
          name: 'HVAC Specialists',
          description: 'Heating, ventilation, and air conditioning services.',
          icon: Icons.ac_unit,
          colorHex: '#00BCD4',
        ),
        ServiceCategory(
          id: 'it_support',
          name: 'IT Support / Computer Technicians',
          description: 'PC and laptop repair, networking, software support.',
          icon: Icons.computer,
          colorHex: '#455A64',
        ),
        ServiceCategory(
          id: 'pest_control',
          name: 'Pest Control Specialists',
          description: 'Termite, rodent, insect control, fumigation services.',
          icon: Icons.bug_report,
          colorHex: '#CDDC39',
        ),
        ServiceCategory(
          id: 'movers_hauling',
          name: 'Movers & Hauling Services',
          description: 'Furniture moving, junk removal, transport services.',
          icon: Icons.local_shipping,
          colorHex: '#FF9800',
        ),
        ServiceCategory(
          id: 'security_systems',
          name: 'Security System Installers',
          description: 'CCTV, alarms, access control, smart locks.',
          icon: Icons.security,
          colorHex: '#0D47A1',
        ),
        ServiceCategory(
          id: 'glass_windows',
          name: 'Glass & Window Installers',
          description: 'Glass cutting, window and door installation, repairs.',
          icon: Icons.window,
          colorHex: '#03A9F4',
        ),
        
        // Beauty and personal care categories
        ServiceCategory(
          id: 'hairdressers_barbers',
          name: 'Hairdressers / Barbers',
          description: 'Haircuts, styling, coloring, treatments, barbering services.',
          icon: Icons.content_cut,
          colorHex: '#673AB7',
        ),
        ServiceCategory(
          id: 'makeup_artists',
          name: 'Makeup Artists',
          description: 'Professional makeup services for events, weddings, and photoshoots.',
          icon: Icons.face,
          colorHex: '#F06292',
        ),
        ServiceCategory(
          id: 'nail_technicians',
          name: 'Nail Technicians',
          description: 'Manicures, pedicures, acrylics, gels, and nail art.',
          icon: Icons.brush,
          colorHex: '#FF6F61',
        ),
        ServiceCategory(
          id: 'lash_technicians',
          name: 'Lash Technicians',
          description: 'Eyelash extensions, lifts, and tints.',
          icon: Icons.visibility,
          colorHex: '#BA68C8',
        ),
      ];

      final batch = _firestore.batch();
      
      for (final category in defaultCategories) {
        final docRef = _firestore.collection(_collection).doc(category.id);
        batch.set(docRef, category.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to seed default categories: $e');
    }
  }

  // Search categories by name
  Future<List<ServiceCategory>> searchCategories(String query) async {
    try {
      // Get all active categories and filter in memory to avoid complex index requirements
      final allCategories = await getAllCategories();
      
      // Filter categories that contain the query string (case insensitive)
      final filteredCategories = allCategories.where((category) {
        return category.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      return filteredCategories;
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }

  // Get categories with professional count
  Future<Map<String, int>> getCategoryProfessionalCounts() async {
    try {
      final categories = await getAllCategories();
      final counts = <String, int>{};

      for (final category in categories) {
        final professionalCount = await _firestore
            .collection('professionals')
            .where('categoryIds', arrayContains: category.id)
            .where('isAvailable', isEqualTo: true)
            .count()
            .get();

        counts[category.id] = professionalCount.count ?? 0;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get category professional counts: $e');
    }
  }
}

import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String colorHex;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.colorHex,
    this.isActive = true,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': icon.codePoint.toString(),
      'colorHex': colorHex,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Firestore document
  factory ServiceCategory.fromMap(Map<String, dynamic> map, String documentId) {
    return ServiceCategory(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: _getIconFromCodePoint(map['iconName'] ?? '0xe3c9'), // Default to build icon
      colorHex: map['colorHex'] ?? '#2196F3',
      isActive: map['isActive'] ?? true,
      imageUrl: map['imageUrl'] as String?,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Helper method to convert icon code point back to IconData
  static IconData _getIconFromCodePoint(String codePoint) {
    try {
      final int code = int.parse(codePoint);
      return IconData(code, fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.build; // Default fallback
    }
  }

  // Get color from hex string
  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue; // Default fallback
    }
  }

  // Copy with method
  ServiceCategory copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    String? colorHex,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ServiceCategory(id: $id, name: $name, isActive: $isActive)';
  }
}

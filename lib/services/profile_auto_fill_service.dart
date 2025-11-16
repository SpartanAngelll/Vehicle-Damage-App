import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_state.dart';
import '../models/service_professional.dart';

class ProfileAutoFillService {
  /// Auto-fill customer profile data from login information
  static Map<String, dynamic> getCustomerProfileData(UserState userState) {
    return {
      'fullName': userState.fullName,
      'email': userState.email,
      'phoneNumber': userState.phoneNumber,
      'username': userState.username,
      'bio': userState.bio,
      'profilePhotoUrl': userState.profilePhotoUrl,
    };
  }

  /// Auto-fill service professional profile data from login information
  static Map<String, dynamic> getServiceProfessionalProfileData(UserState userState) {
    return {
      'fullName': userState.fullName,
      'email': userState.email,
      'phoneNumber': userState.phoneNumber,
      'bio': userState.bio,
      'profilePhotoUrl': userState.profilePhotoUrl,
      'businessName': userState.businessName,
      'businessAddress': userState.businessAddress,
      'businessPhone': userState.businessPhone,
      'website': userState.website,
      'yearsOfExperience': userState.yearsOfExperience,
      'serviceCategoryIds': userState.serviceCategoryIds,
      'specializations': userState.specializations,
      'certifications': userState.certifications,
      'serviceAreas': userState.serviceAreas,
    };
  }

  /// Get suggested values for empty fields based on available data
  static Map<String, dynamic> getSuggestedValues(UserState userState) {
    final suggestions = <String, dynamic>{};
    
    // Extract name from email if full name is not available
    if (userState.fullName == null && userState.email != null) {
      final emailName = _extractNameFromEmail(userState.email!);
      if (emailName.isNotEmpty) {
        suggestions['suggestedFullName'] = emailName;
      }
    }
    
    // Generate username from email if username is not available
    if (userState.username == null && userState.email != null) {
      suggestions['suggestedUsername'] = _generateUsernameFromEmail(userState.email!);
    }
    
    // Generate business name from full name if available
    if (userState.isServiceProfessional && 
        userState.businessName == null && 
        userState.fullName != null) {
      suggestions['suggestedBusinessName'] = '${userState.fullName}\'s Services';
    }
    
    return suggestions;
  }

  /// Extract a name from email address
  static String _extractNameFromEmail(String email) {
    try {
      final localPart = email.split('@')[0];
      // Remove numbers and special characters, capitalize first letter
      final cleanName = localPart
          .replaceAll(RegExp(r'[0-9._-]'), ' ')
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join(' ');
      return cleanName;
    } catch (e) {
      debugPrint('Error extracting name from email: $e');
      return '';
    }
  }

  /// Generate a username from email address
  static String _generateUsernameFromEmail(String email) {
    try {
      final localPart = email.split('@')[0];
      // Remove special characters and numbers, keep only letters
      final cleanUsername = localPart
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .toLowerCase();
      
      // Ensure username is at least 3 characters
      if (cleanUsername.length >= 3) {
        return cleanUsername;
      } else {
        // If too short, add some characters
        return '${cleanUsername}user';
      }
    } catch (e) {
      debugPrint('Error generating username from email: $e');
      return 'user${DateTime.now().millisecondsSinceEpoch % 1000}';
    }
  }

  /// Check if profile data is complete for the user type
  static Map<String, bool> checkProfileCompleteness(UserState userState) {
    final completeness = <String, bool>{};
    
    if (userState.isOwner) {
      completeness['hasFullName'] = userState.fullName != null && userState.fullName!.isNotEmpty;
      completeness['hasUsername'] = userState.username != null && userState.username!.isNotEmpty;
      completeness['hasProfilePhoto'] = userState.profilePhotoUrl != null;
      completeness['hasBio'] = userState.bio != null && userState.bio!.isNotEmpty;
    } else if (userState.isServiceProfessional) {
      completeness['hasFullName'] = userState.fullName != null && userState.fullName!.isNotEmpty;
      completeness['hasBio'] = userState.bio != null && userState.bio!.isNotEmpty;
      completeness['hasBusinessName'] = userState.businessName != null && userState.businessName!.isNotEmpty;
      completeness['hasServiceCategories'] = userState.serviceCategoryIds.isNotEmpty;
      completeness['hasServiceAreas'] = userState.serviceAreas.isNotEmpty;
      completeness['hasProfilePhoto'] = userState.profilePhotoUrl != null;
    }
    
    return completeness;
  }

  /// Get missing required fields for profile completion
  static List<String> getMissingRequiredFields(UserState userState) {
    final missing = <String>[];
    final completeness = checkProfileCompleteness(userState);
    
    if (userState.isOwner) {
      if (!completeness['hasFullName']!) missing.add('Full Name');
      if (!completeness['hasUsername']!) missing.add('Username');
    } else if (userState.isServiceProfessional) {
      if (!completeness['hasFullName']!) missing.add('Full Name');
      if (!completeness['hasBio']!) missing.add('Bio');
      if (!completeness['hasServiceCategories']!) missing.add('Service Categories');
    }
    
    return missing;
  }

  /// Auto-populate form controllers with available data
  static void populateFormControllers({
    required Map<String, TextEditingController> controllers,
    required UserState userState,
    Map<String, dynamic>? suggestions,
  }) {
    // Basic profile data
    if (userState.fullName != null) {
      controllers['fullName']?.text = userState.fullName!;
    } else if (suggestions?['suggestedFullName'] != null) {
      controllers['fullName']?.text = suggestions!['suggestedFullName'];
    }
    
    if (userState.email != null) {
      controllers['email']?.text = userState.email!;
    }
    
    if (userState.phoneNumber != null) {
      controllers['phone']?.text = userState.phoneNumber!;
    }
    
    if (userState.username != null) {
      controllers['username']?.text = userState.username!;
    } else if (suggestions?['suggestedUsername'] != null) {
      controllers['username']?.text = suggestions!['suggestedUsername'];
    }
    
    if (userState.bio != null) {
      controllers['bio']?.text = userState.bio!;
    }
    
    // Service professional specific data
    if (userState.isServiceProfessional) {
      if (userState.businessName != null) {
        controllers['businessName']?.text = userState.businessName!;
      } else if (suggestions?['suggestedBusinessName'] != null) {
        controllers['businessName']?.text = suggestions!['suggestedBusinessName'];
      }
      
      if (userState.businessAddress != null) {
        controllers['businessAddress']?.text = userState.businessAddress!;
      }
      
      if (userState.businessPhone != null) {
        controllers['businessPhone']?.text = userState.businessPhone!;
      }
      
      if (userState.website != null) {
        controllers['website']?.text = userState.website!;
      }
      
      if (userState.yearsOfExperience > 0) {
        controllers['yearsExperience']?.text = userState.yearsOfExperience.toString();
      }
    }
  }
}

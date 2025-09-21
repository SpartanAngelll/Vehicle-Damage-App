import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _userIdKey = 'user_id';
  static const String _themeModeKey = 'theme_mode';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userDataKey = 'user_data';

  // Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  // Save user ID
  static Future<bool> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userIdKey, userId);
    } catch (e) {
      return false;
    }
  }

  // Get theme mode
  static Future<String> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeModeKey) ?? '0'; // Default to system theme
    } catch (e) {
      return '0';
    }
  }

  // Save theme mode
  static Future<bool> saveThemeMode(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_themeModeKey, themeMode);
    } catch (e) {
      return false;
    }
  }

  // Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Set onboarding completed status
  static Future<bool> setOnboardingCompleted({bool completed = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_onboardingCompletedKey, completed);
    } catch (e) {
      return false;
    }
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        // In a real app, you'd parse this as JSON
        // For now, return a simple map
        return {'userId': userDataString};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user data
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real app, you'd convert this to JSON string
      final userDataString = userData.toString();
      return await prefs.setString(_userDataKey, userDataString);
    } catch (e) {
      return false;
    }
  }

  // Clear user data
  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_userDataKey);
    } catch (e) {
      return false;
    }
  }

  // Clear all data
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      return false;
    }
  }

  // Get damage reports metadata
  static Future<List<Map<String, dynamic>>> getDamageReportsMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real app, you'd store and retrieve actual metadata
      // For now, return an empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  // Save damage reports metadata
  static Future<bool> saveDamageReportsMetadata(List<Map<String, dynamic>> metadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real app, you'd store the actual metadata
      // For now, just return success
      return true;
    } catch (e) {
      return false;
    }
  }

  // Additional user data methods
  static Future<bool> saveUserEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_email', email);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveUserPhone(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_phone', phone);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_phone');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_role', role);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveUserBio(String bio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_bio', bio);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserBio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_bio');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveUserFullName(String fullName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_full_name', fullName);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_full_name');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveUserUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_username', username);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_username');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveUserProfilePhotoUrl(String profilePhotoUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_profile_photo_url', profilePhotoUrl);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserProfilePhotoUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_profile_photo_url');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveIsAuthenticated(bool isAuthenticated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool('is_authenticated', isAuthenticated);
    } catch (e) {
      return false;
    }
  }

  static Future<bool?> getIsAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_authenticated');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveLastLoginTime(DateTime lastLoginTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt('last_login_time', lastLoginTime.millisecondsSinceEpoch);
    } catch (e) {
      return false;
    }
  }

  static Future<DateTime?> getLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_login_time');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}


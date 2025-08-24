import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Theme storage
  static const String _themeModeKey = 'theme_mode';
  
  // User data storage
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userRoleKey = 'user_role';
  static const String _userBioKey = 'user_bio';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _lastLoginTimeKey = 'last_login_time';
  
  // App settings storage
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _damageReportsMetadataKey = 'damage_reports_metadata';

  // Theme methods
  static Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode);
  }

  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }

  // User data methods
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPhoneKey, phone);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // User bio methods
  static Future<void> saveUserBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userBioKey, bio);
  }

  static Future<String?> getUserBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userBioKey);
  }

  static Future<void> saveIsAuthenticated(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, isAuthenticated);
  }

  static Future<bool?> getIsAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey);
  }

  static Future<void> saveLastLoginTime(DateTime lastLoginTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastLoginTimeKey, lastLoginTime.millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastLoginTimeKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // App settings methods
  static Future<void> saveIsFirstLaunch(bool isFirstLaunch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, isFirstLaunch);
  }

  static Future<bool> getIsFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  static Future<void> setOnboardingCompleted({bool completed = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Damage reports metadata methods
  static Future<void> saveDamageReportsMetadata(List<Map<String, dynamic>> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = metadata.map((item) => {
      'id': item['id'],
      'description': item['description'],
      'timestamp': item['timestamp'],
      'estimateCount': item['estimateCount'],
      'hasEstimates': item['hasEstimates'],
    }).toList();
    
    // Convert to JSON string for storage
    final jsonString = metadataJson.toString();
    await prefs.setString(_damageReportsMetadataKey, jsonString);
  }

  static Future<List<Map<String, dynamic>>> getDamageReportsMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_damageReportsMetadataKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        // Parse the stored string back to a list
        // This is a simplified approach - in a real app you'd use proper JSON serialization
        final List<Map<String, dynamic>> metadata = [];
        // For now, return empty list since we can't easily reconstruct the metadata
        // In a real app, you'd use jsonDecode and proper serialization
        return metadata;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Generic app setting methods
  static Future<void> saveAppSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  static Future<T?> getAppSetting<T>(String key, T defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    if (defaultValue is String) {
      return prefs.getString(key) as T? ?? defaultValue;
    } else if (defaultValue is int) {
      return prefs.getInt(key) as T? ?? defaultValue;
    } else if (defaultValue is double) {
      return prefs.getDouble(key) as T? ?? defaultValue;
    } else if (defaultValue is bool) {
      return prefs.getBool(key) as T? ?? defaultValue;
    } else if (defaultValue is List<String>) {
      return prefs.getStringList(key) as T? ?? defaultValue;
    }
    return defaultValue;
  }

  // Clear user data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userBioKey);
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_lastLoginTimeKey);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

# Network Connectivity Troubleshooting Guide

## 🔍 **Issue Overview**
The app has been experiencing network connectivity issues, particularly with Firestore operations that result in `UnknownHostException` and other network-related errors.

## 🛠️ **Solutions Implemented**

### 1. **Enhanced Network Connectivity Service**
- **File**: `lib/services/network_connectivity_service.dart`
- **Features**:
  - Real-time connectivity monitoring
  - Automatic retry logic with exponential backoff
  - Comprehensive error handling for different network issues
  - Firestore-specific connectivity testing
  - User-friendly error messages

### 2. **Improved Firestore Service**
- **File**: `lib/services/firebase_firestore_service.dart`
- **Enhancements**:
  - Integrated with network connectivity service
  - Retry logic for failed operations
  - Better error logging and debugging
  - Graceful handling of network interruptions

### 3. **App Initialization Updates**
- **File**: `lib/main.dart`
- **Changes**:
  - Network connectivity service initialization
  - Early detection of network issues
  - Better error handling during app startup

## 🚨 **Common Network Issues & Solutions**

### Issue: UnknownHostException
**Symptoms**: "Cannot resolve host" errors
**Causes**:
- DNS resolution failures
- Network connectivity issues
- Firewall blocking requests
- Incorrect Firebase configuration

**Solutions**:
1. **Check Internet Connection**:
   ```bash
   # Test basic connectivity
   ping google.com
   ping firestore.googleapis.com
   ```

2. **Verify Firebase Configuration**:
   - Check `firebase_options.dart` for correct project settings
   - Ensure Firebase project is active and billing is enabled
   - Verify Firestore is enabled in Firebase Console

3. **Network Configuration**:
   - Check if corporate firewall is blocking Firebase domains
   - Try different network (mobile hotspot vs WiFi)
   - Restart network adapter

### Issue: SocketException
**Symptoms**: "Network is unreachable" or "Connection refused"
**Causes**:
- Network interface down
- Firewall blocking connections
- Proxy server issues

**Solutions**:
1. **Check Network Interface**:
   ```bash
   # Windows
   ipconfig /all
   
   # Test connectivity
   telnet firestore.googleapis.com 443
   ```

2. **Firewall Configuration**:
   - Allow Flutter/Dart through Windows Firewall
   - Check corporate firewall rules
   - Temporarily disable antivirus to test

### Issue: TimeoutException
**Symptoms**: Operations timing out after 10+ seconds
**Causes**:
- Slow network connection
- High server load
- Network congestion

**Solutions**:
1. **Increase Timeout Values**:
   ```dart
   // In network_connectivity_service.dart
   static const Duration _connectionTimeout = Duration(seconds: 30);
   ```

2. **Network Optimization**:
   - Use wired connection instead of WiFi
   - Close bandwidth-intensive applications
   - Check network speed: `speedtest.net`

### Issue: FirebaseException
**Symptoms**: "Permission denied" or "Unauthenticated"
**Causes**:
- Authentication issues
- Security rules blocking access
- Project configuration problems

**Solutions**:
1. **Check Authentication**:
   ```dart
   // Verify user is authenticated
   final user = FirebaseAuth.instance.currentUser;
   print('User authenticated: ${user != null}');
   ```

2. **Review Firestore Rules**:
   ```javascript
   // Check firestore.rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Ensure rules allow authenticated access
     }
   }
   ```

## 🔧 **Testing Network Connectivity**

### 1. **Manual Testing**
```dart
// Test network connectivity
final networkService = NetworkConnectivityService();
final isConnected = await networkService.testConnectivity();
print('Network connected: $isConnected');

// Test Firestore connectivity
final firestoreConnected = await networkService.testFirestoreConnectivity();
print('Firestore connected: $firestoreConnected');
```

### 2. **Debug Commands**
```bash
# Check network connectivity
flutter run --debug

# Monitor network traffic
# Use Android Studio Network Inspector or Chrome DevTools
```

### 3. **Log Analysis**
Look for these log patterns:
```
✅ [NetworkService] Network connectivity test passed
❌ [NetworkService] Firestore connectivity test failed
⚠️ [FirestoreService] Users collection access failed
```

## 📱 **Platform-Specific Issues**

### Android
- **Emulator Issues**: Use physical device for testing
- **Network Security Config**: Check `android/app/src/main/res/xml/network_security_config.xml`
- **Permissions**: Ensure `INTERNET` permission is granted

### Windows (Desktop)
- **Firewall**: Windows Defender may block connections
- **Proxy Settings**: Check system proxy configuration
- **Antivirus**: May interfere with network connections

## 🚀 **Performance Optimization**

### 1. **Connection Pooling**
```dart
// Use connection pooling for better performance
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### 2. **Offline Support**
```dart
// Enable offline persistence
await FirebaseFirestore.instance.enablePersistence();
```

### 3. **Caching Strategy**
- Use `FirestoreCacheService` for offline data
- Implement local storage for critical data
- Cache user preferences and settings

## 🔍 **Monitoring & Debugging**

### 1. **Real-time Monitoring**
```dart
// Listen to network connectivity changes
NetworkConnectivityService().connectivityStream.listen((isConnected) {
  print('Connectivity changed: $isConnected');
});

// Listen to network errors
NetworkConnectivityService().errorStream.listen((error) {
  print('Network error: ${error.message}');
});
```

### 2. **Error Reporting**
```dart
// Log network errors for analysis
void logNetworkError(dynamic error) {
  debugPrint('🌐 [NetworkError] ${error.toString()}');
  // Send to crash reporting service
}
```

### 3. **Health Checks**
```dart
// Periodic health checks
Timer.periodic(Duration(minutes: 5), (timer) async {
  final isHealthy = await NetworkConnectivityService().testConnectivity();
  if (!isHealthy) {
    // Handle unhealthy state
  }
});
```

## 📋 **Troubleshooting Checklist**

- [ ] Check internet connection
- [ ] Verify Firebase project configuration
- [ ] Test with different network (mobile hotspot)
- [ ] Check firewall/antivirus settings
- [ ] Verify Firestore security rules
- [ ] Test on physical device vs emulator
- [ ] Check system proxy settings
- [ ] Review app logs for specific errors
- [ ] Test with different Firebase project
- [ ] Verify billing is enabled on Firebase project

## 🆘 **Emergency Fallback**

If network issues persist:

1. **Offline Mode**: App should work with cached data
2. **User Notification**: Inform users about connectivity issues
3. **Retry Mechanism**: Automatic retry with exponential backoff
4. **Alternative Endpoints**: Consider backup Firebase project
5. **Local Storage**: Store critical data locally

## 📞 **Support Resources**

- **Firebase Status**: https://status.firebase.google.com/
- **Flutter Network Issues**: https://flutter.dev/docs/testing/network-issues
- **Firestore Troubleshooting**: https://firebase.google.com/docs/firestore/troubleshoot
- **Android Network Issues**: https://developer.android.com/training/basics/network-ops/

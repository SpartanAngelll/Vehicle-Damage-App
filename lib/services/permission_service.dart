import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isGranted) {
          return true;
        }
      }
      
      if (status.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Camera Permission Required',
          'Camera access is permanently denied. Please enable it in your device settings to take photos of vehicle damage.',
          'Open Settings',
          () => openAppSettings(),
        );
        return false;
      }
      
      if (status.isRestricted) {
        await _showPermissionDialog(
          context,
          'Camera Access Restricted',
          'Camera access is restricted on your device. This may be due to parental controls or device policies.',
          'OK',
          () => Navigator.of(context).pop(),
        );
        return false;
      }
      
      return false;
    } catch (e) {
      await _showPermissionDialog(
        context,
        'Permission Error',
        'An error occurred while requesting camera permission: ${e.toString()}',
        'OK',
        () => Navigator.of(context).pop(),
      );
      return false;
    }
  }

  // Location permission
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      final status = await Permission.location.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.location.request();
        if (result.isGranted) {
          return true;
        }
      }
      
      if (status.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Location Permission Required',
          'Location access is permanently denied. Please enable it in your device settings to help repair professionals find your location.',
          'Open Settings',
          () => openAppSettings(),
        );
        return false;
      }
      
      if (status.isRestricted) {
        await _showPermissionDialog(
          context,
          'Location Access Restricted',
          'Location access is restricted on your device. This may be due to parental controls or device policies.',
          'OK',
          () => Navigator.of(context).pop(),
        );
        return false;
      }
      
      return false;
    } catch (e) {
      await _showPermissionDialog(
        context,
        'Permission Error',
        'An error occurred while requesting location permission: ${e.toString()}',
        'OK',
        () => Navigator.of(context).pop(),
      );
      return false;
    }
  }

  // Storage permission (for Android)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    try {
      // Check if we're on Android
      if (Theme.of(context).platform == TargetPlatform.android) {
        final status = await Permission.storage.status;
        
        if (status.isGranted) {
          return true;
        }
        
        if (status.isDenied) {
          final result = await Permission.storage.request();
          if (result.isGranted) {
            return true;
          }
        }
        
        if (status.isPermanentlyDenied) {
          await _showPermissionDialog(
            context,
            'Storage Permission Required',
            'Storage access is permanently denied. Please enable it in your device settings to save and access photos.',
            'Open Settings',
            () => openAppSettings(),
          );
          return false;
        }
        
        if (status.isRestricted) {
          await _showPermissionDialog(
            context,
            'Storage Access Restricted',
            'Storage access is restricted on your device. This may be due to parental controls or device policies.',
            'OK',
            () => Navigator.of(context).pop(),
          );
          return false;
        }
      }
      
      // On other platforms, storage permission is usually not required
      return true;
    } catch (e) {
      await _showPermissionDialog(
        context,
        'Permission Error',
        'An error occurred while requesting storage permission: ${e.toString()}',
        'OK',
        () => Navigator.of(context).pop(),
      );
      return false;
    }
  }

  // Microphone permission (for video recording if needed later)
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    try {
      final status = await Permission.microphone.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isGranted) {
          return true;
        }
      }
      
      if (status.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Microphone Permission Required',
          'Microphone access is permanently denied. Please enable it in your device settings if you want to record voice notes.',
          'Open Settings',
          () => openAppSettings(),
        );
        return false;
      }
      
      return false;
    } catch (e) {
      await _showPermissionDialog(
        context,
        'Permission Error',
        'An error occurred while requesting microphone permission: ${e.toString()}',
        'OK',
        () => Navigator.of(context).pop(),
      );
      return false;
    }
  }

  // Check multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> checkMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      return await permissions.request();
    } catch (e) {
      debugPrint('Error checking multiple permissions: $e');
      return {};
    }
  }

  // Show permission explanation dialog
  static Future<void> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    String actionText,
    VoidCallback onAction,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }

  // Check if all required permissions are granted
  static Future<bool> checkAllRequiredPermissions(BuildContext context) async {
    final cameraGranted = await requestCameraPermission(context);
    final storageGranted = await requestStoragePermission(context);
    
    // Location is optional but recommended
    await requestLocationPermission(context);
    
    return cameraGranted && storageGranted;
  }

  // Show permission status summary
  static Future<void> showPermissionStatus(BuildContext context) async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final storageStatus = await Permission.storage.status;
    
    String getStatusText(PermissionStatus status) {
      switch (status) {
        case PermissionStatus.granted:
          return '✅ Granted';
        case PermissionStatus.denied:
          return '❌ Denied';
        case PermissionStatus.permanentlyDenied:
          return '🚫 Permanently Denied';
        case PermissionStatus.restricted:
          return '🔒 Restricted';
        case PermissionStatus.limited:
          return '⚠️ Limited';
        default:
          return '❓ Unknown';
      }
    }
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Camera: ${getStatusText(cameraStatus)}'),
              SizedBox(height: 8),
              Text('Location: ${getStatusText(locationStatus)}'),
              SizedBox(height: 8),
              Text('Storage: ${getStatusText(storageStatus)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for connectivity state
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<NetworkError> _errorController = StreamController<NetworkError>.broadcast();
  
  // Current connectivity state
  bool _isConnected = true;
  ConnectivityResult _currentResult = ConnectivityResult.none;
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _connectionTimeout = Duration(seconds: 10);
  
  // Getters
  bool get isConnected => _isConnected;
  ConnectivityResult get currentResult => _currentResult;
  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<NetworkError> get errorStream => _errorController.stream;

  /// Initialize the network connectivity service
  Future<void> initialize() async {
    try {
      debugPrint('🌐 [NetworkService] Initializing network connectivity service...');
      
      // Get initial connectivity state
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        _currentResult = results.first;
        _isConnected = _currentResult != ConnectivityResult.none;
        _connectivityController.add(_isConnected);
      }
      
      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
      
      // Test Firestore connectivity
      await _testFirestoreConnectivity();
      
      debugPrint('✅ [NetworkService] Network connectivity service initialized');
    } catch (e) {
      debugPrint('❌ [NetworkService] Failed to initialize: $e');
      _errorController.add(NetworkError.initializationFailed(e.toString()));
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (results.isNotEmpty) {
      final newResult = results.first;
      final wasConnected = _isConnected;
      
      _currentResult = newResult;
      _isConnected = newResult != ConnectivityResult.none;
      
      debugPrint('🌐 [NetworkService] Connectivity changed: ${_currentResult.name} (Connected: $_isConnected)');
      
      // Notify listeners
      _connectivityController.add(_isConnected);
      
      // If we just reconnected, test Firestore connectivity
      if (!wasConnected && _isConnected) {
        _testFirestoreConnectivity();
      }
    }
  }

  /// Test Firestore connectivity with retry logic
  Future<bool> _testFirestoreConnectivity() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('🔍 [NetworkService] Testing Firestore connectivity (attempt $attempt/$_maxRetries)...');
        
        // Test with a simple read operation
        await _firestore
            .collection('_test_connectivity')
            .limit(1)
            .get()
            .timeout(_connectionTimeout);
        
        debugPrint('✅ [NetworkService] Firestore connectivity test passed');
        return true;
      } catch (e) {
        debugPrint('❌ [NetworkService] Firestore connectivity test failed (attempt $attempt): $e');
        
        if (e is SocketException) {
          _errorController.add(NetworkError.socketException(e.message));
        } else if (e is TimeoutException) {
          _errorController.add(NetworkError.timeoutException('Connection timeout'));
        } else if (e.toString().contains('UnknownHostException')) {
          _errorController.add(NetworkError.unknownHostException('Cannot resolve host'));
        } else if (e is FirebaseException) {
          _errorController.add(NetworkError.firebaseException(e.message ?? 'Firebase error'));
        } else {
          _errorController.add(NetworkError.genericException(e.toString()));
        }
        
        // Wait before retrying (except on last attempt)
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }
    
    debugPrint('❌ [NetworkService] All Firestore connectivity tests failed');
    return false;
  }

  /// Test network connectivity with custom timeout
  Future<bool> testConnectivity({Duration? timeout}) async {
    try {
      final results = await _connectivity
          .checkConnectivity()
          .timeout(timeout ?? _connectionTimeout);
      
      if (results.isNotEmpty) {
        final result = results.first;
        _currentResult = result;
        _isConnected = result != ConnectivityResult.none;
        return _isConnected;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ [NetworkService] Connectivity test failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Test Firestore connectivity with custom timeout
  Future<bool> testFirestoreConnectivity({Duration? timeout}) async {
    try {
      await _firestore
          .collection('_test_connectivity')
          .limit(1)
          .get()
          .timeout(timeout ?? _connectionTimeout);
      
      return true;
    } catch (e) {
      debugPrint('❌ [NetworkService] Firestore connectivity test failed: $e');
      
      if (e is SocketException) {
        _errorController.add(NetworkError.socketException(e.message));
      } else if (e is TimeoutException) {
        _errorController.add(NetworkError.timeoutException('Connection timeout'));
      } else if (e.toString().contains('UnknownHostException')) {
        _errorController.add(NetworkError.unknownHostException('Cannot resolve host'));
      } else if (e is FirebaseException) {
        _errorController.add(NetworkError.firebaseException(e.message ?? 'Firebase error'));
      } else {
        _errorController.add(NetworkError.genericException(e.toString()));
      }
      
      return false;
    }
  }

  /// Execute a Firestore operation with retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
    Duration? timeout,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 [NetworkService] Executing operation (attempt $attempt/$maxRetries)...');
        
        final result = await operation().timeout(timeout ?? _connectionTimeout);
        debugPrint('✅ [NetworkService] Operation completed successfully');
        return result;
      } catch (e) {
        debugPrint('❌ [NetworkService] Operation failed (attempt $attempt): $e');
        
        // Don't retry on certain errors
        if (e is FirebaseException && e.code == 'permission-denied') {
          rethrow;
        }
        
        if (attempt < maxRetries) {
          debugPrint('⏳ [NetworkService] Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        } else {
          // Last attempt failed, handle the error
          if (e is SocketException) {
            _errorController.add(NetworkError.socketException(e.message));
          } else if (e is TimeoutException) {
            _errorController.add(NetworkError.timeoutException('Operation timeout'));
          } else if (e.toString().contains('UnknownHostException')) {
            _errorController.add(NetworkError.unknownHostException('Cannot resolve host'));
          } else if (e is FirebaseException) {
            _errorController.add(NetworkError.firebaseException(e.message ?? 'Firebase error'));
          } else {
            _errorController.add(NetworkError.genericException(e.toString()));
          }
          
          rethrow;
        }
      }
    }
    
    throw Exception('All retry attempts failed');
  }

  /// Get user-friendly error message
  String getErrorMessage(NetworkError error) {
    switch (error.type) {
      case NetworkErrorType.socketException:
        return 'Network connection failed. Please check your internet connection.';
      case NetworkErrorType.timeoutException:
        return 'Request timed out. Please try again.';
      case NetworkErrorType.unknownHostException:
        return 'Cannot connect to server. Please check your internet connection.';
      case NetworkErrorType.firebaseException:
        return 'Database connection failed. Please try again.';
      case NetworkErrorType.initializationFailed:
        return 'Network service initialization failed.';
      case NetworkErrorType.genericException:
        return 'Network error occurred. Please try again.';
    }
  }

  /// Check if error is retryable
  bool isRetryableError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error.toString().contains('UnknownHostException')) return true;
    if (error is FirebaseException && error.code != 'permission-denied') return true;
    return false;
  }

  /// Dispose resources
  void dispose() {
    _connectivityController.close();
    _errorController.close();
  }
}

/// Network error types
enum NetworkErrorType {
  socketException,
  timeoutException,
  unknownHostException,
  firebaseException,
  initializationFailed,
  genericException,
}

/// Network error class
class NetworkError {
  final NetworkErrorType type;
  final String message;
  final DateTime timestamp;

  NetworkError._(this.type, this.message) : timestamp = DateTime.now();

  factory NetworkError.socketException(String message) =>
      NetworkError._(NetworkErrorType.socketException, message);

  factory NetworkError.timeoutException(String message) =>
      NetworkError._(NetworkErrorType.timeoutException, message);

  factory NetworkError.unknownHostException(String message) =>
      NetworkError._(NetworkErrorType.unknownHostException, message);

  factory NetworkError.firebaseException(String message) =>
      NetworkError._(NetworkErrorType.firebaseException, message);

  factory NetworkError.initializationFailed(String message) =>
      NetworkError._(NetworkErrorType.initializationFailed, message);

  factory NetworkError.genericException(String message) =>
      NetworkError._(NetworkErrorType.genericException, message);

  @override
  String toString() => 'NetworkError(${type.name}): $message';
}

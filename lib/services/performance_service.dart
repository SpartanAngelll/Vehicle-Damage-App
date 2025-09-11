import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

class PerformanceService {
  static const int _maxConcurrentOperations = 3;
  static final Map<String, Completer> _activeOperations = {};
  static final Queue<Future Function()> _operationQueue = Queue<Future Function()>();
  static int _activeOperationCount = 0;
  
  // Debounce function to prevent excessive calls
  static Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  
  // Throttle function to limit operation frequency
  static DateTime? _lastThrottleTime;
  static const Duration _throttleDelay = Duration(milliseconds: 100);
  
  /// Execute a heavy operation with concurrency control
  static Future<T> executeWithConcurrency<T>(
    String operationId,
    Future<T> Function() operation,
  ) async {
    // Check if operation is already running
    if (_activeOperations.containsKey(operationId)) {
      return await _activeOperations[operationId]!.future as T;
    }
    
    // Check concurrency limit
    if (_activeOperationCount >= _maxConcurrentOperations) {
      // Queue the operation
      final completer = Completer<T>();
      _operationQueue.add(() async {
        try {
          final result = await operation();
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      });
      return await completer.future;
    }
    
    // Execute operation
    final completer = Completer<T>();
    _activeOperations[operationId] = completer;
    _activeOperationCount++;
    
    try {
      final result = await operation();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _activeOperations.remove(operationId);
      _activeOperationCount--;
      
      // Process queued operations
      if (_operationQueue.isNotEmpty && _activeOperationCount < _maxConcurrentOperations) {
        final nextOperation = _operationQueue.removeFirst();
        nextOperation();
      }
    }
  }
  
  /// Debounce function calls
  static void debounce(String key, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      callback();
    });
  }
  
  /// Throttle function calls
  static bool throttle(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) > _throttleDelay) {
      _lastThrottleTime = now;
      callback();
      return true;
    }
    return false;
  }
  
  /// Execute operation in isolate for heavy computations
  static Future<T> executeInIsolate<T>(
    T Function() computation,
  ) async {
    if (kIsWeb) {
      // Web doesn't support isolates, run on main thread
      return computation();
    }
    
    return await compute(_isolateComputation, computation);
  }
  
  /// Isolate computation wrapper
  static T _isolateComputation<T>(T Function() computation) {
    return computation();
  }
  
  /// Batch operations for better performance
  static Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations,
    {int batchSize = 5}
  ) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((operation) => operation())
      );
      results.addAll(batchResults);
    }
    
    return results;
  }
  
  /// Memory-efficient list processing
  static Future<List<R>> processListInBatches<T, R>(
    List<T> items,
    Future<R> Function(T item) processor,
    {int batchSize = 10}
  ) async {
    final results = <R>[];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((item) => processor(item))
      );
      results.addAll(batchResults);
      
      // Allow other operations to run
      await Future.delayed(Duration.zero);
    }
    
    return results;
  }
  
  /// Clear all active operations
  static void clearActiveOperations() {
    _activeOperations.clear();
    while (_operationQueue.isNotEmpty) {
      _operationQueue.removeFirst();
    }
    _activeOperationCount = 0;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastThrottleTime = null;
  }
  
  /// Get performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    return {
      'activeOperations': _activeOperationCount,
      'queuedOperations': _operationQueue.length,
      'maxConcurrentOperations': _maxConcurrentOperations,
    };
  }
}

// Queue implementation for Dart
class Queue<T> {
  final List<T> _items = [];
  
  void add(T item) {
    _items.add(item);
  }
  
  T removeFirst() {
    if (_items.isEmpty) {
      throw StateError('Queue is empty');
    }
    return _items.removeAt(0);
  }
  
  bool get isNotEmpty => _items.isNotEmpty;
  
  int get length => _items.length;
}

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

/// Production-ready Firebase Supabase Service
/// Features:
/// - Retry logic with exponential backoff
/// - Token refresh mechanism
/// - Structured logging (debug mode only)
/// - Proper error handling
/// - Request timeouts
/// - Basic metrics tracking
class FirebaseSupabaseService {
  static FirebaseSupabaseService? _instance;
  SupabaseClient? _supabaseClient;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? _supabaseUrl;
  String? _supabaseAnonKey;
  
  // Token caching
  String? _cachedToken;
  DateTime? _tokenExpiry;
  static const Duration _tokenRefreshBuffer = Duration(minutes: 5);
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 500);
  static const Duration _maxRetryDelay = Duration(seconds: 10);
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  // Metrics
  int _successCount = 0;
  int _failureCount = 0;
  int _retryCount = 0;

  FirebaseSupabaseService._();

  static FirebaseSupabaseService get instance {
    _instance ??= FirebaseSupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase service
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      _log('Initializing Supabase service', level: LogLevel.info);
      
      // Store URL and key for direct HTTP requests
      _supabaseUrl = supabaseUrl;
      _supabaseAnonKey = supabaseAnonKey;
      
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _supabaseClient = Supabase.instance.client;
      
      _log('Supabase client initialized successfully', level: LogLevel.info);
      
      // Listen to auth state changes for token refresh
      _firebaseAuth.authStateChanges().listen((user) async {
        if (user != null) {
          // Clear cached token when user changes
          _cachedToken = null;
          _tokenExpiry = null;
          await _refreshSupabaseSession();
        } else {
          _cachedToken = null;
          _tokenExpiry = null;
        }
      });
    } catch (e, stackTrace) {
      _log('Initialization error: $e', level: LogLevel.error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Refresh Supabase session with Firebase token
  Future<void> _refreshSupabaseSession() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      final idToken = await _getFirebaseIdToken(forceRefresh: false);
      if (idToken == null || _supabaseClient == null) return;

      // Try to set session (may fail with Firebase tokens, but worth trying)
      try {
        await _supabaseClient!.auth.setSession(idToken);
      } catch (e) {
        // Expected to fail with Firebase tokens - we use HTTP requests instead
        _log('Session refresh failed (expected with Firebase tokens): $e', level: LogLevel.debug);
      }
    } catch (e) {
      _log('Session refresh error: $e', level: LogLevel.warning);
    }
  }

  /// Get Firebase ID token with caching and refresh
  Future<String?> _getFirebaseIdToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      
      // Check if cached token is still valid
      if (!forceRefresh && _cachedToken != null && _tokenExpiry != null) {
        if (DateTime.now().isBefore(_tokenExpiry!.subtract(_tokenRefreshBuffer))) {
          return _cachedToken;
        }
      }
      
      // Get fresh token
      // Note: getIdToken takes a positional boolean parameter, not named
      final token = await user.getIdToken(forceRefresh);
      if (token == null) return null;
      
      // Cache token (Firebase tokens expire in 1 hour)
      _cachedToken = token;
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
      
      return token;
    } catch (e) {
      _log('Get token error: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Get Firebase ID token (public method)
  Future<String?> getFirebaseIdToken() async {
    return await _getFirebaseIdToken(forceRefresh: false);
  }

  /// Execute HTTP request with retry logic
  Future<http.Response> _executeWithRetry({
    required Future<http.Response> Function() request,
    String? operation,
  }) async {
    int attempt = 0;
    Exception? lastException;
    
    while (attempt <= _maxRetries) {
      try {
        final response = await request().timeout(_requestTimeout);
        
        // Check if response indicates retryable error
        if (_isRetryableError(response.statusCode)) {
          if (attempt < _maxRetries) {
            attempt++;
            _retryCount++;
            final delay = _calculateBackoff(attempt);
            _log(
              'Retryable error ${response.statusCode}, retrying in ${delay.inMilliseconds}ms (attempt $attempt/$_maxRetries)',
              level: LogLevel.warning,
              operation: operation,
            );
            await Future.delayed(delay);
            continue;
          }
        }
        
        // Success or non-retryable error
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _successCount++;
        } else {
          _failureCount++;
        }
        return response;
      } on TimeoutException {
        if (attempt < _maxRetries) {
          attempt++;
          _retryCount++;
          final delay = _calculateBackoff(attempt);
          _log(
            'Request timeout, retrying in ${delay.inMilliseconds}ms (attempt $attempt/$_maxRetries)',
            level: LogLevel.warning,
            operation: operation,
          );
          await Future.delayed(delay);
          continue;
        }
        lastException = TimeoutException('Request timed out after $_maxRetries retries');
        break;
      } on Exception catch (e) {
        if (attempt < _maxRetries && _isRetryableException(e)) {
          attempt++;
          _retryCount++;
          final delay = _calculateBackoff(attempt);
          _log(
            'Exception occurred, retrying in ${delay.inMilliseconds}ms (attempt $attempt/$_maxRetries): $e',
            level: LogLevel.warning,
            operation: operation,
          );
          await Future.delayed(delay);
          lastException = e;
          continue;
        }
        lastException = e;
        break;
      }
    }
    
    _failureCount++;
    if (lastException != null) {
      throw lastException;
    }
    throw Exception('Request failed after $_maxRetries retries');
  }

  /// Check if HTTP status code indicates retryable error
  bool _isRetryableError(int statusCode) {
    // 429 = Rate limit, 500-503 = Server errors
    return statusCode == 429 || (statusCode >= 500 && statusCode < 504);
  }

  /// Check if exception is retryable
  bool _isRetryableException(Exception e) {
    // Network errors, timeouts, etc. are retryable
    return e is TimeoutException || 
           e.toString().contains('SocketException') ||
           e.toString().contains('NetworkException');
  }

  /// Calculate exponential backoff delay with jitter
  Duration _calculateBackoff(int attempt) {
    final exponentialDelay = _baseRetryDelay * pow(2, attempt - 1);
    final jitter = Duration(milliseconds: Random().nextInt(200));
    final totalDelay = exponentialDelay + jitter;
    return totalDelay > _maxRetryDelay ? _maxRetryDelay : totalDelay;
  }

  /// Upsert (insert or update) data into Supabase with retry logic
  /// Uses ON CONFLICT to handle duplicates gracefully
  Future<List<Map<String, dynamic>>?> upsert({
    required String table,
    required Map<String, dynamic> data,
    required String conflictTarget, // Column name for conflict resolution (e.g., 'firebase_uid')
  }) async {
    try {
      if (_supabaseClient == null) {
        throw Exception('Supabase client not initialized');
      }

      // Get Firebase token (with refresh if needed)
      final idToken = await _getFirebaseIdToken(forceRefresh: false);
      
      if (idToken == null || _supabaseUrl == null || _supabaseAnonKey == null) {
        throw Exception('Missing authentication: Firebase token or Supabase credentials not available');
      }

      // Use direct HTTP request with Firebase token for Third Party Auth
      // Add conflict resolution to URL: ?on_conflict=firebase_uid
      final url = Uri.parse('$_supabaseUrl/rest/v1/$table?select=*&on_conflict=$conflictTarget');
      
      // Log token info for debugging (masked)
      if (kDebugMode) {
        final tokenPreview = idToken.length > 50 
            ? '${idToken.substring(0, 20)}...${idToken.substring(idToken.length - 10)}'
            : idToken;
        _log('Using Firebase token for UPSERT (length: ${idToken.length}, preview: $tokenPreview)', 
            level: LogLevel.debug, operation: 'upsert');
      }
      
      final response = await _executeWithRetry(
        operation: 'upsert',
        request: () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $idToken',
            'Prefer': 'return=representation,resolution=merge-duplicates',
          },
          body: jsonEncode(data),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Upsert successful', level: LogLevel.info, operation: 'upsert', table: table);
          
          if (responseData is List) {
            return List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map) {
            return [Map<String, dynamic>.from(responseData)];
          }
          return [];
        } catch (e) {
          _log('Failed to parse response: $e', level: LogLevel.error, operation: 'upsert');
          throw Exception('Invalid response format: $e');
        }
      } else {
        final errorBody = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      _log(
        'Upsert error: $e',
        level: LogLevel.error,
        operation: 'upsert',
        table: table,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Insert data into Supabase with retry logic
  Future<List<Map<String, dynamic>>?> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (_supabaseClient == null) {
        throw Exception('Supabase client not initialized');
      }

      // Get Firebase token (with refresh if needed)
      final idToken = await _getFirebaseIdToken(forceRefresh: false);
      
      if (idToken == null || _supabaseUrl == null || _supabaseAnonKey == null) {
        throw Exception('Missing authentication: Firebase token or Supabase credentials not available');
      }

      // Use direct HTTP request with Firebase token for Third Party Auth
      final url = Uri.parse('$_supabaseUrl/rest/v1/$table?select=*');
      
      // Log token info for debugging (masked)
      if (kDebugMode) {
        final tokenPreview = idToken.length > 50 
            ? '${idToken.substring(0, 20)}...${idToken.substring(idToken.length - 10)}'
            : idToken;
        _log('Using Firebase token (length: ${idToken.length}, preview: $tokenPreview)', 
            level: LogLevel.debug, operation: 'insert');
        
        // Log current Firebase UID for comparison
        final currentUid = _firebaseAuth.currentUser?.uid;
        if (currentUid != null) {
          _log('Current Firebase UID: $currentUid', level: LogLevel.debug, operation: 'insert');
          
          // Log customer_id from data for RLS comparison
          if (data.containsKey('customer_id')) {
            _log('Booking customer_id: ${data['customer_id']}, Expected to match Firebase UID: $currentUid', 
                level: LogLevel.debug, operation: 'insert');
          }
        }
      }
      
      final response = await _executeWithRetry(
        operation: 'insert',
        request: () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $idToken',
            'Prefer': 'return=representation',
          },
          body: jsonEncode(data),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Insert successful', level: LogLevel.info, operation: 'insert', table: table);
          
          if (responseData is List) {
            return List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map) {
            return [Map<String, dynamic>.from(responseData)];
          }
          return [];
        } catch (e) {
          _log('Failed to parse response: $e', level: LogLevel.error, operation: 'insert');
          throw Exception('Invalid response format: $e');
        }
        } else {
          // Handle specific error codes
          if (response.statusCode == 409) {
            // Duplicate key error - user might already exist
            // This is expected for user sync, so we'll log it but not throw
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
            final errorCode = errorBody?['code'] as String?;
            if (errorCode == '23505') {
              _log(
                'Duplicate key error (409) - record may already exist. Consider using upsert() instead of insert().',
                level: LogLevel.warning,
                operation: 'insert',
                table: table,
              );
              // Re-throw so caller can handle it
            }
          }
          
          if (response.statusCode == 401) {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorCode = errorBody?['code'] as String?;
          final errorMessage = errorBody?['message'] as String?;
          
          // Check if it's an RLS policy violation
          if (errorCode == '42501' || (errorMessage?.contains('row-level security') ?? false)) {
            _log(
              'RLS policy violation - Supabase not recognizing Firebase token. '
              'Firebase UID: ${_firebaseAuth.currentUser?.uid}, '
              'Customer ID in data: ${data['customer_id']}. '
              'Verify Firebase Third Party Auth is configured in Supabase Dashboard.',
              level: LogLevel.error,
              operation: 'insert',
            );
            
            // Provide helpful error message
            throw Exception(
              'RLS Policy Violation: Supabase is not extracting Firebase UID from token. '
              'This usually means:\n'
              '1. Firebase Third Party Auth is not properly configured in Supabase Dashboard\n'
              '2. The firebase_uid() function is not working (auth.jwt() returns null)\n'
              '3. JWT secret may need to be configured\n\n'
              'Current Firebase UID: ${_firebaseAuth.currentUser?.uid}\n'
              'Customer ID in booking: ${data['customer_id']}\n'
              'See FIREBASE_THIRD_PARTY_AUTH_SETUP.md for setup instructions.'
            );
          }
          
          // Token might be expired, try refreshing
          _log('Unauthorized (401), refreshing token and retrying', level: LogLevel.warning);
          final refreshedToken = await _getFirebaseIdToken(forceRefresh: true);
          if (refreshedToken != null && refreshedToken != idToken) {
            // Retry once with refreshed token
            final retryResponse = await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'apikey': _supabaseAnonKey!,
                'Authorization': 'Bearer $refreshedToken',
                'Prefer': 'return=representation',
              },
              body: jsonEncode(data),
            ).timeout(_requestTimeout);
            
            if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
              final responseData = jsonDecode(retryResponse.body);
              if (responseData is List) {
                return List<Map<String, dynamic>>.from(responseData);
              } else if (responseData is Map) {
                return [Map<String, dynamic>.from(responseData)];
              }
              return [];
            }
          }
        }
        
        final errorBody = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      _log(
        'Insert error: $e',
        level: LogLevel.error,
        operation: 'insert',
        table: table,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Query data from Supabase
  /// Uses direct HTTP requests with Firebase tokens (same as upsert/insert)
  Future<List<Map<String, dynamic>>?> query({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    int? limit,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      if (_supabaseUrl == null || _supabaseAnonKey == null) {
        throw Exception('Supabase not initialized');
      }

      // Get Firebase token (with refresh if needed)
      final idToken = await _getFirebaseIdToken(forceRefresh: false);
      
      if (idToken == null) {
        throw Exception('Missing authentication: Firebase token not available');
      }

      // Parse the Supabase URL to extract host and path
      final baseUri = Uri.parse(_supabaseUrl!);
      final pathSegments = ['rest', 'v1', table];
      
      // Build query parameters for PostgREST
      // PostgREST format: column=eq.value (where value is URL-encoded)
      // Note: Uri.queryParameters will encode values, but PostgREST needs 'eq.' prefix
      // So we manually construct query string for filters to avoid encoding 'eq.'
      final queryParts = <String>[];
      
      // Select clause (standard query parameter)
      queryParts.add('select=${Uri.encodeComponent(select ?? '*')}');
      
      // Add filters (PostgREST format: column=eq.value)
      // Manually construct to ensure 'eq.' is not encoded
      if (filters != null) {
        filters.forEach((key, value) {
          final encodedKey = Uri.encodeComponent(key);
          final encodedValue = Uri.encodeComponent(value.toString());
          queryParts.add('$encodedKey=eq.$encodedValue');
        });
      }
      
      // Add ordering (standard query parameter)
      if (orderBy != null) {
        final order = ascending ? 'asc' : 'desc';
        queryParts.add('order=${Uri.encodeComponent('$orderBy.$order')}');
      }
      
      // Add limit (standard query parameter)
      if (limit != null) {
        queryParts.add('limit=$limit');
      }
      
      // Build the final URI with manually constructed query string
      final queryString = queryParts.isNotEmpty ? queryParts.join('&') : '';
      final url = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        pathSegments: pathSegments,
      ).replace(query: queryString);

      // Log token info for debugging (masked)
      if (kDebugMode) {
        final tokenPreview = idToken.length > 50 
            ? '${idToken.substring(0, 20)}...${idToken.substring(idToken.length - 10)}'
            : idToken;
        _log('Using Firebase token for QUERY (length: ${idToken.length}, preview: $tokenPreview)', 
            level: LogLevel.debug, operation: 'query');
      }

      final response = await _executeWithRetry(
        operation: 'query',
        request: () => http.get(
          url,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $idToken',
            'Prefer': 'return=representation',
          },
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Query successful', level: LogLevel.info, operation: 'query', table: table);
          
          if (responseData is List) {
            return List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map) {
            return [Map<String, dynamic>.from(responseData)];
          }
          return [];
        } catch (e) {
          _log('Failed to parse response: $e', level: LogLevel.error, operation: 'query');
          throw Exception('Invalid response format: $e');
        }
      } else {
        // Handle 401 (unauthorized) - might be RLS issue
        if (response.statusCode == 401) {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorCode = errorBody?['code'] as String?;
          final errorMessage = errorBody?['message'] as String?;
          
          // Check if it's an RLS policy violation
          if (errorCode == '42501' || (errorMessage?.contains('row-level security') ?? false)) {
            _log(
              'RLS policy violation during query - Supabase not recognizing Firebase token. '
              'Firebase UID: ${_firebaseAuth.currentUser?.uid}. '
              'Verify Firebase Third Party Auth is configured in Supabase Dashboard.',
              level: LogLevel.error,
              operation: 'query',
            );
          }
          
          // Try refreshing token and retrying once
          _log('Unauthorized (401), refreshing token and retrying', level: LogLevel.warning);
          final refreshedToken = await _getFirebaseIdToken(forceRefresh: true);
          if (refreshedToken != null && refreshedToken != idToken) {
            final retryResponse = await http.get(
              url,
              headers: {
                'apikey': _supabaseAnonKey!,
                'Authorization': 'Bearer $refreshedToken',
                'Prefer': 'return=representation',
              },
            ).timeout(_requestTimeout);
            
            if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
              final responseData = jsonDecode(retryResponse.body);
              if (responseData is List) {
                return List<Map<String, dynamic>>.from(responseData);
              } else if (responseData is Map) {
                return [Map<String, dynamic>.from(responseData)];
              }
              return [];
            }
          }
        }
        
        final errorBody = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      _log('Query error: $e', level: LogLevel.error, operation: 'query', table: table, stackTrace: stackTrace);
      // Return null for query errors to allow graceful degradation
      // Callers should check for null and handle appropriately
      return null;
    }
  }

  /// Update data in Supabase
  /// Uses direct HTTP requests with Firebase tokens (same as upsert/insert/query)
  Future<List<Map<String, dynamic>>?> update({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    try {
      if (_supabaseUrl == null || _supabaseAnonKey == null) {
        throw Exception('Supabase not initialized');
      }

      // Get Firebase token (with refresh if needed)
      final idToken = await _getFirebaseIdToken(forceRefresh: false);
      
      if (idToken == null) {
        throw Exception('Missing authentication: Firebase token not available');
      }

      // Parse the Supabase URL to extract host and path
      final baseUri = Uri.parse(_supabaseUrl!);
      final pathSegments = ['rest', 'v1', table];
      
      // Build query parameters for PostgREST
      // PostgREST format: column=eq.value (where value is URL-encoded)
      final queryParts = <String>['select=*'];
      
      // Add filters (PostgREST format: column=eq.value)
      // Manually construct to ensure 'eq.' is not encoded
      filters.forEach((key, value) {
        final encodedKey = Uri.encodeComponent(key);
        final encodedValue = Uri.encodeComponent(value.toString());
        queryParts.add('$encodedKey=eq.$encodedValue');
      });
      
      // Build the final URI with manually constructed query string
      final queryString = queryParts.join('&');
      final url = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        pathSegments: pathSegments,
      ).replace(query: queryString);

      // Log token info for debugging (masked)
      if (kDebugMode) {
        final tokenPreview = idToken.length > 50 
            ? '${idToken.substring(0, 20)}...${idToken.substring(idToken.length - 10)}'
            : idToken;
        _log('Using Firebase token for UPDATE (length: ${idToken.length}, preview: $tokenPreview)', 
            level: LogLevel.debug, operation: 'update');
      }

      final response = await _executeWithRetry(
        operation: 'update',
        request: () => http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $idToken',
            'Prefer': 'return=representation',
          },
          body: jsonEncode(data),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = jsonDecode(response.body);
          _log('Update successful', level: LogLevel.info, operation: 'update', table: table);
          
          if (responseData is List) {
            return List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map) {
            return [Map<String, dynamic>.from(responseData)];
          }
          return [];
        } catch (e) {
          _log('Failed to parse response: $e', level: LogLevel.error, operation: 'update');
          throw Exception('Invalid response format: $e');
        }
      } else {
        // Handle 401 (unauthorized) - might be RLS issue
        if (response.statusCode == 401) {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorCode = errorBody?['code'] as String?;
          final errorMessage = errorBody?['message'] as String?;
          
          // Check if it's an RLS policy violation
          if (errorCode == '42501' || (errorMessage?.contains('row-level security') ?? false)) {
            _log(
              'RLS policy violation during update - Supabase not recognizing Firebase token. '
              'Firebase UID: ${_firebaseAuth.currentUser?.uid}. '
              'Verify Firebase Third Party Auth is configured in Supabase Dashboard.',
              level: LogLevel.error,
              operation: 'update',
            );
          }
          
          // Try refreshing token and retrying once
          _log('Unauthorized (401), refreshing token and retrying', level: LogLevel.warning);
          final refreshedToken = await _getFirebaseIdToken(forceRefresh: true);
          if (refreshedToken != null && refreshedToken != idToken) {
            final retryResponse = await http.patch(
              url,
              headers: {
                'Content-Type': 'application/json',
                'apikey': _supabaseAnonKey!,
                'Authorization': 'Bearer $refreshedToken',
                'Prefer': 'return=representation',
              },
              body: jsonEncode(data),
            ).timeout(_requestTimeout);
            
            if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
              final responseData = jsonDecode(retryResponse.body);
              if (responseData is List) {
                return List<Map<String, dynamic>>.from(responseData);
              } else if (responseData is Map) {
                return [Map<String, dynamic>.from(responseData)];
              }
              return [];
            }
          }
        }
        
        final errorBody = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      _log('Update error: $e', level: LogLevel.error, operation: 'update', table: table, stackTrace: stackTrace);
      return null;
    }
  }

  /// Delete data from Supabase
  Future<List<Map<String, dynamic>>?> delete({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      await _refreshSupabaseSession();
      
      if (_supabaseClient == null) {
        throw Exception('Supabase client not initialized');
      }

      dynamic query = _supabaseClient!.from(table).delete();

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.select().timeout(_requestTimeout);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      _log('Delete error: $e', level: LogLevel.error, operation: 'delete', table: table, stackTrace: stackTrace);
      return null;
    }
  }

  /// Subscribe to realtime changes
  Future<RealtimeChannel?> subscribe({
    required String channel,
    required String table,
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) async {
    try {
      await _refreshSupabaseSession();
      
      if (_supabaseClient == null) {
        throw Exception('Supabase client not initialized');
      }

      final realtimeChannel = _supabaseClient!.channel(channel)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (payload) => onInsert(Map<String, dynamic>.from(payload.newRecord)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          callback: (payload) => onUpdate(Map<String, dynamic>.from(payload.newRecord)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          callback: (payload) => onDelete(Map<String, dynamic>.from(payload.oldRecord)),
        )
        .subscribe();

      return realtimeChannel;
    } catch (e, stackTrace) {
      _log('Subscribe error: $e', level: LogLevel.error, operation: 'subscribe', table: table, stackTrace: stackTrace);
      return null;
    }
  }

  /// Structured logging (only in debug mode)
  void _log(
    String message, {
    LogLevel level = LogLevel.info,
    String? operation,
    String? table,
    StackTrace? stackTrace,
  }) {
    // Only log in debug mode for production safety
    if (!kDebugMode && level == LogLevel.debug) {
      return;
    }
    
    final prefix = _getLogPrefix(level);
    final context = [
      if (operation != null) 'op:$operation',
      if (table != null) 'table:$table',
    ].join(', ');
    
    final logMessage = context.isNotEmpty 
        ? '$prefix [FirebaseSupabase] $message ($context)'
        : '$prefix [FirebaseSupabase] $message';
    
    if (kDebugMode) {
      debugPrint(logMessage);
      if (stackTrace != null && level == LogLevel.error) {
        debugPrint('Stack trace: $stackTrace');
      }
    } else if (level == LogLevel.error) {
      // In production, only log errors
      print(logMessage);
      // TODO: Send to error tracking service (Sentry, Firebase Crashlytics, etc.)
    }
  }

  String _getLogPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// Get service metrics
  Map<String, int> getMetrics() {
    return {
      'success_count': _successCount,
      'failure_count': _failureCount,
      'retry_count': _retryCount,
    };
  }

  /// Reset metrics (useful for testing)
  void resetMetrics() {
    _successCount = 0;
    _failureCount = 0;
    _retryCount = 0;
  }

  String? get currentFirebaseUid => _firebaseAuth.currentUser?.uid;

  SupabaseClient? get client => _supabaseClient;
}

/// Log levels for structured logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

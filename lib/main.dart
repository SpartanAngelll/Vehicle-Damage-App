import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'screens/screens.dart';
import 'screens/customer_profile_setup_screen.dart';
import 'screens/customer_edit_profile_screen.dart';
import 'screens/search_professionals_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/service_professional_profile_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/my_service_requests_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/reviews_screen.dart';
import 'theme/theme.dart';
import 'services/services.dart';
import 'services/firebase_firestore_service.dart';
import 'services/chat_service.dart';
import 'services/api_key_service.dart';
import 'services/openai_service.dart';
import 'services/network_connectivity_service.dart';
import 'services/comprehensive_notification_service.dart';
import 'services/firebase_supabase_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Early log to confirm app is starting - use both print and debugPrint
  // These will appear in browser console (F12) for web
  final startMsg = '🚀 [Main] App starting...';
  debugPrint(startMsg);
  print(startMsg);
  
  // For web, also log to browser console explicitly
  if (kIsWeb) {
    final webMsg = '🌐 [Main] Running on web platform - check browser console (F12) for logs';
    debugPrint(webMsg);
    print(webMsg);
  }
  
  runApp(AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});
  
  Future<void> _initializeApp() async {
    // Use debugPrint for better visibility in Flutter
    debugPrint('🚀 [Main] Starting app initialization...');
    
    // Load environment variables from .env file
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ [Main] Environment variables loaded from .env file');
      print('✅ [Main] Environment variables loaded from .env file');
    } catch (e) {
      debugPrint('⚠️ [Main] Failed to load .env file: $e');
      debugPrint('⚠️ [Main] Make sure .env file exists in the root directory');
      print('⚠️ [Main] Failed to load .env file: $e');
      print('⚠️ [Main] Make sure .env file exists in the root directory');
    }
    
    // Initialize Firebase
    debugPrint('🔥 [Main] Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ [Main] Firebase initialized');
    
    // Initialize Supabase from environment variables
    try {
      debugPrint('🔍 [Main] Reading Supabase configuration from .env...');
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw Exception('SUPABASE_URL not found in .env file');
      }
      debugPrint('✅ [Main] SUPABASE_URL loaded from .env: ${supabaseUrl.substring(0, supabaseUrl.length > 30 ? 30 : supabaseUrl.length)}...');
      print('✅ [Main] SUPABASE_URL loaded from .env: ${supabaseUrl.substring(0, supabaseUrl.length > 30 ? 30 : supabaseUrl.length)}...');
      
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY not found in .env file');
      }
      
      // Log key info (masked for security)
      final keyPrefix = supabaseAnonKey.length > 20 ? supabaseAnonKey.substring(0, 20) : supabaseAnonKey;
      final keySuffix = supabaseAnonKey.length > 20 ? supabaseAnonKey.substring(supabaseAnonKey.length - 10) : '';
      final keyInfo = '✅ [Main] SUPABASE_ANON_KEY loaded from .env: ${keyPrefix}...${keySuffix} (length: ${supabaseAnonKey.length})';
      debugPrint(keyInfo);
      print(keyInfo);
      
      // Verify key format (should start with 'eyJ' for JWT)
      if (!supabaseAnonKey.startsWith('eyJ')) {
        final warning = '⚠️ [Main] WARNING: SUPABASE_ANON_KEY does not start with "eyJ" - may be invalid JWT format';
        debugPrint(warning);
        print(warning);
      }
      
      debugPrint('🔧 [Main] Initializing Supabase service...');
      await FirebaseSupabaseService.instance.initialize(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
      );
      debugPrint('✅ [Main] Supabase service initialized successfully');
      print('✅ [Main] Supabase service initialized successfully');
    } catch (e, stackTrace) {
      final errorMsg = '❌ [Main] Failed to initialize Supabase service: $e';
      debugPrint(errorMsg);
      debugPrint('Stack trace: $stackTrace');
      print(errorMsg);
      print('⚠️ [Main] Supabase features may not work properly');
      print('⚠️ [Main] Make sure SUPABASE_ANON_KEY is set in .env file');
      print('⚠️ [Main] Check that .env file exists in project root and contains valid keys');
    }
    
    // Initialize API keys
    await ApiKeyService.initialize();
    
    // Initialize network connectivity service
    await NetworkConnectivityService().initialize();
    
    // Initialize OpenAI service
    OpenAIService().initialize();
    
    // Initialize comprehensive notification service
    try {
      final notificationService = ComprehensiveNotificationService();
      await notificationService.initialize();
      print('✅ [Main] Comprehensive notification service initialized');
    } catch (e) {
      // Don't fail app startup if notification initialization fails
      print('⚠️ [Main] Failed to initialize notification service: $e');
      print('⚠️ [Main] Notifications may not work properly');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AppState()),
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => UserState()),
              ChangeNotifierProvider(create: (_) => NavigationState()),
              ChangeNotifierProvider(create: (_) => FirebaseAuthService()),
              Provider(create: (_) => FirebaseFirestoreService()),
            ],
            child: VehicleDamageApp(),
          );
        }
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

class VehicleDamageApp extends StatelessWidget {
  const VehicleDamageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, FirebaseAuthService>(
      builder: (context, themeProvider, authService, child) {
        return MaterialApp(
          title: 'Multi-Service Professional Network',
          theme: themeProvider.currentTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => AuthWrapper(authService: authService),
            '/homepage': (context) => HomepageScreen(),
            '/onboarding': (context) => OnboardingScreen(),
            '/permissions': (context) => PermissionRequestScreen(),
            '/login': (context) => LoginScreen(),
            '/customerProfileSetup': (context) => CustomerProfileSetupScreen(),
            '/customerEditProfile': (context) => CustomerEditProfileScreen(),
            '/ownerDashboard': (context) => OwnerDashboard(),
            '/repairmanDashboard': (context) => RepairmanDashboard(),
            '/settings': (context) => SettingsScreen(),
            '/serviceProfessionalRegistration': (context) => ServiceProfessionalRegistrationScreen(),
            '/serviceRequest': (context) => ServiceRequestScreen(),
            '/searchProfessionals': (context) => SearchProfessionalsScreen(),
            '/bookingIntegrationExample': (context) => BookingIntegrationExample(),
            '/serviceProfessionalProfile': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is String) {
                return Scaffold(
                  backgroundColor: Colors.grey[900],
                  body: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 1080,
                        maxHeight: 1080,
                      ),
                      width: MediaQuery.of(context).size.width > 1080 
                          ? 1080 
                          : MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height > 1080 
                          ? 1080 
                          : MediaQuery.of(context).size.height,
                      child: ServiceProfessionalProfileScreen(professionalId: args),
                    ),
                  ),
                );
              }
              return const Scaffold(
                body: Center(child: Text('Invalid professional ID')),
              );
            },
            '/chat': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is String) {
                // Load chat room info asynchronously
                return FutureBuilder(
                  future: ChatService().getChatRoom(args),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    if (snapshot.hasData && snapshot.data != null) {
                      final chatRoom = snapshot.data!;
                      final userState = Provider.of<UserState>(context, listen: false);
                      final otherUserName = userState.isOwner
                          ? chatRoom.professionalName
                          : chatRoom.customerName;
                      final otherUserPhotoUrl = userState.isOwner
                          ? chatRoom.professionalPhotoUrl
                          : chatRoom.customerPhotoUrl;
                      
                      return ChatScreen(
                        chatRoomId: args,
                        otherUserName: otherUserName,
                        otherUserPhotoUrl: otherUserPhotoUrl,
                      );
                    }
                    
                    return const Scaffold(
                      body: Center(child: Text('Chat room not found')),
                    );
                  },
                );
              }
              return const Scaffold(
                body: Center(child: Text('Invalid chat room ID')),
              );
            },
            '/chatList': (context) => ChatListScreen(),
            '/myServiceRequests': (context) => MyServiceRequestsScreen(),
            '/myBookings': (context) => MyBookingsScreen(),
            '/reviews': (context) => ReviewsScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final FirebaseAuthService authService;
  
  const AuthWrapper({super.key, required this.authService});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    // Listen to Firebase auth state changes
    widget.authService.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeFCMToken(String userId) async {
    try {
      // Use ComprehensiveNotificationService instead of SimpleNotificationService
      final notificationService = ComprehensiveNotificationService();
      
      // Ensure the service is initialized
      if (!notificationService.isInitialized) {
        await notificationService.initialize();
      }
      
      // Explicitly ensure FCM token is saved now that we have userId
      await notificationService.ensureFCMTokenSaved();
      
      print('✅ [Main] FCM token initialized for user: $userId');
    } catch (e) {
      print('❌ [Main] Failed to initialize FCM token for user $userId: $e');
    }
  }

  Future<void> _initializeAppData() async {
    try {
      final initService = AppInitializationService();
      await initService.initializeApp();
    } catch (e) {
      print('Failed to initialize app data: $e');
    }
  }

  Future<bool> _checkServiceProfessionalProfile(String userId) async {
    try {
      final firestoreService = context.read<FirebaseFirestoreService>();
      final professionalProfile = await firestoreService.getServiceProfessional(userId);
      if (professionalProfile != null) {
        debugPrint('🔍 [Main] Service professional profile found for user: $userId');
        return true;
      } else {
        debugPrint('🔍 [Main] No service professional profile found for user: $userId');
        return false;
      }
    } catch (e) {
      debugPrint('🔍 [Main] Error checking service professional profile for user $userId: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirebaseAuthService, UserState>(
      builder: (context, authService, userState, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authService.isSignedIn && authService.user != null) {
          // Check if UserState is already initialized
          if (userState.isAuthenticated && userState.userId != null) {
            // UserState is already initialized, determine appropriate route
            if (userState.isOwner) {
              // Use a post-frame callback to avoid navigation during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && ModalRoute.of(context)?.settings.name != '/ownerDashboard') {
                  Navigator.pushReplacementNamed(context, '/ownerDashboard');
                }
              });
              
              // Initialize FCM token for already authenticated user
              _initializeFCMToken(userState.userId!);
              
              // Initialize app data after authentication
              _initializeAppData();
              
              return _getDashboardForUser(userState);
            } else if (userState.isRepairman || userState.isServiceProfessional) {
              // For service professionals, check if they have a complete profile asynchronously
              return FutureBuilder<bool>(
                future: _checkServiceProfessionalProfile(userState.userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final hasProfile = snapshot.data ?? false;
                  final route = hasProfile ? '/repairmanDashboard' : '/serviceProfessionalRegistration';
                  
                  // Use a post-frame callback to avoid navigation during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && ModalRoute.of(context)?.settings.name != route) {
                      Navigator.pushReplacementNamed(context, route);
                    }
                  });
                  
                  // Initialize FCM token for already authenticated user
                  _initializeFCMToken(userState.userId!);
                  
                  // Initialize app data after authentication
                  _initializeAppData();
                  
                  // Return appropriate content based on route
                  if (route == '/serviceProfessionalRegistration') {
                    return ServiceProfessionalRegistrationScreen();
                  } else {
                    return _getDashboardForUser(userState);
                  }
                },
              );
            } else {
              // Default to owner dashboard
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && ModalRoute.of(context)?.settings.name != '/ownerDashboard') {
                  Navigator.pushReplacementNamed(context, '/ownerDashboard');
                }
              });
              
              _initializeFCMToken(userState.userId!);
              _initializeAppData();
              return _getDashboardForUser(userState);
            }
          }
          
          // UserState not initialized yet, load profile from Firestore
          return FutureBuilder<Map<String, dynamic>?>(
            future: context.read<FirebaseFirestoreService>().getUserProfile(authService.user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                // Initialize UserState with Firebase data
                final userData = snapshot.data!;
                
                // Use 'role' field from Firestore, fallback to 'userType' for backward compatibility
                final userType = userData['role'] ?? userData['userType'] ?? 'owner';
                
                debugPrint('🔍 [Main] User data from Firestore: $userData');
                debugPrint('🔍 [Main] Extracted userType: $userType');
                debugPrint('🔍 [Main] User role field: ${userData['role']}');
                debugPrint('🔍 [Main] User userType field: ${userData['userType']}');
                
                userState.initializeFromFirebase(
                  userId: authService.user!.uid,
                  email: userData['email'] ?? authService.user!.email ?? '',
                  userType: userType,
                  phoneNumber: userData['phone'],
                  bio: userData['bio'],
                  currentUser: authService.user,
                );

                // Initialize FCM token for the user
                _initializeFCMToken(authService.user!.uid);

                // Initialize app data after authentication
                _initializeAppData();

                // Navigate to appropriate dashboard based on user type and profile completeness
                if (userType == 'owner') {
                  // Use a post-frame callback to avoid navigation during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && ModalRoute.of(context)?.settings.name != '/ownerDashboard') {
                      Navigator.pushReplacementNamed(context, '/ownerDashboard');
                    }
                  });
                  
                  // Initialize FCM token for the user
                  _initializeFCMToken(authService.user!.uid);

                  // Initialize app data after authentication
                  _initializeAppData();
                  
                  return _getDashboardForUser(userState);
                } else {
                  // For service professionals, check if they have a complete profile asynchronously
                  return FutureBuilder<bool>(
                    future: _checkServiceProfessionalProfile(authService.user!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final hasProfile = snapshot.data ?? false;
                      final route = hasProfile ? '/repairmanDashboard' : '/serviceProfessionalRegistration';
                      
                      // Use a post-frame callback to avoid navigation during build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && ModalRoute.of(context)?.settings.name != route) {
                          Navigator.pushReplacementNamed(context, route);
                        }
                      });
                      
                      // Initialize FCM token for the user
                      _initializeFCMToken(authService.user!.uid);

                      // Initialize app data after authentication
                      _initializeAppData();
                      
                      // Return appropriate content based on route
                      if (route == '/serviceProfessionalRegistration') {
                        return ServiceProfessionalRegistrationScreen();
                      } else {
                        return _getDashboardForUser(userState);
                      }
                    },
                  );
                }
              }

              // Show loading while determining route
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }

        // User is not signed in, show homepage
        return HomepageScreen();
      },
    );
  }

  Widget _getDashboardForUser(UserState userState) {
    if (userState.isRepairman || userState.isServiceProfessional) {
      return RepairmanDashboard();
    } else {
      return OwnerDashboard();
    }
  }
}

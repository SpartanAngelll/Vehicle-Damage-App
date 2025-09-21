import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'screens/screens.dart';
import 'screens/customer_profile_setup_screen.dart';
import 'screens/customer_edit_profile_screen.dart';
import 'theme/theme.dart';
import 'services/services.dart';
import 'services/firebase_firestore_service.dart';
import 'services/api_key_service.dart';
import 'services/openai_service.dart';
import 'services/network_connectivity_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});
  
  Future<void> _initializeApp() async {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize API keys
    await ApiKeyService.initialize();
    
    // Initialize network connectivity service
    await NetworkConnectivityService().initialize();
    
    // Initialize OpenAI service
    OpenAIService().initialize();
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
          home: AuthWrapper(authService: authService),
          routes: {
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
      final notificationService = SimpleNotificationService();
      await notificationService.initialize();
      print('FCM token initialized for user: $userId');
    } catch (e) {
      print('Failed to initialize FCM token for user $userId: $e');
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

        // User is not signed in, show splash screen
        return SplashScreen();
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

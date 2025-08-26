import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'screens/screens.dart';
import 'theme/theme.dart';
import 'services/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
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
          title: 'Vehicle Damage Estimator',
          theme: themeProvider.currentTheme,
          themeMode: themeProvider.themeMode,
          home: AuthWrapper(authService: authService),
          routes: {
            '/onboarding': (context) => OnboardingScreen(),
            '/permissions': (context) => PermissionRequestScreen(),
            '/login': (context) => LoginScreen(),
            '/ownerDashboard': (context) => OwnerDashboard(),
            '/repairmanDashboard': (context) => RepairmanDashboard(),
            '/settings': (context) => SettingsScreen(),
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
            // UserState is already initialized, show appropriate dashboard
            final route = userState.isRepairman ? '/repairmanDashboard' : '/ownerDashboard';
            
            // Use a post-frame callback to avoid navigation during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.settings.name != route) {
                Navigator.pushReplacementNamed(context, route);
              }
            });
            
            // Return current route content
            return _getDashboardForUser(userState);
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
                
                userState.initializeFromFirebase(
                  userId: authService.user!.uid,
                  email: userData['email'] ?? authService.user!.email ?? '',
                  userType: userData['userType'] ?? 'owner',
                  phoneNumber: userData['phoneNumber'],
                  bio: userData['bio'],
                );

                // Navigate to appropriate dashboard
                final userType = userData['userType'] ?? 'owner';
                final route = userType == 'owner' ? '/ownerDashboard' : '/repairmanDashboard';
                
                // Use a post-frame callback to avoid navigation during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && ModalRoute.of(context)?.settings.name != route) {
                    Navigator.pushReplacementNamed(context, route);
                  }
                });
                
                // Return dashboard content immediately
                return _getDashboardForUser(userState);
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
    if (userState.isRepairman) {
      return RepairmanDashboard();
    } else {
      return OwnerDashboard();
    }
  }
}

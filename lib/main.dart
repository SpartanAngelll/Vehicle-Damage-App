import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'screens/screens.dart';
import 'theme/theme.dart';

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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Vehicle Damage Estimator',
          theme: themeProvider.currentTheme,
          themeMode: themeProvider.themeMode,
          home: SplashScreen(),
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

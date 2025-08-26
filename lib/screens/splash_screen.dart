import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import '../services/local_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingStatus();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final hasCompletedOnboarding = await LocalStorageService.isOnboardingCompleted();
      if (mounted) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              hasCompletedOnboarding ? '/login' : '/onboarding',
            );
          }
        });
      }
    } catch (e) {
      // If there's an error checking onboarding status, default to onboarding
      if (mounted) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        });
      }
    }
  }

  void _startOnboarding() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Vehicle icon representing the app',
              child: Icon(
                Icons.directions_car, 
                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 80, tablet: 100, desktop: 120), 
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 30, tablet: 40, desktop: 50)),
            Semantics(
              label: 'App tagline: Snap, Upload. Get an Estimate.',
              child: Text(
                "Snap, Upload.\nGet an Estimate.", 
                textAlign: TextAlign.center,
                semanticsLabel: 'Snap, Upload. Get an Estimate.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 28, tablet: 32, desktop: 36), 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                )
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 40, tablet: 50, desktop: 60)),
            Semantics(
              label: 'Button to start onboarding',
              button: true,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 24, tablet: 32, desktop: 40),
                    vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
                  ),
                ),
                onPressed: _startOnboarding,
                child: Text("Get Started"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: _buildMobileLayout(context),
      ),
    );
  }
}

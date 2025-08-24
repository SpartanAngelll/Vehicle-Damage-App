import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import '../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Welcome to Vehicle Damage App',
      description: 'Easily report vehicle damage and get repair estimates from professionals in your area.',
      icon: Icons.car_crash,
      color: Colors.blue,
    ),
    OnboardingSlide(
      title: 'For Vehicle Owners',
      description: 'Take photos of damage, add descriptions, and receive estimates from repair professionals.',
      icon: Icons.person,
      color: Colors.green,
    ),
    OnboardingSlide(
      title: 'For Repair Professionals',
      description: 'View damage reports, submit estimates, and help vehicle owners get back on the road.',
      icon: Icons.build,
      color: Colors.orange,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() async {
    try {
      await StorageService.setOnboardingCompleted();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/permissions');
      }
    } catch (e) {
      // If saving fails, still navigate to permissions
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/permissions');
      }
    }
  }

  void _skipOnboarding() async {
    try {
      await StorageService.setOnboardingCompleted();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/permissions');
      }
    } catch (e) {
      // If saving fails, still navigate to permissions
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/permissions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(context, _slides[index]);
            },
          ),
        ),
        _buildBottomControls(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(context, _slides[index]);
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildBottomControls(context),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(context, _slides[index]);
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildBottomControls(context),
        ),
      ],
    );
  }

  Widget _buildSlide(BuildContext context, OnboardingSlide slide) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: '${slide.title} icon',
            child: Icon(
              slide.icon,
              size: ResponsiveUtils.getResponsiveIconSize(
                context,
                mobile: 80,
                tablet: 100,
                desktop: 120,
              ),
              color: slide.color,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 24, tablet: 32, desktop: 40)),
          Semantics(
            label: 'Onboarding slide title',
            header: true,
            child: Text(
              slide.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 24,
                  tablet: 28,
                  desktop: 32,
                ),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
          Semantics(
            label: 'Onboarding slide description',
            child: Text(
              slide.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => _buildPageIndicator(context, index),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 24, tablet: 32, desktop: 40)),
          
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: Semantics(
                    label: 'Go to previous slide',
                    button: true,
                    child: TextButton(
                      onPressed: _previousPage,
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              Expanded(
                child: Semantics(
                  label: _currentPage == _slides.length - 1 ? 'Finish onboarding' : 'Go to next slide',
                  button: true,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 24, desktop: 32),
                        vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Skip button
          Semantics(
            label: 'Skip onboarding and go to login',
            button: true,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, int index) {
    final isActive = index == _currentPage;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 4, tablet: 6, desktop: 8),
      ),
      width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12),
      height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

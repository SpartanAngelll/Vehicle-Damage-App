import 'dart:async';
import 'package:flutter/material.dart';

class InstructionalOverlay extends StatefulWidget {
  const InstructionalOverlay({super.key});

  @override
  State<InstructionalOverlay> createState() => _InstructionalOverlayState();
}

class _InstructionalOverlayState extends State<InstructionalOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  int _currentIndex = 0;
  Timer? _timer;

  final List<String> _instructions = [
    'Select The Type of Service You Need',
    'Provide Detailed Information About Your Request',
    'Upload Relevant Photos or Documents',
    'Get Matched With Qualified Professionals',
    'Receive Estimates And Choose The Best Option',
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutBack,
    ));

    _startCycling();
  }

  void _startCycling() {
    _fadeController.forward();
    _bounceController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _cycleToNext();
    });
  }

  void _cycleToNext() {
    if (!mounted) return;
    
    setState(() {
      _currentIndex = (_currentIndex + 1) % _instructions.length;
    });
    
    // Reset animations
    _fadeController.reset();
    _bounceController.reset();
    
    // Start new animations
    _fadeController.forward();
    _bounceController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - _bounceAnimation.value)), // Bounce from bottom
              child: Center(
                child: Text(
                  _instructions[_currentIndex],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    // fontFamily: 'Poppins', // Will be enabled when fonts are added
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

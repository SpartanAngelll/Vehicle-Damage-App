import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';

class ServiceProfessionalRegistrationScreen extends StatefulWidget {
  const ServiceProfessionalRegistrationScreen({super.key});

  @override
  State<ServiceProfessionalRegistrationScreen> createState() => _ServiceProfessionalRegistrationScreenState();
}

class _ServiceProfessionalRegistrationScreenState extends State<ServiceProfessionalRegistrationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Registration'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildRegistrationForm(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildHeader(context),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildRegistrationForm(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _buildHeader(context),
          ),
        ),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _buildRegistrationForm(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.person_add,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Join Our Professional Network',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connect with customers looking for your services. Build your business and grow your client base.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildBenefits(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.visibility,
        'title': 'Get Discovered',
        'description': 'Customers can find you based on service categories and location',
      },
      {
        'icon': Icons.notifications,
        'title': 'Real-Time Alerts',
        'description': 'Receive instant notifications about new service requests',
      },
      {
        'icon': Icons.rate_review,
        'title': 'Build Reputation',
        'description': 'Collect reviews and ratings to build trust with customers',
      },
      {
        'icon': Icons.business,
        'title': 'Grow Your Business',
        'description': 'Access to a larger customer base and more opportunities',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Join?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      benefit['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    return ServiceProfessionalRegistrationForm(
      onRegistrationComplete: (ServiceProfessional professional) {
        _handleRegistrationComplete(professional, context);
      },
    );
  }

  void _handleRegistrationComplete(ServiceProfessional professional, BuildContext context) {
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Complete!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to our professional network, ${professional.fullName}!'),
              const SizedBox(height: 16),
              Text(
                'Your profile is now active and customers can find you for:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...professional.categoryIds.map((categoryId) => Text('• ${_getCategoryDisplayName(categoryId)}')),
              const SizedBox(height: 16),
              Text(
                'What happens next:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('• You\'ll receive notifications about new service requests'),
              Text('• Customers can view your profile and contact you'),
              Text('• Start building your reputation with reviews'),
              Text('• Grow your business with our platform'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/repairmanDashboard');
            },
            child: const Text('View My Profile'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/repairmanDashboard');
            },
            child: const Text('Start Browsing Requests'),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String categoryId) {
    switch (categoryId) {
      case 'mechanics':
        return 'Automotive Services';
      case 'plumbers':
        return 'Plumbing Services';
      case 'electricians':
        return 'Electrical Services';
      case 'carpenters':
        return 'Carpentry Services';
      case 'cleaners':
        return 'Cleaning Services';
      case 'landscapers':
        return 'Landscaping Services';
      case 'painters':
        return 'Painting Services';
      case 'appliance_repair':
        return 'Appliance Repair';
      case 'hvac_specialists':
        return 'HVAC Services';
      case 'it_support':
        return 'IT Support';
      case 'security_systems':
        return 'Security Systems';
      case 'hairdressers_barbers':
        return 'Hair Services';
      case 'makeup_artists':
        return 'Makeup Services';
      case 'nail_technicians':
        return 'Nail Services';
      case 'lash_technicians':
        return 'Lash Services';
      default:
        return 'Professional Services';
    }
  }
}


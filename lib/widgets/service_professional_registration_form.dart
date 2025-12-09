import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/firebase_firestore_service.dart';
import '../services/profile_auto_fill_service.dart';
import '../widgets/service_category_selector.dart';
import '../widgets/image_upload_widget.dart';

class ServiceProfessionalRegistrationForm extends StatefulWidget {
  final Function(ServiceProfessional) onRegistrationComplete;

  const ServiceProfessionalRegistrationForm({
    super.key,
    required this.onRegistrationComplete,
  });

  @override
  State<ServiceProfessionalRegistrationForm> createState() => _ServiceProfessionalRegistrationFormState();
}

class _ServiceProfessionalRegistrationFormState extends State<ServiceProfessionalRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  
  List<String> _selectedCategoryIds = [];
  List<String> _specializations = [];
  List<String> _certifications = [];
  List<String> _serviceAreas = [];
  String? _profilePhotoUrl;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Category-specific specialization controllers
  final Map<String, TextEditingController> _specializationControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeSpecializationControllers();
    _autoFillFromUserState();
  }
  
  void _autoFillFromUserState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = context.read<UserState>();
      
      // Get auto-fill data and suggestions
      final suggestions = ProfileAutoFillService.getSuggestedValues(userState);
      
      // Auto-fill form controllers
      final controllers = {
        'fullName': _fullNameController,
        'phone': _phoneController,
        'bio': _bioController,
        'businessName': _businessNameController,
        'businessAddress': _businessAddressController,
        'businessPhone': _businessPhoneController,
        'website': _websiteController,
        'yearsExperience': _yearsExperienceController,
      };
      
      ProfileAutoFillService.populateFormControllers(
        controllers: controllers,
        userState: userState,
        suggestions: suggestions,
      );
      
      // Set profile photo if available
      if (userState.profilePhotoUrl != null) {
        _profilePhotoUrl = userState.profilePhotoUrl;
      }
      
      // Show suggestions to user if any
      if (suggestions.isNotEmpty) {
        _showAutoFillSuggestions(suggestions);
      }
    });
  }
  
  void _showAutoFillSuggestions(Map<String, dynamic> suggestions) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Profile Suggestions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('We\'ve found some information that might help complete your profile:'),
              const SizedBox(height: 16),
              if (suggestions['suggestedFullName'] != null)
                Text('• Suggested name: ${suggestions['suggestedFullName']}'),
              if (suggestions['suggestedUsername'] != null)
                Text('• Suggested username: ${suggestions['suggestedUsername']}'),
              if (suggestions['suggestedBusinessName'] != null)
                Text('• Suggested business name: ${suggestions['suggestedBusinessName']}'),
              const SizedBox(height: 16),
              const Text('You can edit these suggestions in the form below.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  void _initializeSpecializationControllers() {
    // Initialize controllers for category-specific specializations
    _specializationControllers['mechanics'] = TextEditingController(); // Auto repair, maintenance
    _specializationControllers['plumbers'] = TextEditingController(); // Installation, repair, maintenance
    _specializationControllers['electricians'] = TextEditingController(); // Wiring, installation, repair
    _specializationControllers['carpenters'] = TextEditingController(); // Woodworking, construction
    _specializationControllers['cleaners'] = TextEditingController(); // House cleaning, maintenance
    _specializationControllers['landscapers'] = TextEditingController(); // Garden, outdoor maintenance
    _specializationControllers['painters'] = TextEditingController(); // Interior, exterior painting
    _specializationControllers['appliance_repair'] = TextEditingController(); // Appliance types
    _specializationControllers['hvac_specialists'] = TextEditingController(); // AC, heating systems
    _specializationControllers['it_support'] = TextEditingController(); // Computer, network support
    _specializationControllers['security_systems'] = TextEditingController(); // CCTV, alarms
    _specializationControllers['hairdressers_barbers'] = TextEditingController(); // Hair services
    _specializationControllers['makeup_artists'] = TextEditingController(); // Makeup services
    _specializationControllers['nail_technicians'] = TextEditingController(); // Nail services
    _specializationControllers['lash_technicians'] = TextEditingController(); // Lash services
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _websiteController.dispose();
    _yearsExperienceController.dispose();
    
    // Dispose specialization controllers
    for (final controller in _specializationControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Professional Registration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Profile Photo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  ImageUploadWidget(
                    title: 'Upload Profile Photo',
                    subtitle: 'Add a professional photo to help customers recognize you',
                    maxImages: 1,
                    onImagesSelected: (images) {},
                    onImagesUploaded: (imageUrls) {
                      if (imageUrls.isNotEmpty) {
                        setState(() {
                          _profilePhotoUrl = imageUrls.first;
                        });
                      }
                    },
                  ),
                  
                  if (_profilePhotoUrl == null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A profile photo helps build trust with customers and increases your chances of getting hired.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Basic Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Your full name as it appears on documents',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Your contact phone number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Professional Bio',
                      hintText: 'Tell customers about your experience and expertise',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please write a professional bio';
                      }
                      if (value.length < 20) {
                        return 'Bio must be at least 20 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Service Categories
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  FutureBuilder<List<ServiceCategory>>(
                    future: ServiceCategoryService().getAllCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading service categories...'),
                          ],
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading categories: ${snapshot.error}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  // This will trigger a rebuild and retry
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        );
                      }
                      
                      final availableCategories = snapshot.data ?? [];
                      
                      if (availableCategories.isEmpty) {
                        return Column(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No service categories available',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await ServiceCategoryService().seedDefaultCategories();
                                  setState(() {
                                    // This will trigger a rebuild
                                  });
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to seed categories: $e'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Initialize Categories'),
                            ),
                          ],
                        );
                      }
                      
                      return ServiceCategorySelector(
                        availableCategories: availableCategories,
                        selectedCategoryIds: _selectedCategoryIds,
                        onCategoriesChanged: (categoryIds) {
                          setState(() {
                            _selectedCategoryIds = categoryIds;
                            _specializations.clear(); // Clear specializations when categories change
                          });
                        },
                      );
                    },
                  ),
                  
                  if (_selectedCategoryIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Selected Categories: ${_selectedCategoryIds.join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Specializations
          if (_selectedCategoryIds.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specializations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    ..._buildSpecializationFields(),
                    
                    const SizedBox(height: 16),
                    
                    // Add custom specialization
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Add Custom Specialization',
                              hintText: 'Enter additional specialization',
                              prefixIcon: Icon(Icons.add),
                            ),
                            onFieldSubmitted: (value) {
                              if (value.isNotEmpty && !_specializations.contains(value)) {
                                setState(() {
                                  _specializations.add(value);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            final controller = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Add Specialization'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Specialization',
                                    hintText: 'e.g., Advanced diagnostics, custom installations',
                                  ),
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final value = controller.text.trim();
                                      if (value.isNotEmpty && !_specializations.contains(value)) {
                                        setState(() {
                                          _specializations.add(value);
                                        });
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    
                    if (_specializations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _specializations.map((spec) => Chip(
                          label: Text(spec),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _specializations.remove(spec);
                            });
                          },
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Business Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name (Optional)',
                      hintText: 'Your business or company name',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _businessAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address (Optional)',
                      hintText: 'Your business address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _businessPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Business Phone (Optional)',
                      hintText: 'Your business phone number',
                      prefixIcon: Icon(Icons.business_center),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website (Optional)',
                      hintText: 'Your business website URL',
                      prefixIcon: Icon(Icons.web),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Experience & Certifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Experience & Credentials',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _yearsExperienceController,
                    decoration: const InputDecoration(
                      labelText: 'Years of Experience',
                      hintText: 'Number of years in this field',
                      prefixIcon: Icon(Icons.work),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter years of experience';
                      }
                      final years = int.tryParse(value);
                      if (years == null || years < 0) {
                        return 'Please enter a valid number of years';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Add certifications
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Add Certification',
                            hintText: 'e.g., Licensed electrician, certified mechanic',
                            prefixIcon: Icon(Icons.verified),
                          ),
                          onFieldSubmitted: (value) {
                            if (value.isNotEmpty && !_certifications.contains(value)) {
                              setState(() {
                                _certifications.add(value);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final controller = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Add Certification'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Certification',
                                  hintText: 'e.g., Licensed electrician, certified mechanic',
                                ),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final value = controller.text.trim();
                                    if (value.isNotEmpty && !_certifications.contains(value)) {
                                      setState(() {
                                        _certifications.add(value);
                                      });
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  
                  if (_certifications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _certifications.map((cert) => Chip(
                        label: Text(cert),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _certifications.remove(cert);
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Service Areas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Areas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Add Service Area',
                            hintText: 'e.g., Downtown, North Side, 10-mile radius',
                            prefixIcon: Icon(Icons.map),
                          ),
                          onFieldSubmitted: (value) {
                            if (value.isNotEmpty && !_serviceAreas.contains(value)) {
                              setState(() {
                                _serviceAreas.add(value);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final controller = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Add Service Area'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Service Area',
                                  hintText: 'e.g., Downtown, North Side, 10-mile radius',
                                ),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final value = controller.text.trim();
                                    if (value.isNotEmpty && !_serviceAreas.contains(value)) {
                                      setState(() {
                                        _serviceAreas.add(value);
                                      });
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  
                  if (_serviceAreas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceAreas.map((area) => Chip(
                        label: Text(area),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _serviceAreas.remove(area);
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubmit() && !_isSubmitting ? _submitRegistration : null,
              icon: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
              label: Text(_isSubmitting ? 'Creating Profile...' : 'Complete Registration'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpecializationFields() {
    final fields = <Widget>[];
    
    for (final categoryId in _selectedCategoryIds) {
      if (_specializationControllers.containsKey(categoryId)) {
        fields.addAll([
          Text(
            _getCategoryDisplayName(categoryId),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _specializationControllers[categoryId]!,
            decoration: InputDecoration(
              labelText: 'Specializations',
              hintText: _getSpecializationHint(categoryId),
              prefixIcon: Icon(_getCategoryIcon(categoryId)),
            ),
            maxLines: 2,
            onChanged: (value) {
              if (value.isNotEmpty) {
                final specializations = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                setState(() {
                  _specializations.removeWhere((spec) => _specializations.contains(spec));
                  _specializations.addAll(specializations);
                });
              }
            },
          ),
          const SizedBox(height: 16),
        ]);
      }
    }
    
    return fields;
  }

  String _getCategoryDisplayName(String categoryId) {
    switch (categoryId) {
      case 'mechanics':
        return 'Automotive Specializations';
      case 'plumbers':
        return 'Plumbing Specializations';
      case 'electricians':
        return 'Electrical Specializations';
      case 'carpenters':
        return 'Carpentry Specializations';
      case 'cleaners':
        return 'Cleaning Specializations';
      case 'landscapers':
        return 'Landscaping Specializations';
      case 'painters':
        return 'Painting Specializations';
      case 'appliance_repair':
        return 'Appliance Repair Specializations';
      case 'hvac_specialists':
        return 'HVAC Specializations';
      case 'it_support':
        return 'IT Support Specializations';
      case 'security_systems':
        return 'Security System Specializations';
      case 'hairdressers_barbers':
        return 'Hair Service Specializations';
      case 'makeup_artists':
        return 'Makeup Service Specializations';
      case 'nail_technicians':
        return 'Nail Service Specializations';
      case 'lash_technicians':
        return 'Lash Service Specializations';
      default:
        return 'Specializations';
    }
  }

  String _getSpecializationHint(String categoryId) {
    switch (categoryId) {
      case 'mechanics':
        return 'e.g., Engine repair, transmission, brakes, diagnostics';
      case 'plumbers':
        return 'e.g., Pipe installation, drain cleaning, water heaters';
      case 'electricians':
        return 'e.g., Wiring, panel installation, troubleshooting';
      case 'carpenters':
        return 'e.g., Cabinet making, framing, trim work';
      case 'cleaners':
        return 'e.g., Deep cleaning, move-in/out, regular maintenance';
      case 'landscapers':
        return 'e.g., Garden design, lawn maintenance, irrigation';
      case 'painters':
        return 'e.g., Interior painting, exterior painting, texture work';
      case 'appliance_repair':
        return 'e.g., Refrigerators, washers, dryers, ovens';
      case 'hvac_specialists':
        return 'e.g., AC repair, heating systems, ductwork';
      case 'it_support':
        return 'e.g., Computer repair, networking, software support';
      case 'security_systems':
        return 'e.g., CCTV, alarms, access control, smart locks';
      case 'hairdressers_barbers':
        return 'e.g., Haircuts, coloring, styling, treatments';
      case 'makeup_artists':
        return 'e.g., Wedding makeup, party makeup, photoshoots';
      case 'nail_technicians':
        return 'e.g., Manicures, pedicures, acrylics, nail art';
      case 'lash_technicians':
        return 'e.g., Lash extensions, lifts, tints, fills';
      default:
        return 'Enter your specializations';
    }
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'mechanics':
        return Icons.build;
      case 'plumbers':
        return Icons.plumbing;
      case 'electricians':
        return Icons.electrical_services;
      case 'carpenters':
        return Icons.handyman;
      case 'cleaners':
        return Icons.cleaning_services;
      case 'landscapers':
        return Icons.landscape;
      case 'painters':
        return Icons.format_paint;
      case 'appliance_repair':
        return Icons.kitchen;
      case 'hvac_specialists':
        return Icons.ac_unit;
      case 'it_support':
        return Icons.computer;
      case 'security_systems':
        return Icons.security;
      case 'hairdressers_barbers':
        return Icons.content_cut;
      case 'makeup_artists':
        return Icons.face;
      case 'nail_technicians':
        return Icons.brush;
      case 'lash_technicians':
        return Icons.visibility;
      default:
        return Icons.work;
    }
  }

  bool _canSubmit() {
    // Check basic requirements
    final hasCategories = _selectedCategoryIds.isNotEmpty;
    final hasFullName = _fullNameController.text.trim().isNotEmpty && _fullNameController.text.trim().length >= 2;
    final hasPhone = _phoneController.text.trim().isNotEmpty;
    final hasBio = _bioController.text.trim().isNotEmpty && _bioController.text.trim().length >= 20;
    final hasYears = _yearsExperienceController.text.trim().isNotEmpty && 
                     int.tryParse(_yearsExperienceController.text.trim()) != null;
    
    final canSubmit = hasCategories && hasFullName && hasPhone && hasBio && hasYears;
    
    print('🔍 [RegistrationForm] Form validation check:');
    print('  - Categories selected: $hasCategories (${_selectedCategoryIds.length} categories)');
    print('  - Full name: $hasFullName (length: ${_fullNameController.text.trim().length}, required: >= 2) ("${_fullNameController.text}")');
    print('  - Phone: $hasPhone ("${_phoneController.text}")');
    print('  - Bio: $hasBio (length: ${_bioController.text.trim().length}, required: >= 20) ("${_bioController.text}")');
    print('  - Years experience: $hasYears ("${_yearsExperienceController.text}")');
    print('  - Can submit: $canSubmit');
    
    return canSubmit;
  }

  Future<void> _submitRegistration() async {
    print('🔍 [RegistrationForm] Submit button pressed!');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [RegistrationForm] Form validation failed');
      // Show error message to user
      setState(() {
        _errorMessage = 'Please fix the validation errors above. Check that your name is at least 2 characters and bio is at least 20 characters.';
      });
      // Scroll to first error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fix the form errors. Name must be at least 2 characters and bio must be at least 20 characters.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    
    print('✅ [RegistrationForm] Form validation passed');

    if (_selectedCategoryIds.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one service category';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userState = context.read<UserState>();
      final firestoreService = context.read<FirebaseFirestoreService>();
      
      print('🔍 [RegistrationForm] Starting registration submission');
      print('🔍 [RegistrationForm] User authenticated: ${userState.isAuthenticated}');
      print('🔍 [RegistrationForm] User ID: ${userState.userId}');
      print('🔍 [RegistrationForm] Selected categories: $_selectedCategoryIds');
      
      if (!userState.isAuthenticated || userState.userId == null) {
        throw Exception('User not authenticated');
      }

      // Build specializations from category-specific fields
      _buildSpecializationsFromControllers();
      print('🔍 [RegistrationForm] Specializations built: $_specializations');

      // Create service professional profile
      print('🔍 [RegistrationForm] Creating ServiceProfessional object...');
      final professional = ServiceProfessional(
        id: userState.userId!,
        userId: userState.userId!,
        email: userState.email ?? '',
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        bio: _bioController.text,
        profilePhotoUrl: _profilePhotoUrl,
        categoryIds: _selectedCategoryIds,
        specializations: _specializations,
        businessName: _businessNameController.text.isNotEmpty ? _businessNameController.text : null,
        businessAddress: _businessAddressController.text.isNotEmpty ? _businessAddressController.text : null,
        businessPhone: _businessPhoneController.text.isNotEmpty ? _businessPhoneController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        certifications: _certifications,
        yearsOfExperience: int.parse(_yearsExperienceController.text),
        serviceAreas: _serviceAreas,
        isAvailable: true,
        isVerified: false,
        averageRating: 0.0,
        totalReviews: 0,
        jobsCompleted: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: 'service_professional',
      );

      // Save to Firestore
      print('🔍 [RegistrationForm] Saving to Firestore...');
      await firestoreService.createServiceProfessionalProfile(professional);
      print('✅ [RegistrationForm] Profile saved to Firestore successfully');

      // Update UserState role to service professional
      print('🔍 [RegistrationForm] Updating UserState role...');
      await userState.changeRole(UserRole.serviceProfessional);
      print('✅ [RegistrationForm] UserState role updated');
      
      // Update UserState service professional profile
      await userState.updateServiceProfessionalProfile(
        categoryIds: _selectedCategoryIds,
        specializations: _specializations,
        businessName: _businessNameController.text.isNotEmpty ? _businessNameController.text : null,
        businessAddress: _businessAddressController.text.isNotEmpty ? _businessAddressController.text : null,
        businessPhone: _businessPhoneController.text.isNotEmpty ? _businessPhoneController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        certifications: _certifications,
        yearsOfExperience: int.parse(_yearsExperienceController.text),
        serviceAreas: _serviceAreas,
      );

      // Call callback
      widget.onRegistrationComplete(professional);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration completed successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Debug: Try to retrieve the profile immediately after creation
        print('🔍 [RegistrationForm] Testing profile retrieval after creation...');
        try {
          final retrievedProfile = await firestoreService.getServiceProfessional(userState.userId!);
          if (retrievedProfile != null) {
            print('✅ [RegistrationForm] Profile successfully retrieved after creation');
            print('🔍 [RegistrationForm] Retrieved profile: ${retrievedProfile.fullName}, Categories: ${retrievedProfile.categoryIds}');
          } else {
            print('❌ [RegistrationForm] Profile NOT found after creation - this is the bug!');
          }
        } catch (e) {
          print('❌ [RegistrationForm] Error retrieving profile after creation: $e');
        }
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to complete registration: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _buildSpecializationsFromControllers() {
    _specializations.clear();
    
    // Add specializations from category-specific controllers
    for (final categoryId in _selectedCategoryIds) {
      if (_specializationControllers.containsKey(categoryId)) {
        final controller = _specializationControllers[categoryId]!;
        if (controller.text.isNotEmpty) {
          final specs = controller.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          _specializations.addAll(specs);
        }
      }
    }
    
    // Remove duplicates
    _specializations = _specializations.toSet().toList();
  }
}


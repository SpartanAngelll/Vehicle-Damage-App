import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/firebase_firestore_service.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/service_category_selector.dart';

class ServiceRequestForm extends StatefulWidget {
  final Function(JobRequest) onRequestSubmitted;

  const ServiceRequestForm({
    super.key,
    required this.onRequestSubmitted,
  });

  @override
  State<ServiceRequestForm> createState() => _ServiceRequestFormState();
}

class _ServiceRequestFormState extends State<ServiceRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController(); // Deprecated: kept for backward compatibility
  final _locationController = TextEditingController();
  final _priorityController = TextEditingController();
  
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  List<String> _selectedCategoryIds = [];
  Map<String, dynamic> _customFields = {}; // Deprecated: kept for backward compatibility
  bool _isSubmitting = false;
  String? _errorMessage;

  // Category-specific field controllers
  final Map<String, TextEditingController> _categoryControllers = {};
  // Per-category budget controllers
  final Map<String, TextEditingController> _categoryBudgetControllers = {};
  
  // Scroll controller to preserve scroll position
  final ScrollController _scrollController = ScrollController();

  // Helper method to preserve scroll position during setState
  void _setStateWithScrollPreservation(VoidCallback fn) {
    final currentScrollOffset = _scrollController.hasClients 
        ? _scrollController.offset 
        : 0.0;
    
    setState(fn);
    
    // Restore scroll position after setState
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          currentScrollOffset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _initializeCategoryControllers();
  }

  void _initializeCategoryControllers() {
    // Initialize controllers for category-specific fields
    _categoryControllers['mechanics'] = TextEditingController(); // Vehicle make
    _categoryControllers['mechanics_model'] = TextEditingController(); // Vehicle model
    _categoryControllers['mechanics_year'] = TextEditingController(); // Vehicle year
    _categoryControllers['hairdressers_barbers'] = TextEditingController(); // Hair type
    _categoryControllers['makeup_artists'] = TextEditingController(); // Event type
    _categoryControllers['nail_technicians'] = TextEditingController(); // Nail style
    _categoryControllers['plumbers'] = TextEditingController(); // Problem type
    _categoryControllers['electricians'] = TextEditingController(); // Issue type
    _categoryControllers['cleaners'] = TextEditingController(); // Service type
    _categoryControllers['landscapers'] = TextEditingController(); // Project type
    _categoryControllers['painters'] = TextEditingController(); // Surface type
    _categoryControllers['appliance_repair'] = TextEditingController(); // Appliance type
    _categoryControllers['hvac_specialists'] = TextEditingController(); // System type
    _categoryControllers['it_support'] = TextEditingController(); // Device type
    _categoryControllers['security_systems'] = TextEditingController(); // System type
    _categoryControllers['glass_windows'] = TextEditingController(); // Material type
    
    // Set default priority
    _priorityController.text = 'Medium';
  }
  
  // Initialize budget controller for a category
  void _initializeCategoryBudgetController(String categoryId) {
    if (!_categoryBudgetControllers.containsKey(categoryId)) {
      _categoryBudgetControllers[categoryId] = TextEditingController();
    }
  }
  
  // Dispose budget controller for a category
  void _disposeCategoryBudgetController(String categoryId) {
    _categoryBudgetControllers[categoryId]?.dispose();
    _categoryBudgetControllers.remove(categoryId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _priorityController.dispose();
    _scrollController.dispose();
    
    // Dispose category controllers
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    
    // Dispose category budget controllers
    for (final controller in _categoryBudgetControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
          // Service Category Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Service Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose one service category for your request',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final categories = await ServiceCategoryService().getAllCategories();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Found ${categories.length} categories'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.bug_report),
                              label: const Text('Test Categories'),
                            ),
                          ],
                        );
                      }
                      
                      return ServiceCategorySelector(
                        availableCategories: availableCategories,
                        selectedCategoryIds: _selectedCategoryIds,
                        allowMultiple: false, // Only allow single category selection
                        onCategoriesChanged: (categoryIds) {
                          _setStateWithScrollPreservation(() {
                            // Dispose controllers for removed categories
                            final removedCategories = _selectedCategoryIds.where(
                              (id) => !categoryIds.contains(id)
                            ).toList();
                            for (final categoryId in removedCategories) {
                              _disposeCategoryBudgetController(categoryId);
                            }
                            
                            // Initialize controllers for new categories
                            for (final categoryId in categoryIds) {
                              _initializeCategoryBudgetController(categoryId);
                            }
                            
                            _selectedCategoryIds = categoryIds;
                            _customFields.clear(); // Clear custom fields when category changes
                          });
                        },
                      );
                    },
                  ),
                  
                  if (_selectedCategoryIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Selected: ${_selectedCategoryIds.first}',
                      style: Theme.of(context).textTheme.bodySmall,
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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Service Request Title',
                      hintText: 'Brief description of what you need',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description',
                      hintText: 'Describe your service needs in detail',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe your service needs';
                      }
                      if (value.length < 20) {
                        return 'Description must be at least 20 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priorityController,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            hintText: 'Urgency level',
                            prefixIcon: Icon(Icons.priority_high),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select priority';
                            }
                            return null;
                          },
                          readOnly: true,
                          onTap: () => _showPriorityDialog(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Service Location',
                      hintText: 'Where the service is needed',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter service location';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Budget Field (single category, so just one budget)
          if (_selectedCategoryIds.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget Range (\$)',
                        hintText: 'Your budget for this service',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your budget';
                        }
                        final budget = double.tryParse(value);
                        if (budget == null || budget <= 0) {
                          return 'Please enter a valid budget';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Category-Specific Fields
          if (_selectedCategoryIds.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category-Specific Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    ..._buildCategorySpecificFields(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Media Upload
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ImageUploadWidget(
                title: 'Service Photos',
                subtitle: 'Upload photos related to your service request',
                maxImages: 10,
                onImagesSelected: (images) {
                  // Only update if the list actually changed to avoid unnecessary rebuilds
                  if (_selectedImages.length != images.length || 
                      !_listEquals(_selectedImages, images)) {
                    _setStateWithScrollPreservation(() {
                      _selectedImages = images;
                    });
                  }
                },
                onImagesUploaded: (imageUrls) {
                  // Only update if the list actually changed to avoid unnecessary rebuilds
                  if (_uploadedImageUrls.length != imageUrls.length || 
                      !_listEquals(_uploadedImageUrls, imageUrls)) {
                    _setStateWithScrollPreservation(() {
                      _uploadedImageUrls = imageUrls;
                    });
                  }
                },
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
              onPressed: _canSubmit() && !_isSubmitting ? _submitRequest : null,
              icon: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
            ),
          ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategorySpecificFields() {
    final fields = <Widget>[];
    
    for (final categoryId in _selectedCategoryIds) {
      switch (categoryId) {
        case 'mechanics':
          fields.addAll([
            Text(
              'Vehicle Information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryControllers['mechanics']!,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Make',
                      hintText: 'e.g., Toyota, Honda',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle make';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _categoryControllers['mechanics_model']!,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Model',
                      hintText: 'e.g., Camry, Civic',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle model';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryControllers['mechanics_year']!,
              decoration: const InputDecoration(
                labelText: 'Vehicle Year',
                hintText: 'e.g., 2020',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle year';
                }
                final year = int.tryParse(value);
                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'hairdressers_barbers':
          fields.addAll([
            Text(
              'Hair Service Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['hairdressers_barbers']!,
              decoration: const InputDecoration(
                labelText: 'Hair Type & Style Preference',
                hintText: 'e.g., Curly hair, bob cut, color treatment',
                prefixIcon: Icon(Icons.content_cut),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe your hair service needs';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'makeup_artists':
          fields.addAll([
            Text(
              'Makeup Service Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['makeup_artists']!,
              decoration: const InputDecoration(
                labelText: 'Event Type & Style',
                hintText: 'e.g., Wedding, photoshoot, party makeup',
                prefixIcon: Icon(Icons.face),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe your makeup service needs';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'nail_technicians':
          fields.addAll([
            Text(
              'Nail Service Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['nail_technicians']!,
              decoration: const InputDecoration(
                labelText: 'Nail Style & Preferences',
                hintText: 'e.g., Acrylics, gel polish, nail art design',
                prefixIcon: Icon(Icons.brush),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe your nail service needs';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'plumbers':
          fields.addAll([
            Text(
              'Plumbing Issue Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['plumbers']!,
              decoration: const InputDecoration(
                labelText: 'Problem Type',
                hintText: 'e.g., Leaky faucet, clogged drain, pipe repair',
                prefixIcon: Icon(Icons.plumbing),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the plumbing issue';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'electricians':
          fields.addAll([
            Text(
              'Electrical Issue Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['electricians']!,
              decoration: const InputDecoration(
                labelText: 'Issue Type',
                hintText: 'e.g., Outlet not working, circuit breaker trips',
                prefixIcon: Icon(Icons.electrical_services),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the electrical issue';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'appliance_repair':
          fields.addAll([
            Text(
              'Appliance Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['appliance_repair']!,
              decoration: const InputDecoration(
                labelText: 'Appliance Type & Issue',
                hintText: 'e.g., Refrigerator not cooling, washing machine leaks',
                prefixIcon: Icon(Icons.kitchen),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the appliance and issue';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'hvac_specialists':
          fields.addAll([
            Text(
              'HVAC System Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['hvac_specialists']!,
              decoration: const InputDecoration(
                labelText: 'System Type & Issue',
                hintText: 'e.g., AC not cooling, furnace not heating',
                prefixIcon: Icon(Icons.ac_unit),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the HVAC system and issue';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'it_support':
          fields.addAll([
            Text(
              'IT Support Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['it_support']!,
              decoration: const InputDecoration(
                labelText: 'Device Type & Issue',
                hintText: 'e.g., Laptop won\'t start, network connectivity issues',
                prefixIcon: Icon(Icons.computer),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the device and issue';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'security_systems':
          fields.addAll([
            Text(
              'Security System Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['security_systems']!,
              decoration: const InputDecoration(
                labelText: 'System Type & Requirements',
                hintText: 'e.g., CCTV installation, alarm system setup',
                prefixIcon: Icon(Icons.security),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the security system needs';
                }
                return null;
              },
            ),
          ]);
          break;
          
        case 'glass_windows':
          fields.addAll([
            Text(
              'Glass & Window Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryControllers['glass_windows']!,
              decoration: const InputDecoration(
                labelText: 'Material & Service Type',
                hintText: 'e.g., Window replacement, glass repair, door installation',
                prefixIcon: Icon(Icons.window),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the glass/window service needs';
                }
                return null;
              },
            ),
          ]);
          break;
          
        default:
          // Generic field for other categories
          fields.addAll([
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Specific Requirements',
                hintText: 'Any specific details about your service needs',
                prefixIcon: Icon(Icons.info),
              ),
              maxLines: 2,
            ),
          ]);
      }
      
      if (categoryId != _selectedCategoryIds.last) {
        fields.add(const SizedBox(height: 24));
        fields.add(const Divider());
        fields.add(const SizedBox(height: 24));
      }
    }
    
    return fields;
  }

  void _showPriorityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Low'),
              subtitle: const Text('Can wait a few days'),
              onTap: () {
                _priorityController.text = 'Low';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Medium'),
              subtitle: const Text('Needed within 1-2 days'),
              onTap: () {
                _priorityController.text = 'Medium';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('High'),
              subtitle: const Text('Needed today or tomorrow'),
              onTap: () {
                _priorityController.text = 'High';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Urgent'),
              subtitle: const Text('Emergency - needed immediately'),
              onTap: () {
                _priorityController.text = 'Urgent';
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _selectedCategoryIds.isNotEmpty && 
           _uploadedImageUrls.isNotEmpty &&
           _titleController.text.isNotEmpty &&
           _descriptionController.text.isNotEmpty;
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryIds.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a service category';
      });
      return;
    }

    if (_uploadedImageUrls.isEmpty) {
      setState(() {
        _errorMessage = 'Please upload at least one image';
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
      
      if (!userState.isAuthenticated || userState.userId == null) {
        throw Exception('User not authenticated');
      }

      // Build custom fields based on selected categories
      _buildCustomFields();

      // Build budget (single category, so just one budget)
      final categoryBudgets = <String, double>{};
      if (_selectedCategoryIds.isNotEmpty && _budgetController.text.isNotEmpty) {
        final budget = double.tryParse(_budgetController.text);
        if (budget != null && budget > 0) {
          categoryBudgets[_selectedCategoryIds.first] = budget;
        }
      }

      // Create job request in Firestore
      final now = DateTime.now();
      final requestId = await firestoreService.createJobRequest({
        'customerId': userState.userId!,
        'customerEmail': userState.email ?? '',
        'categoryIds': _selectedCategoryIds,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'estimatedBudget': double.tryParse(_budgetController.text),
        'categoryBudgets': categoryBudgets.isEmpty ? null : categoryBudgets,
        'categoryCustomFields': _categoryCustomFields?.isEmpty ?? true ? null : _categoryCustomFields,
        'location': _locationController.text,
        'priority': _getJobPriority(_priorityController.text).name,
        'customFields': _customFields,
        'imageUrls': _uploadedImageUrls,
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
        'tags': <String>[],
      });

      // Create JobRequest object
      final jobRequest = JobRequest(
        id: requestId,
        customerId: userState.userId!,
        customerEmail: userState.email ?? '',
        categoryIds: _selectedCategoryIds,
        title: _titleController.text,
        description: _descriptionController.text,
        estimatedBudget: double.tryParse(_budgetController.text),
        categoryBudgets: categoryBudgets.isEmpty ? null : categoryBudgets,
        categoryCustomFields: _categoryCustomFields?.isEmpty ?? true ? null : _categoryCustomFields,
        location: _locationController.text,
        priority: _getJobPriority(_priorityController.text),
        customFields: _customFields,
        imageUrls: _uploadedImageUrls,
        status: JobStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Call callback
      widget.onRequestSubmitted(jobRequest);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Service request submitted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Reset form
      _resetForm();

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit request: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _buildCustomFields() {
    _customFields.clear();
    
    // Build per-category custom fields
    final categoryCustomFields = <String, Map<String, dynamic>>{};
    
    for (final categoryId in _selectedCategoryIds) {
      final categoryFields = <String, dynamic>{};
      
      switch (categoryId) {
        case 'mechanics':
          categoryFields['vehicleMake'] = _categoryControllers['mechanics']?.text;
          categoryFields['vehicleModel'] = _categoryControllers['mechanics_model']?.text;
          categoryFields['vehicleYear'] = _categoryControllers['mechanics_year']?.text;
          // Also add to legacy _customFields for backward compatibility
          _customFields['vehicleMake'] = _categoryControllers['mechanics']?.text;
          _customFields['vehicleModel'] = _categoryControllers['mechanics_model']?.text;
          _customFields['vehicleYear'] = _categoryControllers['mechanics_year']?.text;
          break;
        case 'hairdressers_barbers':
          categoryFields['hairType'] = _categoryControllers['hairdressers_barbers']?.text;
          _customFields['hairType'] = _categoryControllers['hairdressers_barbers']?.text;
          break;
        case 'makeup_artists':
          categoryFields['eventType'] = _categoryControllers['makeup_artists']?.text;
          _customFields['eventType'] = _categoryControllers['makeup_artists']?.text;
          break;
        case 'nail_technicians':
          categoryFields['nailStyle'] = _categoryControllers['nail_technicians']?.text;
          _customFields['nailStyle'] = _categoryControllers['nail_technicians']?.text;
          break;
        case 'plumbers':
          categoryFields['problemType'] = _categoryControllers['plumbers']?.text;
          _customFields['problemType'] = _categoryControllers['plumbers']?.text;
          break;
        case 'electricians':
          categoryFields['issueType'] = _categoryControllers['electricians']?.text;
          _customFields['issueType'] = _categoryControllers['electricians']?.text;
          break;
        case 'appliance_repair':
          categoryFields['applianceType'] = _categoryControllers['appliance_repair']?.text;
          _customFields['applianceType'] = _categoryControllers['appliance_repair']?.text;
          break;
        case 'hvac_specialists':
          categoryFields['systemType'] = _categoryControllers['hvac_specialists']?.text;
          _customFields['systemType'] = _categoryControllers['hvac_specialists']?.text;
          break;
        case 'it_support':
          categoryFields['deviceType'] = _categoryControllers['it_support']?.text;
          _customFields['deviceType'] = _categoryControllers['it_support']?.text;
          break;
        case 'security_systems':
          categoryFields['securitySystemType'] = _categoryControllers['security_systems']?.text;
          _customFields['securitySystemType'] = _categoryControllers['security_systems']?.text;
          break;
        case 'glass_windows':
          categoryFields['materialType'] = _categoryControllers['glass_windows']?.text;
          _customFields['materialType'] = _categoryControllers['glass_windows']?.text;
          break;
      }
      
      if (categoryFields.isNotEmpty) {
        categoryCustomFields[categoryId] = categoryFields;
      }
    }
    
    // Store for use in submit
    _categoryCustomFields = categoryCustomFields;
  }
  
  // Store per-category custom fields
  Map<String, Map<String, dynamic>>? _categoryCustomFields;

  JobPriority _getJobPriority(String priorityText) {
    switch (priorityText.toLowerCase()) {
      case 'low':
        return JobPriority.low;
      case 'medium':
        return JobPriority.medium;
      case 'high':
        return JobPriority.high;
      case 'urgent':
        return JobPriority.urgent;
      default:
        return JobPriority.medium;
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _budgetController.clear();
    _locationController.clear();
    _priorityController.text = 'Medium'; // Reset to default priority
    
    // Clear category controllers
    for (final controller in _categoryControllers.values) {
      controller.clear();
    }
    
    // Clear category budget controllers
    for (final controller in _categoryBudgetControllers.values) {
      controller.clear();
    }
    
    setState(() {
      _selectedImages.clear();
      _uploadedImageUrls.clear();
      _selectedCategoryIds.clear();
      _customFields.clear();
      _categoryCustomFields = null;
    });
  }
}


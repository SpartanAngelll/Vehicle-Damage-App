import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/firebase_firestore_service.dart';
import '../widgets/image_upload_widget.dart';

class DamageReportForm extends StatefulWidget {
  final Function(DamageReport) onReportSubmitted;

  const DamageReportForm({
    super.key,
    required this.onReportSubmitted,
  });

  @override
  State<DamageReportForm> createState() => _DamageReportFormState();
}

class _DamageReportFormState extends State<DamageReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set current year as default
    _yearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _notesController.dispose();
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
            'Submit Damage Report',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Vehicle information section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _makeController,
                          decoration: const InputDecoration(
                            labelText: 'Make',
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
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
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
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year',
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
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Damage description section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Damage Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Damage Description',
                      hintText: 'Describe the damage in detail',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe the damage';
                      }
                      if (value.length < 20) {
                        return 'Description must be at least 20 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Cost (\$)',
                      hintText: 'Your estimate of repair cost',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter estimated cost';
                      }
                      final cost = double.tryParse(value);
                      if (cost == null || cost <= 0) {
                        return 'Please enter a valid cost amount';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      hintText: 'Any additional information (optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Image upload section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ImageUploadWidget(
                title: 'Damage Photos',
                subtitle: 'Upload clear photos of the damage (required)',
                maxImages: 10,
                onImagesSelected: (images) {
                  setState(() {
                    _selectedImages = images;
                  });
                },
                onImagesUploaded: (imageUrls) {
                  setState(() {
                    _uploadedImageUrls = imageUrls;
                  });
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
              onPressed: _canSubmit() && !_isSubmitting ? _submitReport : null,
              icon: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _selectedImages.isNotEmpty && _uploadedImageUrls.isNotEmpty;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
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

      // Create damage report in Firestore
      final reportId = await firestoreService.createDamageReport(
        ownerId: userState.userId!,
        vehicleMake: _makeController.text,
        vehicleModel: _modelController.text,
        vehicleYear: int.parse(_yearController.text),
        damageDescription: _descriptionController.text,
        imageUrls: _uploadedImageUrls,
        estimatedCost: double.parse(_costController.text),
        additionalNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Create DamageReport object
      final damageReport = DamageReport(
        ownerId: userState.userId!,
        vehicleMake: _makeController.text,
        vehicleModel: _modelController.text,
        vehicleYear: int.parse(_yearController.text),
        damageDescription: _descriptionController.text,
        imageUrls: _uploadedImageUrls,
        estimatedCost: double.parse(_costController.text),
        additionalNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Call callback
      widget.onReportSubmitted(damageReport);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Damage report submitted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Reset form
      _resetForm();

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit report: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _makeController.clear();
    _modelController.clear();
    _yearController.text = DateTime.now().year.toString();
    _descriptionController.clear();
    _costController.clear();
    _notesController.clear();
    setState(() {
      _selectedImages.clear();
      _uploadedImageUrls.clear();
    });
  }
}


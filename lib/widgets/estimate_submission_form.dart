import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/image_upload_widget.dart';

class EstimateSubmissionForm extends StatefulWidget {
  final String reportId;
  final String ownerId;
  final Function(Estimate) onEstimateSubmitted;

  const EstimateSubmissionForm({
    super.key,
    required this.reportId,
    required this.ownerId,
    required this.onEstimateSubmitted,
  });

  @override
  State<EstimateSubmissionForm> createState() => _EstimateSubmissionFormState();
}

class _EstimateSubmissionFormState extends State<EstimateSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _leadTimeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _costController.dispose();
    _leadTimeController.dispose();
    _descriptionController.dispose();
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
            'Submit Estimate',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Cost input
          TextFormField(
            controller: _costController,
            decoration: const InputDecoration(
              labelText: 'Estimated Cost (\$)',
              hintText: 'Enter the estimated repair cost',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the estimated cost';
              }
              final cost = double.tryParse(value);
              if (cost == null || cost <= 0) {
                return 'Please enter a valid cost amount';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Lead time input
          TextFormField(
            controller: _leadTimeController,
            decoration: const InputDecoration(
              labelText: 'Lead Time (Days)',
              hintText: 'How many days will the repair take?',
              prefixIcon: Icon(Icons.schedule),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the lead time';
              }
              final days = int.tryParse(value);
              if (days == null || days <= 0) {
                return 'Please enter a valid number of days';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Description input
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Repair Description',
              hintText: 'Describe the repair work in detail',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a repair description';
              }
              if (value.length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Image upload section
          ImageUploadWidget(
            title: 'Add Supporting Images',
            subtitle: 'Upload photos that support your estimate (optional)',
            maxImages: 5,
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
              onPressed: _isSubmitting ? null : _submitEstimate,
              icon: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Estimate'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEstimate() async {
    if (!_formKey.currentState!.validate()) {
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

      // Create estimate in Firestore
      final estimateId = await firestoreService.createEstimate(
        reportId: widget.reportId,
        ownerId: widget.ownerId,
        professionalId: userState.userId!,
        professionalEmail: userState.email ?? '',
        professionalBio: userState.bio,
        cost: double.parse(_costController.text),
        leadTimeDays: int.parse(_leadTimeController.text),
        description: _descriptionController.text,
        imageUrls: _uploadedImageUrls,
      );

      // Create Estimate object
      final estimate = Estimate(
        reportId: widget.reportId,
        ownerId: widget.ownerId,
        repairProfessionalId: userState.userId!,
        repairProfessionalEmail: userState.email ?? '',
        repairProfessionalBio: userState.bio,
        cost: double.parse(_costController.text),
        leadTimeDays: int.parse(_leadTimeController.text),
        description: _descriptionController.text,
        imageUrls: _uploadedImageUrls,
      );

      // Add to user state
      userState.addSubmittedEstimate(estimate);

      // Call callback
      widget.onEstimateSubmitted(estimate);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Estimate submitted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Reset form
      _resetForm();

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit estimate: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _costController.clear();
    _leadTimeController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedImages.clear();
      _uploadedImageUrls.clear();
    });
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/damage_report.dart';
import '../models/booking_models.dart';
import '../services/firebase_firestore_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';

class EstimateSubmissionForm extends StatefulWidget {
  final DamageReport damageReport;
  final String professionalId;
  final String professionalEmail;
  final String? professionalBio;
  final VoidCallback? onEstimateSubmitted;

  const EstimateSubmissionForm({
    super.key,
    required this.damageReport,
    required this.professionalId,
    required this.professionalEmail,
    this.professionalBio,
    this.onEstimateSubmitted,
  });

  @override
  State<EstimateSubmissionForm> createState() => _EstimateSubmissionFormState();
}

class _EstimateSubmissionFormState extends State<EstimateSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _leadTimeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _costController.dispose();
    _leadTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitEstimate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final cost = double.parse(_costController.text);
      final leadTimeDays = int.parse(_leadTimeController.text);
      final description = _descriptionController.text.trim();

      if (cost <= 0) {
        throw Exception('Cost must be greater than 0');
      }

      if (leadTimeDays <= 0) {
        throw Exception('Lead time must be greater than 0 days');
      }

      final firestoreService = FirebaseFirestoreService();
      
      await firestoreService.createEstimate(
        reportId: widget.damageReport.id,
        ownerId: widget.damageReport.ownerId,
        professionalId: widget.professionalId,
        professionalEmail: widget.professionalEmail,
        professionalBio: widget.professionalBio,
        cost: cost,
        leadTimeDays: leadTimeDays,
        description: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estimate submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onEstimateSubmitted?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Estimate'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _buildForm(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Estimate'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Estimate'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Information Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.damageReport.vehicleYear} ${widget.damageReport.vehicleMake} ${widget.damageReport.vehicleModel}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Damage: ${widget.damageReport.damageDescription}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveUtils.getResponsivePadding(context)),

            // Cost Input
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Estimated Cost (\$)',
                hintText: 'Enter estimated cost',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter estimated cost';
                }
                final cost = double.tryParse(value);
                if (cost == null || cost <= 0) {
                  return 'Please enter a valid cost greater than 0';
                }
                return null;
              },
            ),

            SizedBox(height: ResponsiveUtils.getResponsivePadding(context)),

            // Lead Time Input
            TextFormField(
              controller: _leadTimeController,
              decoration: const InputDecoration(
                labelText: 'Lead Time (Days)',
                hintText: 'Enter estimated lead time in days',
                suffixText: 'days',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter lead time';
                }
                final days = int.tryParse(value);
                if (days == null || days <= 0) {
                  return 'Please enter a valid number of days';
                }
                return null;
              },
            ),

            SizedBox(height: ResponsiveUtils.getResponsivePadding(context)),

            // Description Input
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your repair approach and any additional details',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),

            SizedBox(height: ResponsiveUtils.getResponsivePadding(context)),

            // Error Message
            if (_errorMessage != null)
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

            if (_errorMessage != null)
              SizedBox(height: ResponsiveUtils.getResponsivePadding(context)),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEstimate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : const Text('Submit Estimate'),
              ),
            ),

            SizedBox(height: ResponsiveUtils.getResponsivePadding(context)),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

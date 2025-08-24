import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../utils/responsive_utils.dart';
import 'responsive_layout.dart';

class DamageReportCard extends StatefulWidget {
  final DamageReport report;
  final int index;
  final bool showEstimateInput;

  const DamageReportCard({
    super.key,
    required this.report,
    required this.index,
    this.showEstimateInput = false,
  });

  @override
  State<DamageReportCard> createState() => _DamageReportCardState();
}

class _DamageReportCardState extends State<DamageReportCard> {
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _leadTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _costController.dispose();
    _leadTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return Semantics(
          label: 'Damage report card ${widget.index + 1}',
          child: Card(
            margin: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16),
            ),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(context, isMobile, isTablet, isDesktop),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                  if (widget.showEstimateInput) ...[
                    _buildEstimateInput(context, isMobile, isTablet, isDesktop),
                    SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                    _buildSubmitButton(context, isMobile, isTablet, isDesktop),
                    SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                  ],
                  _buildEstimatesList(context, isMobile, isTablet, isDesktop),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Damage Report #${widget.index + 1}",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            widget.report.image,
            width: double.infinity,
            height: ResponsiveUtils.isMobile(context) ? 200 : 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: ResponsiveUtils.isMobile(context) ? 200 : 250,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.error_outline,
                  size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 48, tablet: 56, desktop: 64),
                  color: Theme.of(context).colorScheme.error,
                ),
              );
            },
          ),
        ),
        if (widget.report.description.isNotEmpty) ...[
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
          Text(
            "Description: ${widget.report.description}",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
            ),
          ),
        ],
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
        Text(
          "Submitted: ${_formatDate(widget.report.timestamp)}",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateInput(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Submit Repair Estimate",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        
        // Cost input
        TextField(
          controller: _costController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Estimated Cost (\$)",
            hintText: "Enter estimated repair cost",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
              vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        
        // Lead time input
        TextField(
          controller: _leadTimeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Lead Time (days)",
            hintText: "Enter estimated completion time",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.schedule),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
              vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        
        // Description input
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: "Repair Description",
            hintText: "Describe the repair work needed, parts required, etc.",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
              vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Submit repair estimate',
        button: true,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitEstimate,
          icon: _isSubmitting
            ? SizedBox(
                width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                ),
              )
            : Icon(Icons.send),
          label: Text(
            _isSubmitting ? "Submitting..." : "Submit Estimate",
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstimatesList(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    if (widget.report.estimates.isEmpty) {
      return Semantics(
        label: 'No repair estimates submitted yet',
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "No estimates submitted yet",
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Repair Estimates",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
        ...widget.report.estimates.asMap().entries.map((entry) {
          final index = entry.key;
          final estimate = entry.value;
          return _buildEstimateCard(context, index, estimate, isMobile, isTablet, isDesktop);
        }),
      ],
    );
  }

  Widget _buildEstimateCard(BuildContext context, int index, Estimate estimate, bool isMobile, bool isTablet, bool isDesktop) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estimate header with professional info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.build,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Auto Repair Professional",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        estimate.repairProfessionalEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        "Estimate #${index + 1}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 6, tablet: 8, desktop: 10),
                    vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 2, tablet: 4, desktop: 6),
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(estimate.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(estimate.status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            
            // Professional bio (if available)
            if (estimate.repairProfessionalBio != null && estimate.repairProfessionalBio!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: ResponsiveUtils.getResponsiveIconSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 6, tablet: 8, desktop: 10)),
                        Text(
                          "About This Professional",
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 6, tablet: 8, desktop: 10)),
                    Text(
                      estimate.repairProfessionalBio!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 15,
                          desktop: 17,
                        ),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            ],
            
            // Estimate details
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cost and Lead Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Estimated Cost:",
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              "\$${estimate.cost.toStringAsFixed(2)}",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lead Time:",
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              "${estimate.leadTimeDays} days",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                  
                  // Description
                  Text(
                    "Repair Description:",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                  Text(
                    estimate.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
            
            // Action buttons - Only show for vehicle owners and only for pending estimates
            Consumer<UserState>(
              builder: (context, userState, child) {
                // Only show action buttons for vehicle owners and pending estimates
                if (!userState.isOwner || estimate.status != EstimateStatus.pending) {
                  return SizedBox.shrink();
                }
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Could implement contact professional functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contact functionality coming soon!'),
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(Icons.message),
                      label: Text("Contact"),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Vehicle owner accepts the estimate
                        _acceptEstimate(context, index);
                      },
                      icon: Icon(Icons.check),
                      label: Text("Accept"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Vehicle owner declines the estimate
                        _declineEstimate(context, index);
                      },
                      icon: Icon(Icons.close),
                      label: Text("Decline"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(EstimateStatus status) {
    switch (status) {
      case EstimateStatus.pending:
        return Colors.orange;
      case EstimateStatus.accepted:
        return Colors.green;
      case EstimateStatus.declined:
        return Colors.red;
    }
  }

  String _getStatusText(EstimateStatus status) {
    switch (status) {
      case EstimateStatus.pending:
        return "Pending";
      case EstimateStatus.accepted:
        return "Accepted";
      case EstimateStatus.declined:
        return "Declined";
    }
  }

  void _acceptEstimate(BuildContext context, int estimateIndex) {
    final appState = context.read<AppState>();
    final selectedReport = appState.selectedReport;
    
    if (selectedReport != null) {
      appState.updateEstimateStatus(
        appState.selectedReportIndex!,
        estimateIndex,
        EstimateStatus.accepted,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estimate accepted! We\'ll notify the repair professional.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _declineEstimate(BuildContext context, int estimateIndex) {
    final appState = context.read<AppState>();
    final selectedReport = appState.selectedReport;
    
    if (selectedReport != null) {
      appState.updateEstimateStatus(
        appState.selectedReportIndex!,
        estimateIndex,
        EstimateStatus.declined,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estimate declined.'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitEstimate() async {
    // Validate inputs
    final costText = _costController.text.trim();
    final leadTimeText = _leadTimeController.text.trim();
    final description = _descriptionController.text.trim();

    if (costText.isEmpty || leadTimeText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cost = double.tryParse(costText);
    final leadTime = int.tryParse(leadTimeText);

    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid cost amount'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (leadTime == null || leadTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid lead time'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final appState = context.read<AppState>();
      final userState = context.read<UserState>();
      
      // Get current user information for the estimate
      if (userState.isRepairman && userState.userId != null && userState.email != null) {
        final estimate = Estimate(
          repairProfessionalId: userState.userId!,
          repairProfessionalEmail: userState.email!,
          repairProfessionalBio: userState.bio,
          cost: cost,
          leadTimeDays: leadTime,
          description: description,
        );
        
        // Add estimate to the damage report
        await appState.addEstimate(widget.index, estimate);
        
        // Track the submitted estimate in UserState
        userState.addSubmittedEstimate(estimate);
        
        // Clear form
        _costController.clear();
        _leadTimeController.clear();
        _descriptionController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Estimate submitted successfully! This job has been moved to "My Estimates".'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('User information not available');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit estimate: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

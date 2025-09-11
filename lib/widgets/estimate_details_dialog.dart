import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/damage_report.dart';
import '../utils/responsive_utils.dart';
import 'expandable_photo_viewer.dart';

class EstimateDetailsDialog extends StatelessWidget {
  final Estimate estimate;

  const EstimateDetailsDialog({
    super.key,
    required this.estimate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: ResponsiveUtils.isMobile(context) 
              ? MediaQuery.of(context).size.width * 0.95
              : 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assessment,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accepted Estimate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Estimate #${estimate.id}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    _buildSection(
                      context,
                      'Service Description',
                      estimate.description,
                      Icons.description,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Photos
                    if (estimate.imageUrls.isNotEmpty) ...[
                      _buildSection(
                        context,
                        'Reference Photos',
                        null,
                        Icons.photo_library,
                        child: SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: estimate.imageUrls.length,
                            itemBuilder: (context, index) {
                              return PhotoThumbnail(
                                imageUrl: estimate.imageUrls[index],
                                allImageUrls: estimate.imageUrls,
                                index: index,
                                width: 120,
                                height: 120,
                                title: 'Estimate Photos',
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Cost and Timeline
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Estimated Cost',
                            '\$${estimate.cost.toStringAsFixed(2)}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Lead Time',
                            '${estimate.leadTimeDays} days',
                            Icons.schedule,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Status and Dates
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Status',
                            _getStatusText(estimate.status),
                            Icons.info,
                            _getStatusColor(estimate.status),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Submitted',
                            _formatDate(estimate.submittedAt),
                            Icons.calendar_today,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    
                    if (estimate.acceptedAt != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        context,
                        'Accepted On',
                        _formatDate(estimate.acceptedAt!),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                    
                    // Professional Info
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      'Professional Information',
                      null,
                      Icons.person,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            context,
                            'Email',
                            estimate.repairProfessionalEmail,
                            Icons.email,
                          ),
                          if (estimate.repairProfessionalBio != null)
                            _buildInfoRow(
                              context,
                              'Bio',
                              estimate.repairProfessionalBio!,
                              Icons.info_outline,
                            ),
                        ],
                      ),
                    ),
                    
                    // Attachments
                    if (estimate.attachments != null && estimate.attachments!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        'Attachments',
                        null,
                        Icons.attach_file,
                        child: Column(
                          children: estimate.attachments!.map((attachment) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.file_present, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      attachment,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ],
                    
                    // Completion Notes
                    if (estimate.completionNotes != null && estimate.completionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        'Completion Notes',
                        estimate.completionNotes!,
                        Icons.note,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String? content,
    IconData icon, {
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (content != null)
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (child != null) child,
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(EstimateStatus status) {
    switch (status) {
      case EstimateStatus.pending:
        return 'Pending';
      case EstimateStatus.accepted:
        return 'Accepted';
      case EstimateStatus.declined:
        return 'Declined';
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

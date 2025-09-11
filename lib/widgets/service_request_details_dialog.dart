import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/job_request.dart';
import '../utils/responsive_utils.dart';
import 'expandable_photo_viewer.dart';

class ServiceRequestDetailsDialog extends StatelessWidget {
  final JobRequest request;

  const ServiceRequestDetailsDialog({
    super.key,
    required this.request,
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
                    Icons.assignment,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Request Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.title,
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
                      'Description',
                      request.description,
                      Icons.description,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Photos
                    if (request.imageUrls.isNotEmpty) ...[
                      _buildSection(
                        context,
                        'Photos (${request.imageUrls.length})',
                        'Tap any image to view in full screen',
                        Icons.photo_library,
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8),
                            itemCount: request.imageUrls.length,
                            itemBuilder: (context, index) {
                              print('🔍 [ServiceRequestDialog] Building photo thumbnail $index: ${request.imageUrls[index]}');
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: PhotoThumbnail(
                                  imageUrl: request.imageUrls[index],
                                  allImageUrls: request.imageUrls,
                                  index: index,
                                  width: 120,
                                  height: 120,
                                  title: '${request.title} - Photos',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Show debug info when no images
                      _buildSection(
                        context,
                        'Photos',
                        'No images available for this service request',
                        Icons.photo_library,
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Details Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Priority',
                            _getPriorityText(request.priority),
                            Icons.flag,
                            _getPriorityColor(request.priority),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Budget',
                            request.estimatedBudget != null 
                                ? '\$${request.estimatedBudget!.toStringAsFixed(0)}'
                                : 'Not specified',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Location',
                            request.location ?? 'Not specified',
                            Icons.location_on,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Created',
                            _formatDate(request.createdAt),
                            Icons.schedule,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    
                    // Custom Fields
                    if (request.customFields != null && request.customFields!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        'Additional Details',
                        null,
                        Icons.info_outline,
                        child: Column(
                          children: request.customFields!.entries.map((entry) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${_formatFieldName(entry.key)}:',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.value?.toString() ?? '',
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

  String _getPriorityText(JobPriority priority) {
    switch (priority) {
      case JobPriority.low:
        return 'Low';
      case JobPriority.medium:
        return 'Medium';
      case JobPriority.high:
        return 'High';
      case JobPriority.urgent:
        return 'Urgent';
    }
  }

  Color _getPriorityColor(JobPriority priority) {
    switch (priority) {
      case JobPriority.low:
        return Colors.green;
      case JobPriority.medium:
        return Colors.orange;
      case JobPriority.high:
        return Colors.red;
      case JobPriority.urgent:
        return Colors.purple;
    }
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .split(RegExp(r'(?=[A-Z])'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

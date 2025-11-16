import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/job_request.dart';
import '../models/user_state.dart';
import '../utils/responsive_utils.dart';
import 'expandable_photo_viewer.dart';
import '../services/firebase_firestore_service.dart';
import '../services/review_service.dart';
import 'profile_avatar.dart';

class ServiceRequestCard extends StatefulWidget {
  final JobRequest request;
  final int index;
  final bool showEstimateInput;
  final VoidCallback? onEstimateSubmitted;
  final VoidCallback? onDismiss;

  const ServiceRequestCard({
    super.key,
    required this.request,
    required this.index,
    this.showEstimateInput = false,
    this.onEstimateSubmitted,
    this.onDismiss,
  });

  @override
  State<ServiceRequestCard> createState() => _ServiceRequestCardState();
}

class _ServiceRequestCardState extends State<ServiceRequestCard> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final ReviewService _reviewService = ReviewService();
  
  String? _customerProfilePhotoUrl;
  String? _customerName;
  double _customerAverageRating = 0.0;
  int _customerTotalReviews = 0;
  bool _isLoadingCustomerData = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      setState(() => _isLoadingCustomerData = true);
      
      // Load customer profile
      final customerProfile = await _firestoreService.getUserProfile(widget.request.customerId);
      if (customerProfile != null) {
        _customerProfilePhotoUrl = customerProfile['profilePhotoUrl'];
        _customerName = customerProfile['fullName'] ?? 
                       customerProfile['username'] ?? 
                       customerProfile['email']?.split('@')[0] ?? 
                       'Customer';
      }
      
      // Load customer rating stats
      final ratingStats = await _reviewService.getCustomerRatingStats(widget.request.customerId);
      _customerAverageRating = ratingStats.averageRating;
      _customerTotalReviews = ratingStats.totalReviews;
      
      if (mounted) {
        setState(() => _isLoadingCustomerData = false);
      }
    } catch (e) {
      print('❌ [ServiceRequestCard] Error loading customer data: $e');
      if (mounted) {
        setState(() => _isLoadingCustomerData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, _) {
        // Get professional's registered categories
        final professionalCategories = userState.isServiceProfessional 
            ? userState.serviceCategoryIds 
            : <String>[];
        
        // Filter categories to only show those the professional is registered for
        final relevantCategories = professionalCategories.isEmpty
            ? widget.request.categoryIds
            : widget.request.categoryIds.where(
                (categoryId) => professionalCategories.contains(categoryId)
              ).toList();
        
        // If no relevant categories, show all (for non-professionals or if filtering fails)
        final displayCategories = relevantCategories.isEmpty 
            ? widget.request.categoryIds 
            : relevantCategories;
        
        // Get budget for relevant categories
        double? displayBudget;
        if (widget.request.categoryBudgets != null && displayCategories.isNotEmpty) {
          // If multiple relevant categories, show the first one's budget
          // In practice, professionals should only see requests for their categories
          final firstCategory = displayCategories.first;
          displayBudget = widget.request.getBudgetForCategory(firstCategory);
        } else {
          displayBudget = widget.request.estimatedBudget;
        }
        
        // Get custom fields for relevant categories
        Map<String, dynamic>? displayCustomFields;
        if (widget.request.categoryCustomFields != null && displayCategories.isNotEmpty) {
          // Merge custom fields from all relevant categories
          displayCustomFields = {};
          for (final categoryId in displayCategories) {
            final categoryFields = widget.request.getCustomFieldsForCategory(categoryId);
            if (categoryFields != null) {
              displayCustomFields!.addAll(categoryFields);
            }
          }
          if (displayCustomFields!.isEmpty) {
            displayCustomFields = null;
          }
        } else {
          displayCustomFields = widget.request.customFields;
        }
        
        return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and priority
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            decoration: BoxDecoration(
              color: _getPriorityColor(widget.request.priority).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info row with profile picture and rating
                Row(
                  children: [
                    // Customer profile picture
                    if (_isLoadingCustomerData)
                      SizedBox(
                        width: ResponsiveUtils.getResponsiveFontSize(context, mobile: 40, tablet: 48, desktop: 56),
                        height: ResponsiveUtils.getResponsiveFontSize(context, mobile: 40, tablet: 48, desktop: 56),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      ProfileAvatar(
                        profilePhotoUrl: _customerProfilePhotoUrl,
                        radius: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20, tablet: 24, desktop: 28),
                      ),
                    const SizedBox(width: 12),
                    // Customer name and rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoadingCustomerData ? 'Loading...' : (_customerName ?? 'Customer'),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!_isLoadingCustomerData && _customerTotalReviews > 0)
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _customerAverageRating.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      mobile: 12,
                                      tablet: 14,
                                      desktop: 16,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($_customerTotalReviews ${_customerTotalReviews == 1 ? 'review' : 'reviews'})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      mobile: 10,
                                      tablet: 12,
                                      desktop: 14,
                                    ),
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          else if (!_isLoadingCustomerData)
                            Text(
                              'No reviews yet',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 10,
                                  tablet: 12,
                                  desktop: 14,
                                ),
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Priority badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12),
                        vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 4, tablet: 6, desktop: 8),
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(widget.request.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPriorityText(widget.request.priority),
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
                const SizedBox(height: 12),
                // Request title and number
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.request.title,
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
                          const SizedBox(height: 4),
                          Text(
                            'Request #${widget.index + 1}',
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
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service categories (filtered to show only relevant ones)
                if (displayCategories.isNotEmpty) ...[
                  Text(
                    'Service Categories:',
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displayCategories.map((categoryId) => Chip(
                      label: Text(
                        _getCategoryDisplayName(categoryId),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 10,
                            tablet: 12,
                            desktop: 14,
                          ),
                        ),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Description
                Text(
                  'Description:',
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
                const SizedBox(height: 8),
                Text(
                  widget.request.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Images
                if (widget.request.imageUrls.isNotEmpty) ...[
                  Text(
                    'Photos:',
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
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.request.imageUrls.length,
                      itemBuilder: (context, imageIndex) {
                        return PhotoThumbnail(
                          imageUrl: widget.request.imageUrls[imageIndex],
                          allImageUrls: widget.request.imageUrls,
                          index: imageIndex,
                          width: 100,
                          height: 100,
                          title: '${widget.request.title} - Photos',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Details row
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        'Budget',
                                                 displayBudget != null 
                             ? '\$${displayBudget.toStringAsFixed(0)}'
                             : 'Not specified',
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                                             child: _buildDetailItem(
                         context,
                         'Location',
                         widget.request.location ?? 'Not specified',
                         Icons.location_on,
                       ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                                 // Custom fields (filtered to show only relevant ones)
                 if (displayCustomFields != null && displayCustomFields!.isNotEmpty) ...[
                  Text(
                    'Additional Details:',
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
                  const SizedBox(height: 8),
                                     ...displayCustomFields!.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatFieldName(entry.key)}: ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 16),
                ],
                
                // Footer with timestamp and action buttons
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Posted ${_formatDate(widget.request.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    if (widget.showEstimateInput) ...[
                      // Dismiss button
                      TextButton.icon(
                        onPressed: widget.onDismiss,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Dismiss'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Submit estimate button
                      ElevatedButton.icon(
                        onPressed: widget.onEstimateSubmitted,
                        icon: const Icon(Icons.assessment, size: 16),
                        label: const Text('Estimate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
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
        const SizedBox(height: 4),
        Text(
          value,
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
    );
  }

  Color _getPriorityColor(JobPriority priority) {
    switch (priority) {
      case JobPriority.low:
        return Colors.green.shade600;
      case JobPriority.medium:
        return Colors.orange.shade600;
      case JobPriority.high:
        return Colors.red.shade600;
      case JobPriority.urgent:
        return Colors.deepPurple.shade600;
    }
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

  String _getCategoryDisplayName(String categoryId) {
    switch (categoryId) {
      case 'mechanics':
        return 'Automotive';
      case 'plumbers':
        return 'Plumbing';
      case 'electricians':
        return 'Electrical';
      case 'carpenters':
        return 'Carpentry';
      case 'cleaners':
        return 'Cleaning';
      case 'landscapers':
        return 'Landscaping';
      case 'painters':
        return 'Painting';
      case 'appliance_repair':
        return 'Appliance Repair';
      case 'hvac_specialists':
        return 'HVAC';
      case 'it_support':
        return 'IT Support';
      case 'security_systems':
        return 'Security';
      case 'hairdressers_barbers':
        return 'Hair Services';
      case 'makeup_artists':
        return 'Makeup';
      case 'nail_technicians':
        return 'Nail Services';
      case 'lash_technicians':
        return 'Lash Services';
      case 'glass_windows':
        return 'Glass & Windows';
      default:
        return categoryId.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/damage_report.dart';
import '../models/user_state.dart';
import '../services/real_time_distribution_service.dart';
import '../services/simple_notification_service.dart';
import 'damage_report_card.dart';
import 'time_picker_widget.dart';

class RealTimeDashboard extends StatefulWidget {
  const RealTimeDashboard({super.key});

  @override
  State<RealTimeDashboard> createState() => _RealTimeDashboardState();
}

class _RealTimeDashboardState extends State<RealTimeDashboard> {
  final RealTimeDistributionService _distributionService = RealTimeDistributionService();
  final SimpleNotificationService _notificationService = SimpleNotificationService();
  
  Stream<QuerySnapshot>? _damageReportsStream;
  Stream<QuerySnapshot>? _estimatesStream;
  
  List<Map<String, dynamic>> _liveDamageReports = [];
  List<Map<String, dynamic>> _myEstimates = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeRealTimeDashboard();
  }

  Future<void> _initializeRealTimeDashboard() async {
    try {
      setState(() => _isLoading = true);
      
      // Initialize the distribution service
      await _distributionService.initialize();
      
      // Subscribe to notifications
      await _notificationService.subscribeToDamageReports();
      await _notificationService.subscribeToEstimateRequests();
      
      // Set up real-time streams
      _setupRealTimeStreams();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize real-time dashboard: $e';
      });
    }
  }

  void _setupRealTimeStreams() {
    final userState = context.read<UserState>();
    final currentUserId = userState.userId;
    
    if (currentUserId == null) return;

    print('🔍 [RealTimeDashboard] Setting up streams for user: $currentUserId');
    print('🔍 [RealTimeDashboard] User role: ${userState.role}');
    print('🔍 [RealTimeDashboard] Is service professional: ${userState.isServiceProfessional}');
    print('🔍 [RealTimeDashboard] Service category IDs: ${userState.serviceCategoryIds}');

    // Stream for live service requests (pending status) - only for service professionals
    if (userState.isServiceProfessional && userState.serviceCategoryIds.isNotEmpty) {
      print('🔍 [RealTimeDashboard] Setting up job_requests stream for service professional');
      _damageReportsStream = FirebaseFirestore.instance
          .collection('job_requests')
          .where('categoryIds', arrayContainsAny: userState.serviceCategoryIds)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      print('🔍 [RealTimeDashboard] Setting up damage_reports stream (repairman or no categories)');
      // For repairmen, show damage reports
      _damageReportsStream = FirebaseFirestore.instance
          .collection('damage_reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    // Stream for user's estimates
    _estimatesStream = FirebaseFirestore.instance
        .collection('estimates')
        .where('professionalId', isEqualTo: currentUserId)
        .orderBy('submittedAt', descending: true)
        .snapshots();

    // Listen to streams
    _damageReportsStream?.listen(_onDamageReportsUpdated);
    _estimatesStream?.listen(_onEstimatesUpdated);
  }

  void _onDamageReportsUpdated(QuerySnapshot snapshot) {
    final reports = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    print('📋 REAL-TIME UPDATE - Total items: ${reports.length}');
    for (final report in reports) {
      print('   - Item ID: ${report['id']}, Title: ${report['title'] ?? 'N/A'}, Categories: ${report['categoryIds'] ?? 'N/A'}');
    }

    setState(() {
      _liveDamageReports = reports;
    });
  }

  void _onEstimatesUpdated(QuerySnapshot snapshot) {
    final estimates = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      _myEstimates = estimates;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.token),
            onPressed: _refreshFCMToken,
            tooltip: 'Refresh FCM Token',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotificationSettings,
            tooltip: 'Notification Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildDashboardContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Dashboard Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeRealTimeDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.new_releases),
                  text: 'Live Jobs',
                ),
                Tab(
                  icon: Icon(Icons.assessment),
                  text: 'My Estimates',
                ),
                Tab(
                  icon: Icon(Icons.analytics),
                  text: 'Analytics',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLiveReportsTab(),
                _buildMyEstimatesTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveReportsTab() {
    if (_liveDamageReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Live Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'New damage reports will appear here in real-time',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildLiveStatusHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _liveDamageReports.length,
            itemBuilder: (context, index) {
              final report = _liveDamageReports[index];
              return _buildLiveReportCard(report);
            },
          ),
        ),
      ],
    );
  }

  String _getActiveItemsText() {
    // Count service requests vs damage reports
    final serviceRequests = _liveDamageReports.where((report) => 
      report.containsKey('title') && report.containsKey('categoryIds')).length;
    final damageReports = _liveDamageReports.length - serviceRequests;
    
    if (serviceRequests > 0) {
      return '$serviceRequests active service requests';
    } else if (damageReports > 0) {
      return '$damageReports active damage reports';
    } else {
      return 'No active items';
    }
  }

  Widget _buildLiveStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.live_tv,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Updates Active',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getActiveItemsText(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveReportCard(Map<String, dynamic> report) {
    final reportId = report['id'] as String;
    final distributionStatus = _distributionService.getDistributionStatus(reportId);
    
    // Check if this is a service request or damage report
    final isServiceRequest = report.containsKey('title') && report.containsKey('categoryIds');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                isServiceRequest ? Icons.build : Icons.car_repair, 
                color: Colors.white
              ),
            ),
            title: Text(
              isServiceRequest 
                ? (report['title'] ?? 'No title')
                : '${report['vehicleYear'] ?? 'N/A'} ${report['vehicleMake'] ?? 'N/A'} ${report['vehicleModel'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isServiceRequest 
                    ? (report['description'] ?? 'No description')
                    : (report['damageDescription'] ?? 'No description')
                ),
                const SizedBox(height: 4),
                if (isServiceRequest && report['categoryIds'] != null) ...[
                  Text(
                    'Categories: ${(report['categoryIds'] as List).join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(report['createdAt']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleReportAction(value, report),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'submit_estimate',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Submit Estimate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_details',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'distribution_status',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Distribution Status'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Show images if they exist
          if (report['imageUrls'] != null && (report['imageUrls'] as List).isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (report['imageUrls'] as List).length,
                itemBuilder: (context, index) {
                  final imageUrl = (report['imageUrls'] as List)[index] as String;
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Est. Cost: \$${report['estimatedCost']?.toStringAsFixed(2) ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${distributionStatus['professionalsNotified']} notified',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyEstimatesTab() {
    if (_myEstimates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Estimates Submitted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your submitted estimates will appear here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myEstimates.length,
      itemBuilder: (context, index) {
        final estimate = _myEstimates[index];
        return _buildEstimateCard(estimate);
      },
    );
  }

  Widget _buildEstimateCard(Map<String, dynamic> estimate) {
    final status = estimate['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
          ),
        ),
        title: Text(
          'Estimate for Report #${estimate['reportId']?.substring(0, 8) ?? 'N/A'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cost: \$${estimate['cost']?.toStringAsFixed(2) ?? 'N/A'}'),
            Text('Lead Time: ${estimate['leadTimeDays'] != null ? TimeHelper.minutesToDisplayString(estimate['leadTimeDays']) : 'N/A'}'),
            Text('Status: ${status.toUpperCase()}'),
          ],
        ),
        trailing: Text(
          _formatTimestamp(estimate['submittedAt']),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-Time Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'Live Reports',
            value: _liveDamageReports.length.toString(),
            icon: Icons.new_releases,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'My Estimates',
            value: _myEstimates.length.toString(),
            icon: Icons.assessment,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'Response Rate',
            value: _calculateResponseRate(),
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _calculateResponseRate() {
    if (_liveDamageReports.isEmpty) return '0%';
    
    final respondedReports = _liveDamageReports.where((report) {
      final reportId = report['id'] as String;
      return _myEstimates.any((estimate) => estimate['reportId'] == reportId);
    }).length;
    
    final rate = (respondedReports / _liveDamageReports.length * 100).round();
    return '$rate%';
  }

  void _handleReportAction(String action, Map<String, dynamic> report) {
    switch (action) {
      case 'submit_estimate':
        _navigateToEstimateForm(report);
        break;
      case 'view_details':
        _viewReportDetails(report);
        break;
      case 'distribution_status':
        _showDistributionStatus(report);
        break;
    }
  }

  void _navigateToEstimateForm(Map<String, dynamic> report) {
    // Show estimate submission form as a modal dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submit Estimate',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              // Estimate form
              Expanded(
                child: _buildEstimateForm(report),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewReportDetails(Map<String, dynamic> report) {
    // Navigate to report details
    Navigator.pushNamed(
      context,
      '/report-details',
      arguments: report,
    );
  }

  void _showDistributionStatus(Map<String, dynamic> report) {
    final reportId = report['id'] as String;
    final status = _distributionService.getDistributionStatus(reportId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Distribution Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report ID: ${reportId.substring(0, 8)}...'),
            const SizedBox(height: 8),
            Text('Professionals Notified: ${status['professionalsNotified']}'),
            Text('Estimates Submitted: ${status['estimatesSubmitted']}'),
            Text('Status: ${status['isActive'] ? 'Active' : 'Inactive'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _refreshDashboard() {
    _initializeRealTimeDashboard();
  }

  void _refreshFCMToken() async {
    try {
      await _notificationService.refreshAndSaveFCMToken();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM token refreshed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh FCM token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Configure your notification preferences here.'),
            const SizedBox(height: 16),
            const Text('• New damage reports'),
            const Text('• Estimate requests'),
            const Text('• Estimate status updates'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _checkMissingFCMTokens();
              },
              icon: const Icon(Icons.search),
              label: const Text('Check Missing FCM Tokens'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _checkMissingFCMTokens() async {
    try {
      await _notificationService.checkAndFixMissingFCMTokens();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM token check completed. Check console for details.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check FCM tokens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEstimateForm(Map<String, dynamic> report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Damage Report Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Damage Report Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${report['vehicleYear']} ${report['vehicleMake']} ${report['vehicleModel']}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report['damageDescription'] ?? 'No description provided',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  // Show damage report images
                  if (report['imageUrls'] != null && 
                      (report['imageUrls'] as List).isNotEmpty) ...[
                    Text(
                      'Damage Photos:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (report['imageUrls'] as List).length,
                        itemBuilder: (context, index) {
                          final imageUrl = (report['imageUrls'] as List)[index] as String;
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Simple estimate form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit Estimate',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Estimated Cost',
                      hintText: 'Enter your estimated cost',
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Lead Time (Days)',
                      hintText: 'How many days to complete the work',
                      prefixIcon: Icon(Icons.schedule),
                      suffixText: 'days',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Service Description',
                      hintText: 'Describe the service work in detail',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Estimate submitted successfully!'),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Estimate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _damageReportsStream = null;
    _estimatesStream = null;
    super.dispose();
  }
}

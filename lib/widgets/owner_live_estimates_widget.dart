import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_state.dart';
import '../models/models.dart';
import '../services/real_time_distribution_service.dart';
import '../services/simple_notification_service.dart';
import '../services/firebase_firestore_service.dart';
import 'damage_report_card.dart';
import '../screens/service_professional_profile_screen.dart';
import 'time_picker_widget.dart';

class OwnerLiveEstimatesWidget extends StatefulWidget {
  const OwnerLiveEstimatesWidget({super.key});

  @override
  State<OwnerLiveEstimatesWidget> createState() => _OwnerLiveEstimatesWidgetState();
}

class _OwnerLiveEstimatesWidgetState extends State<OwnerLiveEstimatesWidget>
    with TickerProviderStateMixin {
  final RealTimeDistributionService _distributionService = RealTimeDistributionService();
  final SimpleNotificationService _notificationService = SimpleNotificationService();
  
  late TabController _tabController;
  Stream<QuerySnapshot>? _damageReportsStream;
  Stream<QuerySnapshot>? _estimatesStream;
  
  List<Map<String, dynamic>> _damageReports = [];
  List<Map<String, dynamic>> _estimates = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter states
  EstimateStatus? _selectedEstimateFilter;
  String? _selectedReportFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLiveData();
  }

    Future<void> _initializeLiveData() async {
    try {
      setState(() => _isLoading = true);

      print('🚀 INITIALIZING OWNER LIVE ESTIMATES WIDGET');

      // Initialize notification service
      await _notificationService.initialize();
      print('✅ Notification service initialized');

      // Set up real-time streams
      _setupRealTimeStreams();
      print('✅ Real-time streams set up');

      setState(() => _isLoading = false);
      print('✅ Live data initialization complete');
    } catch (e) {
      print('❌ Failed to initialize live data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize live data: $e';
      });
    }
  }

  void _setupRealTimeStreams() {
    final userState = context.read<UserState>();
    final currentUserId = userState.userId;
    
    if (currentUserId == null) {
      print('❌ No current user ID found');
      return;
    }

    print('👤 Setting up streams for user: $currentUserId');

    // Stream for user's damage reports
    _damageReportsStream = FirebaseFirestore.instance
        .collection('damage_reports')
        .where('ownerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    print('📋 Damage reports stream created for owner: $currentUserId');

    // Stream for estimates on user's reports
    _estimatesStream = FirebaseFirestore.instance
        .collection('estimates')
        .orderBy('submittedAt', descending: true)
        .snapshots();

    print('📊 Estimates stream created');

    // Listen to streams
    _damageReportsStream?.listen(_onDamageReportsUpdated);
    _estimatesStream?.listen(_onEstimatesUpdated);
    
    print('✅ Stream listeners attached');
  }

  void _onDamageReportsUpdated(QuerySnapshot snapshot) {
    if (!mounted) return; // Check if widget is still mounted
    final reports = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    print('📋 DAMAGE REPORTS UPDATE - Total reports: ${reports.length}');
    for (final report in reports) {
      print('   - Report ID: ${report['id']}, Owner ID: ${report['ownerId']}, Vehicle: ${report['vehicleYear']} ${report['vehicleMake']} ${report['vehicleModel']}');
    }

    setState(() {
      _damageReports = reports;
    });
  }

  void _onEstimatesUpdated(QuerySnapshot snapshot) {
    if (!mounted) return; // Check if widget is still mounted
    final userState = context.read<UserState>();
    final currentUserId = userState.userId;
    
    if (currentUserId == null) return;

    // Filter estimates to only show those for the current user's damage reports
    final allEstimates = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    // Get report IDs for current user
    final userReportIds = _damageReports.map((report) => report['id'] as String).toSet();
    
    // Filter estimates to only show those for user's reports
    final userEstimates = allEstimates.where((estimate) {
      final reportId = estimate['reportId'] as String?;
      final ownerId = estimate['ownerId'] as String?;
      
      // Log estimate details for debugging
      print('🔍 ESTIMATE FILTERING - Estimate ID: ${estimate['id']}, Report ID: $reportId, Owner ID: $ownerId, Current User: $currentUserId');
      
      // First try to match by ownerId (more efficient)
      if (ownerId != null && ownerId == currentUserId) {
        print('   ✅ Matched by ownerId: ${estimate['id']}');
        return true;
      }
      
      // Fall back to reportId matching if ownerId is not available
      if (reportId != null && userReportIds.contains(reportId)) {
        print('   ✅ Matched by reportId: ${estimate['id']}');
        return true;
      }
      
      print('   ❌ No match for estimate: ${estimate['id']}');
      return false;
    }).toList();

    print('📊 ESTIMATES UPDATE - Total estimates: ${allEstimates.length}, User estimates: ${userEstimates.length}, User reports: ${userReportIds.length}');

    setState(() {
      _estimates = userEstimates;
    });
  }

  List<Map<String, dynamic>> _getFilteredEstimates() {
    List<Map<String, dynamic>> filtered = _estimates;

    // Apply estimate status filter
    if (_selectedEstimateFilter != null) {
      filtered = filtered.where((estimate) {
        final status = estimate['status'] as String? ?? 'pending';
        return status == _selectedEstimateFilter.toString().split('.').last;
      }).toList();
    }

    // Apply report filter
    if (_selectedReportFilter != null) {
      filtered = filtered.where((estimate) {
        final reportId = estimate['reportId'] as String?;
        return reportId == _selectedReportFilter;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildFilterSection(),
        const SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5, // Use 50% of screen height
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDamageReportsTab(),
              _buildEstimatesTab(),
              _buildAnalyticsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Estimates & Reports',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Track your damage reports and estimates in real-time',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _migrateEstimates,
                icon: const Icon(Icons.sync, color: Colors.white),
                tooltip: 'Migrate Estimates',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _testEstimateRetrieval,
                icon: const Icon(Icons.bug_report, color: Colors.white),
                tooltip: 'Test Estimate Retrieval',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Data',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Estimate status filter
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<EstimateStatus?>(
              value: _selectedEstimateFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...EstimateStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedEstimateFilter = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Report filter
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String?>(
              value: _selectedReportFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Report',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Reports'),
                ),
                ..._damageReports.map((report) {
                  final vehicleInfo = '${report['vehicleYear']} ${report['vehicleMake']} ${report['vehicleModel']}';
                  return DropdownMenuItem(
                    value: report['id'],
                    child: Text(vehicleInfo.length > 25 ? '${vehicleInfo.substring(0, 25)}...' : vehicleInfo),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedReportFilter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageReportsTab() {
    if (_damageReports.isEmpty) {
      return _buildEmptyState(
        icon: Icons.car_repair,
        title: 'No Damage Reports',
        message: 'You haven\'t submitted any damage reports yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _damageReports.length,
      itemBuilder: (context, index) {
        final report = _damageReports[index];
        return _buildDamageReportCard(report);
      },
    );
  }

  Widget _buildEstimatesTab() {
    final filteredEstimates = _getFilteredEstimates();
    
    if (filteredEstimates.isEmpty) {
      if (_estimates.isEmpty) {
        return _buildEmptyState(
          icon: Icons.assessment,
          title: 'No Estimates Yet',
          message: 'Estimates will appear here when professionals submit them.',
        );
      } else {
        return _buildEmptyState(
          icon: Icons.filter_list,
          title: 'No Matching Estimates',
          message: 'Try adjusting your filters to see more estimates.',
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEstimates.length,
      itemBuilder: (context, index) {
        final estimate = filteredEstimates[index];
        return _buildEstimateCard(estimate);
      },
    );
  }

  Widget _buildAnalyticsTab() {
    final totalReports = _damageReports.length;
    final totalEstimates = _estimates.length;
    final pendingEstimates = _estimates.where((e) => e['status'] == 'pending').length;
    final acceptedEstimates = _estimates.where((e) => e['status'] == 'accepted').length;
    final declinedEstimates = _estimates.where((e) => e['status'] == 'declined').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-Time Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildAnalyticsCard(
            title: 'Total Damage Reports',
            value: totalReports.toString(),
            icon: Icons.car_repair,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'Total Estimates Received',
            value: totalEstimates.toString(),
            icon: Icons.assessment,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'Pending Estimates',
            value: pendingEstimates.toString(),
            icon: Icons.schedule,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'Accepted Estimates',
            value: acceptedEstimates.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'Declined Estimates',
            value: declinedEstimates.toString(),
            icon: Icons.cancel,
            color: Colors.red,
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

  Widget _buildDamageReportCard(Map<String, dynamic> report) {
    final reportId = report['id'] as String;
    final estimatesForReport = _estimates.where((e) => e['reportId'] == reportId).toList();
    final pendingEstimates = estimatesForReport.where((e) => e['status'] == 'pending').length;
    final acceptedEstimates = estimatesForReport.where((e) => e['status'] == 'accepted').length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.car_repair, color: Colors.white),
            ),
            title: Text(
              '${report['vehicleYear']} ${report['vehicleMake']} ${report['vehicleModel']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report['damageDescription'] ?? 'No description'),
                const SizedBox(height: 4),
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
                  value: 'view_estimates',
                  child: Row(
                    children: [
                      Icon(Icons.assessment),
                      SizedBox(width: 8),
                      Text('View Estimates'),
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
              ],
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
                      Icons.assessment,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$pendingEstimates pending, $acceptedEstimates accepted',
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

  Widget _buildEstimateCard(Map<String, dynamic> estimate) {
    final status = estimate['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);
    final reportId = estimate['reportId'] as String?;
    final ownerId = estimate['ownerId'] as String?;
    final professionalId = estimate['professionalId'] as String?;
    final professionalEmail = estimate['professionalEmail'] as String?;
    final professionalBio = estimate['professionalBio'] as String?;
    
    final report = _damageReports.firstWhere(
      (r) => r['id'] == reportId,
      orElse: () => <String, dynamic>{},
    );

    // Log estimate details for debugging
    print('🎯 BUILDING ESTIMATE CARD - ID: ${estimate['id']}, Status: $status, Owner: $ownerId, Professional: $professionalId');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(
                _getStatusIcon(status),
                color: Colors.white,
              ),
            ),
            title: GestureDetector(
              onTap: () => _viewProfessionalProfile(estimate),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimate from ${estimate['professionalName'] ?? professionalEmail ?? 'Professional'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                          ),
                        ),
                        Text(
                          'Tap to view profile',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.isNotEmpty)
                  Text('${report['vehicleYear']} ${report['vehicleMake']} ${report['vehicleModel']}'),
                Text('Cost: \$${estimate['cost']?.toStringAsFixed(2) ?? 'N/A'}'),
                Text('Lead Time: ${estimate['leadTimeDays'] != null ? TimeHelper.minutesToDisplayString(estimate['leadTimeDays']) : 'N/A'}'),
                Text('Status: ${status.toUpperCase()}'),
                if (professionalEmail != null)
                  Text('Contact: $professionalEmail', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (professionalBio != null && professionalBio.isNotEmpty)
                  Text('Bio: $professionalBio', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleEstimateAction(value, estimate),
              itemBuilder: (context) => [
                if (status == 'pending') ...[
                  const PopupMenuItem(
                    value: 'accept',
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Accept Estimate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'decline',
                    child: Row(
                      children: [
                        Icon(Icons.close, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Decline Estimate'),
                      ],
                    ),
                  ),
                ],
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
                  value: 'view_profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('View Professional Profile'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Submitted: ${_formatTimestamp(estimate['submittedAt'])}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _viewProfessionalProfile(estimate),
                  icon: const Icon(Icons.person, size: 14),
                  label: const Text('Profile', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
            'Error Loading Data',
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
            onPressed: _initializeLiveData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleReportAction(String action, Map<String, dynamic> report) {
    switch (action) {
      case 'view_estimates':
        // Filter estimates to show only this report
        setState(() {
          _selectedReportFilter = report['id'];
          _tabController.animateTo(1); // Switch to estimates tab
        });
        break;
      case 'view_details':
        // Show report details
        _showReportDetails(report);
        break;
    }
  }

  void _handleEstimateAction(String action, Map<String, dynamic> estimate) {
    switch (action) {
      case 'accept':
        _acceptEstimate(estimate);
        break;
      case 'decline':
        _declineEstimate(estimate);
        break;
      case 'view_details':
        _showEstimateDetails(estimate);
        break;
      case 'view_profile':
        _viewProfessionalProfile(estimate);
        break;
    }
  }

  Future<void> _acceptEstimate(Map<String, dynamic> estimate) async {
    try {
      final estimateId = estimate['id'] as String;
      final reportId = estimate['reportId'] as String;
      final ownerId = estimate['ownerId'] as String?;
      final professionalId = estimate['professionalId'] as String?;
      
      print('✅ ACCEPTING ESTIMATE - Estimate ID: $estimateId, Report ID: $reportId, Owner ID: $ownerId, Professional ID: $professionalId');
      
      // Use the service method to update estimate status
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.updateEstimateStatus(
        estimateId,
        'accepted',
        additionalData: {
          'acceptedAt': DateTime.now(),
        },
      );

      print('✅ Estimate status updated to accepted');

      // Update damage report status
      await FirebaseFirestore.instance
          .collection('damage_reports')
          .doc(reportId)
          .update({
        'status': 'accepted',
        'acceptedEstimateId': estimateId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Damage report status updated to accepted');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimate accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Failed to accept estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept estimate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineEstimate(Map<String, dynamic> estimate) async {
    try {
      final estimateId = estimate['id'] as String;
      final reportId = estimate['reportId'] as String;
      final ownerId = estimate['ownerId'] as String?;
      final professionalId = estimate['professionalId'] as String?;
      
      print('❌ DECLINING ESTIMATE - Estimate ID: $estimateId, Report ID: $reportId, Owner ID: $ownerId, Professional ID: $professionalId');
      
      // Use the service method to update estimate status
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.updateEstimateStatus(
        estimateId,
        'declined',
        additionalData: {
          'declinedAt': DateTime.now(),
        },
      );

      print('✅ Estimate status updated to declined');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimate declined successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ Failed to decline estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline estimate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${report['vehicleYear']} ${report['vehicleMake']} ${report['vehicleModel']}'),
            Text('Description: ${report['damageDescription'] ?? 'No description'}'),
            Text('Estimated Cost: \$${report['estimatedCost']?.toStringAsFixed(2) ?? 'N/A'}'),
            Text('Created: ${_formatTimestamp(report['createdAt'])}'),
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

  void _showEstimateDetails(Map<String, dynamic> estimate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estimate Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional: ${estimate['professionalName'] ?? 'Unknown'}'),
            Text('Cost: \$${estimate['cost']?.toStringAsFixed(2) ?? 'N/A'}'),
            Text('Lead Time: ${estimate['leadTimeDays'] ?? 'N/A'} days'),
            Text('Status: ${estimate['status']?.toString().toUpperCase() ?? 'PENDING'}'),
            Text('Submitted: ${_formatTimestamp(estimate['submittedAt'])}'),
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

  void _viewProfessionalProfile(Map<String, dynamic> estimate) {
    final professionalId = estimate['professionalId'] as String?;
    if (professionalId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.grey[900],
            body: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 1080,
                  maxHeight: 1080,
                ),
                width: MediaQuery.of(context).size.width > 1080 
                    ? 1080 
                    : MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height > 1080 
                    ? 1080 
                    : MediaQuery.of(context).size.height,
                child: ServiceProfessionalProfileScreen(
                  professionalId: professionalId,
                  isCustomerView: true,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professional profile not available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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

  String _getStatusDisplayName(EstimateStatus status) {
    switch (status) {
      case EstimateStatus.pending:
        return 'Pending';
      case EstimateStatus.accepted:
        return 'Accepted';
      case EstimateStatus.declined:
        return 'Declined';
    }
  }

  /// Refresh data manually
  Future<void> _refreshData() async {
    try {
      print('🔄 MANUAL REFRESH TRIGGERED');
      setState(() => _isLoading = true);
      
      // Re-initialize the data
      await _initializeLiveData();
      
      print('✅ Manual refresh completed');
    } catch (e) {
      print('❌ Manual refresh failed: $e');
      setState(() {
        _errorMessage = 'Refresh failed: $e';
      });
    }
  }

  /// Test estimate retrieval for debugging
  Future<void> _testEstimateRetrieval() async {
    try {
      print('🧪 TESTING ESTIMATE RETRIEVAL');
      final userState = context.read<UserState>();
      final currentUserId = userState.userId;
      
      if (currentUserId == null) {
        print('❌ No current user ID found');
        return;
      }
      
      print('👤 Testing for user: $currentUserId');
      
      // Test direct estimate retrieval
      final realTimeService = RealTimeDistributionService();
      final directEstimates = await realTimeService.getEstimatesByOwnerId(currentUserId);
      print('📊 Direct estimates found: ${directEstimates.length}');
      
      // Test estimate retrieval through damage reports
      final reportEstimates = await realTimeService.getEstimatesForOwner(currentUserId);
      print('📋 Report-based estimates found: ${reportEstimates.length}');
      
      // Show results in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test Results: Direct=${directEstimates.length}, Report-based=${reportEstimates.length}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Migrate existing estimates to include ownerId field
  Future<void> _migrateEstimates() async {
    try {
      print('🔄 MIGRATING ESTIMATES');
      setState(() => _isLoading = true);
      
      // Run the migration
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.migrateEstimatesWithOwnerId();
      
      // Refresh data after migration
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estimates migration completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Migration failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

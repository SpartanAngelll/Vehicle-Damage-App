import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../utils/responsive_utils.dart';
import 'responsive_layout.dart';
import 'damage_report_card.dart';

class RepairProfessionalDashboard extends StatefulWidget {
  const RepairProfessionalDashboard({super.key});

  @override
  State<RepairProfessionalDashboard> createState() => _RepairProfessionalDashboardState();
}

class _RepairProfessionalDashboardState extends State<RepairProfessionalDashboard> with TickerProviderStateMixin {
  late TabController _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Professional Dashboard',
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.work),
              text: 'Incoming Jobs',
            ),
            Tab(
              icon: Icon(Icons.assessment),
              text: 'My Estimates',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Profile',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingJobsTab(context),
          _buildMyEstimatesTab(context),
          _buildProfileTab(context),
        ],
      ),
    );
  }

  Widget _buildIncomingJobsTab(BuildContext context) {
    return Consumer2<AppState, UserState>(
      builder: (context, appState, userState, child) {
        if (!userState.isRepairman || userState.userId == null) {
          return Center(
            child: Text(
              'Access denied. Please sign in as a repair professional.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        final availableJobs = appState.getAvailableJobsForProfessional(userState.userId!);

        if (availableJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: ResponsiveUtils.getResponsiveIconSize(
                    context,
                    mobile: 64,
                    tablet: 80,
                    desktop: 96,
                  ),
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                Text(
                  'No Available Jobs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                Text(
                  'All current damage reports have estimates submitted.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ResponsiveLayout(
          mobile: _buildIncomingJobsMobile(context, availableJobs),
          tablet: _buildIncomingJobsTablet(context, availableJobs),
          desktop: _buildIncomingJobsDesktop(context, availableJobs),
        );
      },
    );
  }

  Widget _buildIncomingJobsMobile(BuildContext context, List<DamageReport> availableJobs) {
    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      itemCount: availableJobs.length,
      itemBuilder: (context, index) {
        final report = availableJobs[index];
        return DamageReportCard(
          report: report,
          index: index,
          showEstimateInput: true,
        );
      },
    );
  }

  Widget _buildIncomingJobsTablet(BuildContext context, List<DamageReport> availableJobs) {
    return GridView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
        mainAxisSpacing: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
      ),
      itemCount: availableJobs.length,
      itemBuilder: (context, index) {
        final report = availableJobs[index];
        return DamageReportCard(
          report: report,
          index: index,
          showEstimateInput: true,
        );
      },
    );
  }

  Widget _buildIncomingJobsDesktop(BuildContext context, List<DamageReport> availableJobs) {
    return GridView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
        mainAxisSpacing: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
      ),
      itemCount: availableJobs.length,
      itemBuilder: (context, index) {
        final report = availableJobs[index];
        return DamageReportCard(
          report: report,
          index: index,
          showEstimateInput: true,
        );
      },
    );
  }

  Widget _buildMyEstimatesTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isRepairman) {
          return Center(
            child: Text(
              'Access denied. Please sign in as a repair professional.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Summary cards
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Total Submitted',
                        userState.totalSubmittedEstimates.toString(),
                        Icons.assessment,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Pending',
                        userState.totalPendingEstimates.toString(),
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Accepted',
                        userState.totalAcceptedEstimates.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Declined',
                        userState.totalDeclinedEstimates.toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tab bar for estimate categories
              TabBar(
                tabs: [
                  Tab(text: 'Pending (${userState.totalPendingEstimates})'),
                  Tab(text: 'Accepted (${userState.totalAcceptedEstimates})'),
                  Tab(text: 'Declined (${userState.totalDeclinedEstimates})'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              
              // Tab bar view
              Expanded(
                child: TabBarView(
                  children: [
                    _buildEstimatesList(context, userState.pendingEstimates, 'Pending'),
                    _buildEstimatesList(context, userState.acceptedEstimates, 'Accepted'),
                    _buildEstimatesList(context, userState.declinedEstimates, 'Declined'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.getResponsiveIconSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
              color: color,
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 28,
                ),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatesList(BuildContext context, List<Estimate> estimates, String status) {
    if (estimates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'Pending' ? Icons.schedule : status == 'Accepted' ? Icons.check_circle : Icons.cancel,
              size: ResponsiveUtils.getResponsiveIconSize(
                context,
                mobile: 64,
                tablet: 80,
                desktop: 96,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
            Text(
              'No $status Estimates',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 28,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
            Text(
              status == 'Pending' 
                ? 'You don\'t have any pending estimates at the moment.'
                : status == 'Accepted'
                  ? 'No estimates have been accepted yet.'
                  : 'No estimates have been declined.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      itemCount: estimates.length,
      itemBuilder: (context, index) {
        final estimate = estimates[index];
        return _buildEstimateCard(context, estimate, index);
      },
    );
  }

  Widget _buildEstimateCard(BuildContext context, Estimate estimate, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Estimate #${index + 1}",
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
                      Text(
                        "Submitted: ${_formatDate(estimate.submittedAt)}",
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12),
                    vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 4, tablet: 6, desktop: 8),
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
            
            // Estimate details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cost:",
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
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isRepairman) {
          return Center(
            child: Text(
              'Access denied. Please sign in as a repair professional.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Card(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              mobile: 32,
                              tablet: 40,
                              desktop: 48,
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.build,
                              size: ResponsiveUtils.getResponsiveIconSize(
                                context,
                                mobile: 24,
                                tablet: 30,
                                desktop: 36,
                              ),
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Auto Repair Professional",
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      mobile: 20,
                                      tablet: 24,
                                      desktop: 28,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  userState.email ?? 'No email',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      mobile: 16,
                                      tablet: 18,
                                      desktop: 20,
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
              ),
              
              SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
              
              // Bio section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                          Text(
                            "Professional Bio",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                      
                      if (userState.bio != null && userState.bio!.isNotEmpty) ...[
                        Text(
                          userState.bio!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                      ] else ...[
                        Text(
                          "No bio added yet. Add a professional bio to help vehicle owners learn about your expertise.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                      ],
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _editBio(context, userState),
                          icon: Icon(Icons.edit),
                          label: Text(
                            userState.bio != null && userState.bio!.isNotEmpty
                                ? "Edit Bio"
                                : "Add Bio",
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Future<void> _editBio(BuildContext context, UserState userState) async {
    final TextEditingController bioController = TextEditingController(text: userState.bio ?? '');
    final int maxLength = 500;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Professional Bio',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tell vehicle owners about your experience, certifications, and specialties.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                  TextField(
                    controller: bioController,
                    maxLines: 4,
                    maxLength: maxLength,
                    decoration: InputDecoration(
                      hintText: 'Enter your professional bio...',
                      border: OutlineInputBorder(),
                      counterText: '${bioController.text.length}/$maxLength characters',
                      counterStyle: TextStyle(
                        color: bioController.text.length > maxLength * 0.9
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final bio = bioController.text.trim();
                final navigator = Navigator.of(context);

                if (bio.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bio cannot be empty'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                try {
                  await userState.updateBio(bio);
                  if (mounted) {
                    navigator.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bio updated successfully!'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update bio: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final userState = context.read<UserState>();
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                await userState.signOut();
                navigator.pop(); // Close dialog first
                if (mounted) {
                  navigator.pushReplacementNamed('/login');
                }
              } catch (e) {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                navigator.pop(); // Close dialog on error too
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }
}

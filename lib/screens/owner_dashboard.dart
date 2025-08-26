import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/models.dart';
import '../services/image_service.dart';
import '../widgets/widgets.dart';
import '../utils/responsive_utils.dart';
import '../services/services.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/damage_report_card.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final TextEditingController descController = TextEditingController();
  final TextEditingController makeController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  bool _isUploading = false;
  bool _isLoadingEstimates = false;
  bool _hasLoadedEstimates = false;
  
  @override
  void initState() {
    super.initState();
    // Don't auto-load estimates to prevent UI blocking
  }
  
  Future<void> _loadEstimatesAsync() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingEstimates = true;
    });
    
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.loadEstimatesForOwner();
      if (mounted) {
        setState(() {
          _hasLoadedEstimates = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load estimates: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEstimates = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Vehicle Owner Dashboard',
          header: true,
          child: Text(
            "Vehicle Owner",
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20, tablet: 24, desktop: 28),
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
          ThemeSelector(),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigate to different sections
          switch (index) {
            case 0:
              // Already on main dashboard
              break;
            case 1:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 10, tablet: 15, desktop: 20)),
                _buildUploadSection(context, appState),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 30, tablet: 40, desktop: 50)),
                _buildRequestsSection(context, appState),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 30, tablet: 40, desktop: 50)),
                _buildEstimatesSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Upload Damage section heading',
          header: true,
          child: Text(
            "Upload Damage", 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 22, tablet: 26, desktop: 30), 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            )
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 10, tablet: 15, desktop: 20)),
        Text(
          "Take a photo or select from gallery. You'll be able to review and confirm the image before it goes live to repair professionals.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Damage description input field',
                textField: true,
                child: TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: "Describe damage",
                    hintText: "Enter a description of the vehicle damage",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                      vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                    ),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 10, tablet: 15, desktop: 20)),
            // Camera button
            Semantics(
              label: 'Upload damage photo using camera',
              button: true,
              child: ElevatedButton.icon(
                icon: _isUploading
                  ? SizedBox(
                      width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                      height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                    )
                  : Semantics(
                      label: 'Camera icon',
                      child: Icon(
                        Icons.camera_alt, 
                        size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32)
                      ),
                    ),
                label: Text(
                  _isUploading ? "Uploading..." : "Camera",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20)
                  ),
                ),
                onPressed: _isUploading ? null : () => _uploadImage(context, appState, ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: Size(
                    ResponsiveUtils.getResponsiveButtonWidth(context, mobile: 100, tablet: 120, desktop: 140),
                    ResponsiveUtils.getResponsiveButtonHeight(context, mobile: 50, tablet: 60, desktop: 70),
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
            // Gallery button
            Semantics(
              label: 'Select damage photo from gallery',
              button: true,
              child: ElevatedButton.icon(
                icon: _isUploading
                  ? SizedBox(
                      width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                      height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                    )
                  : Semantics(
                      label: 'Gallery icon',
                      child: Icon(
                        Icons.photo_library, 
                        size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32)
                      ),
                    ),
                label: Text(
                  _isUploading ? "Uploading..." : "Gallery",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20)
                  ),
                ),
                onPressed: _isUploading ? null : () => _uploadImage(context, appState, ImageSource.gallery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  minimumSize: Size(
                    ResponsiveUtils.getResponsiveButtonWidth(context, mobile: 100, tablet: 120, desktop: 140),
                    ResponsiveUtils.getResponsiveButtonHeight(context, mobile: 50, tablet: 60, desktop: 70),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestsSection(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'My Requests section heading',
          header: true,
          child: Text(
            "My Requests", 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20, tablet: 24, desktop: 28), 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            )
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 10, tablet: 15, desktop: 20)),
        appState.reports.isEmpty
            ? Center(
                child: Semantics(
                  label: 'No damage requests submitted yet',
                  child: Text(
                    "No requests yet.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : _buildResponsiveGrid(context, appState),
      ],
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, AppState appState) {
    if (appState.reports.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Use simple Column for all screen sizes to avoid performance issues
    return Column(
      children: appState.reports.asMap().entries.map((entry) {
        final index = entry.key;
        final report = entry.value;
        return DamageReportCard(
          report: report,
          index: index,
          showEstimateInput: false, // Vehicle owners don't submit estimates
        );
      }).toList(),
    );
  }

  Widget _buildEstimatesSection(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'My Estimates section heading',
                    header: true,
                    child: Text(
                      "My Estimates", 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20, tablet: 24, desktop: 28), 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadEstimatesAsync,
                  icon: Icon(Icons.refresh),
                  tooltip: 'Refresh estimates',
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 10, tablet: 15, desktop: 20)),
            if (_isLoadingEstimates)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 30, desktop: 40)),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                      Text(
                        'Loading estimates...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!_hasLoadedEstimates)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 30, desktop: 40)),
                  child: Column(
                    children: [
                      Icon(
                        Icons.refresh,
                        size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 48, tablet: 56, desktop: 64),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                      Text(
                        'Tap refresh to load estimates',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (userState.receivedEstimates.isEmpty)
              Semantics(
                label: 'No estimates received yet',
                child: Text(
                  "No estimates received yet.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Wrap(
                    spacing: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16),
                    runSpacing: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16),
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.28,
                        child: _buildEstimateSummaryCard(
                          context,
                          'Pending',
                          userState.pendingEstimates.length.toString(),
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.28,
                        child: _buildEstimateSummaryCard(
                          context,
                          'Accepted',
                          userState.acceptedEstimates.length.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.28,
                        child: _buildEstimateSummaryCard(
                          context,
                          'Declined',
                          userState.declinedEstimates.length.toString(),
                          Icons.cancel,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
                  // Estimates list
                  Column(
                    children: userState.receivedEstimates.map((estimate) {
                      return _buildEstimateCard(context, estimate);
                    }).toList(),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildEstimateSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
              color: color,
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12)),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18, tablet: 22, desktop: 26),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateCard(BuildContext context, Estimate estimate) {
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
                Icon(
                  estimate.status == EstimateStatus.pending ? Icons.schedule 
                    : estimate.status == EstimateStatus.accepted ? Icons.check_circle 
                    : Icons.cancel,
                  color: estimate.status == EstimateStatus.pending ? Colors.orange 
                    : estimate.status == EstimateStatus.accepted ? Colors.green 
                    : Colors.red,
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                Expanded(
                  child: Text(
                    'Estimate from ${estimate.repairProfessionalEmail}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16),
                    vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 4, tablet: 6, desktop: 8),
                  ),
                  decoration: BoxDecoration(
                    color: estimate.status == EstimateStatus.pending ? Colors.orange.withOpacity(0.1)
                      : estimate.status == EstimateStatus.accepted ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: estimate.status == EstimateStatus.pending ? Colors.orange
                        : estimate.status == EstimateStatus.accepted ? Colors.green
                        : Colors.red,
                    ),
                  ),
                  child: Text(
                    estimate.status.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                      fontWeight: FontWeight.bold,
                      color: estimate.status == EstimateStatus.pending ? Colors.orange
                        : estimate.status == EstimateStatus.accepted ? Colors.green
                        : Colors.red,
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
                        'Cost: \$${estimate.cost.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 4, tablet: 6, desktop: 8)),
                      Text(
                        'Lead Time: ${estimate.leadTimeDays} days',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (estimate.status == EstimateStatus.pending)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => _acceptEstimate(context, estimate),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Accept'),
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12)),
                      ElevatedButton(
                        onPressed: () => _declineEstimate(context, estimate),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Decline'),
                      ),
                    ],
                  ),
              ],
            ),
            if (estimate.description.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 4, tablet: 6, desktop: 8)),
              Text(
                estimate.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 10, desktop: 12)),
            Text(
              'Submitted: ${estimate.submittedAt.toString().split('.')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptEstimate(BuildContext context, Estimate estimate) async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.updateReceivedEstimateStatus(
        estimateId: estimate.id,
        status: EstimateStatus.accepted,
        acceptedAt: DateTime.now(),
        acceptedCost: estimate.cost,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estimate accepted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept estimate: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _declineEstimate(BuildContext context, Estimate estimate) async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.updateReceivedEstimateStatus(
        estimateId: estimate.id,
        status: EstimateStatus.declined,
        declinedAt: DateTime.now(),
        declinedCost: estimate.cost,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estimate declined successfully!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline estimate: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                final authService = context.read<FirebaseAuthService>();
                final userState = context.read<UserState>();
                
                await authService.signOut();
                userState.clearUserState();
                
                Navigator.pop(context); // Close dialog first
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                Navigator.pop(context); // Close dialog on error too
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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

  Future<bool> _showImageConfirmation(BuildContext context, File imageFile) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Confirm Damage Photo',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Image preview
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: ResponsiveUtils.getResponsiveIconSize(
                                    context,
                                    mobile: 48,
                                    tablet: 56,
                                    desktop: 64,
                                  ),
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      mobile: 16,
                                      tablet: 18,
                                      desktop: 20,
                                    ),
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Action buttons
                Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                  child: Row(
                    children: [
                      // Retake button
                      Expanded(
                        child: Semantics(
                          label: 'Retake damage photo',
                          button: true,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: Icon(Icons.camera_alt),
                            label: Text(
                              'Retake',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                      
                      // Confirm button
                      Expanded(
                        child: Semantics(
                          label: 'Confirm and upload damage photo',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(true),
                            icon: Icon(Icons.check),
                            label: Text(
                              'Confirm & Upload',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  Future<bool?> _showVehicleInfoDialog(BuildContext context) async {
    // Pre-fill with current year if empty
    if (yearController.text.isEmpty) {
      yearController.text = DateTime.now().year.toString();
    }
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Vehicle Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: makeController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Make (e.g., Toyota)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: modelController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Model (e.g., Camry)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: yearController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Year',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (makeController.text.isNotEmpty && 
                    modelController.text.isNotEmpty && 
                    yearController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all vehicle information.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImage(BuildContext context, AppState appState, ImageSource source) async {
    setState(() { _isUploading = true; });
    try {
      final imageFile = source == ImageSource.camera
          ? await ImageService.pickImageFromCamera()
          : await ImageService.pickImageFromGallery();
          
      if (imageFile != null) {
        // Validate the image file
        if (!ImageService.isValidImageFile(imageFile)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid image file. Please select a valid image (JPEG, PNG, GIF, BMP) under 10MB.'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        
        // Show image confirmation dialog
        final confirmed = await _showImageConfirmation(context, imageFile);
        if (confirmed && mounted) {
          // Get the current authenticated user's ID
          final userState = Provider.of<UserState>(context, listen: false);
          if (userState.isAuthenticated && userState.userId != null) {
            // Show vehicle information dialog
            final vehicleConfirmed = await _showVehicleInfoDialog(context);
            if (vehicleConfirmed == true && mounted) {
              await appState.addReport(
                ownerId: userState.userId!,
                vehicleMake: makeController.text,
                vehicleModel: modelController.text,
                vehicleYear: int.parse(yearController.text),
                damageDescription: descController.text,
                image: imageFile,
                estimatedCost: 0.0,
                additionalNotes: null,
              );
              
              // Clear vehicle info controllers
              makeController.clear();
              modelController.clear();
              yearController.clear();
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please log in to submit damage reports.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
          descController.clear();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Damage report uploaded successfully!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) { setState(() { _isUploading = false; }); }
    }
  }

  @override
  void dispose() {
    descController.dispose();
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    super.dispose();
  }
}

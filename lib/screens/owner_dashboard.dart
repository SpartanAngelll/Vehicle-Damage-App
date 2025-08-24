import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/models.dart';
import '../services/image_service.dart';
import '../widgets/widgets.dart';
import '../utils/responsive_utils.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final TextEditingController descController = TextEditingController();
  bool _isUploading = false;
  
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
    final appState = Provider.of<AppState>(context);
    
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 10, tablet: 15, desktop: 20)),
          _buildUploadSection(context, appState),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 30, tablet: 40, desktop: 50)),
          _buildRequestsSection(context, appState),
        ],
      ),
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
    return Expanded(
      child: Column(
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
          Expanded(
            child: appState.reports.isEmpty
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
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, AppState appState) {
    if (ResponsiveUtils.isMobile(context)) {
      return ListView.builder(
        itemCount: appState.reports.length,
        itemBuilder: (context, i) {
          final report = appState.reports[i];
          return DamageReportCard(
            report: report,
            index: i,
            showEstimateInput: false, // Vehicle owners don't submit estimates
          );
        },
      );
    } else {
      // Tablet and desktop use grid layout
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.isTablet(context) ? 2 : 3,
          childAspectRatio: ResponsiveUtils.isTablet(context) ? 1.2 : 1.0,
          crossAxisSpacing: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
          mainAxisSpacing: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
        ),
        itemCount: appState.reports.length,
        itemBuilder: (context, i) {
          final report = appState.reports[i];
          return DamageReportCard(
            report: report,
            index: i,
            showEstimateInput: false, // Vehicle owners don't submit estimates
          );
        },
      );
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
                final userState = context.read<UserState>();
                await userState.signOut();
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

  Future<void> _uploadImage(BuildContext context, AppState appState, ImageSource source) async {
    setState(() { _isUploading = true; });
    try {
      final imageFile = source == ImageSource.camera
          ? await ImageService.pickImageFromCamera(context)
          : await ImageService.pickImageFromGallery(context);
          
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
          await appState.addReport(imageFile, description: descController.text);
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
    super.dispose();
  }
}

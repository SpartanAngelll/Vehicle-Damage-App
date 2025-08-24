import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isRequesting = false;

  final List<PermissionInfo> _permissions = [
    PermissionInfo(
      title: 'Camera Access',
      description: 'Required to take photos of vehicle damage for repair estimates',
      icon: Icons.camera_alt,
      color: Colors.blue,
      isRequired: true,
    ),
    PermissionInfo(
      title: 'Storage Access',
      description: 'Needed to save photos and access your photo gallery',
      icon: Icons.photo_library,
      color: Colors.green,
      isRequired: true,
    ),
    PermissionInfo(
      title: 'Location Access',
      description: 'Helps repair professionals find your location for better service',
      icon: Icons.location_on,
      color: Colors.orange,
      isRequired: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Permissions'),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Permissions Required',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
          Text(
            'The app needs these permissions to function properly. You can change them later in settings.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 24, tablet: 32, desktop: 40)),
          
          // Permissions list
          Expanded(
            child: ListView.builder(
              itemCount: _permissions.length,
              itemBuilder: (context, index) {
                return _buildPermissionCard(context, _permissions[index]);
              },
            ),
          ),
          
          // Action buttons
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Skip permissions and continue',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Skip for Now',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
              Expanded(
                child: Semantics(
                  label: 'Grant all required permissions',
                  button: true,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _requestAllPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                      ),
                    ),
                    child: _isRequesting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Grant Permissions',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildPermissionCard(BuildContext context, PermissionInfo permission) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
              decoration: BoxDecoration(
                color: permission.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                permission.icon,
                color: permission.color,
                size: ResponsiveUtils.getResponsiveIconSize(
                  context,
                  mobile: 32,
                  tablet: 36,
                  desktop: 40,
                ),
              ),
            ),
            
            SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        permission.title,
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
                      SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                      if (permission.isRequired)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 6, tablet: 8, desktop: 10),
                            vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 2, tablet: 4, desktop: 6),
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
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
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 4, tablet: 6, desktop: 8)),
                  Text(
                    permission.description,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() { _isRequesting = true; });
    
    try {
      final allGranted = await PermissionService.checkAllRequiredPermissions(context);
      
      if (mounted) {
        if (allGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All permissions granted! Proceeding to login.'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate to login after a short delay
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Some permissions were not granted. You can still use the app with limited functionality.'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate to login anyway
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isRequesting = false; });
      }
    }
  }
}

class PermissionInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isRequired;

  PermissionInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isRequired,
  });
}

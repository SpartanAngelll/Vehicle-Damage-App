import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../services/services.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/theme_selector.dart';
import '../widgets/banking_details_card.dart';
import '../widgets/banking_details_form.dart';
import '../theme/theme_provider.dart';
import '../services/permission_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  String _storageInfo = '';

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final userData = await LocalStorageService.getUserId();
      final themeMode = await LocalStorageService.getThemeMode();
      final onboardingCompleted = await LocalStorageService.isOnboardingCompleted();
      
      setState(() {
        _storageInfo = '''
User Data: ${userData != null ? 'Stored' : 'Not stored'}
Theme Mode: ${themeMode ?? 'Default'}
Onboarding: ${onboardingCompleted ? 'Completed' : 'Not completed'}
        '''.trim();
      });
    } catch (e) {
      setState(() {
        _storageInfo = 'Error loading storage info: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
          ThemeSelector(),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, "User Profile"),
          _buildUserInfoCard(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
          
          // Banking Details section for service professionals
          Consumer<UserState>(
            builder: (context, userState, child) {
              if (userState.isServiceProfessional) {
                return Column(
                  children: [
                    _buildSectionHeader(context, "Banking Details"),
                    _buildBankingDetailsCard(context),
                    SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
          
          _buildSectionHeader(context, "App Settings"),
          _buildAppSettingsCard(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
          
          _buildSectionHeader(context, "Storage Information"),
          _buildStorageInfoCard(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
          
          _buildSectionHeader(context, "Data Management"),
          _buildDataManagementCard(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
          
          _buildSectionHeader(context, "App Permissions"),
          _buildPermissionsCard(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
          
          _buildSectionHeader(context, "Onboarding"),
          _buildOnboardingCard(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, "User Profile"),
                _buildUserInfoCard(context),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                
                // Banking Details section for service professionals
                Consumer<UserState>(
                  builder: (context, userState, child) {
                    if (userState.isServiceProfessional) {
                      return Column(
                        children: [
                          _buildSectionHeader(context, "Banking Details"),
                          _buildBankingDetailsCard(context),
                          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                
                _buildSectionHeader(context, "App Settings"),
                _buildAppSettingsCard(context),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                
                _buildSectionHeader(context, "Storage Information"),
                _buildStorageInfoCard(context),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, "Data Management"),
                _buildDataManagementCard(context),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                
                _buildSectionHeader(context, "App Permissions"),
                _buildPermissionsCard(context),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                
                _buildSectionHeader(context, "Onboarding"),
                _buildOnboardingCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, "User Profile"),
                _buildUserInfoCard(context),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                
                // Banking Details section for service professionals
                Consumer<UserState>(
                  builder: (context, userState, child) {
                    if (userState.isServiceProfessional) {
                      return Column(
                        children: [
                          _buildSectionHeader(context, "Banking Details"),
                          _buildBankingDetailsCard(context),
                          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                
                _buildSectionHeader(context, "App Settings"),
                _buildAppSettingsCard(context),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, "Storage Information"),
                _buildStorageInfoCard(context),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                
                _buildSectionHeader(context, "Data Management"),
                _buildDataManagementCard(context),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, "App Permissions"),
                _buildPermissionsCard(context),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                
                _buildSectionHeader(context, "Onboarding"),
                _buildOnboardingCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: ResponsiveUtils.getResponsiveFontSize(
            context,
            mobile: 20,
            tablet: 24,
            desktop: 28,
          ),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isAuthenticated) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
              child: Text(
                "Not signed in",
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
            ),
          );
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, "Email", userState.email ?? 'N/A'),
                _buildInfoRow(context, "Phone", userState.phoneNumber ?? 'N/A'),
                _buildInfoRow(context, "Role", _getRoleDisplayName(userState)),
                if (userState.lastLoginTime != null)
                  _buildInfoRow(context, "Last Login", _formatDate(userState.lastLoginTime!)),
                
                if (userState.isRepairman) ...[
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 20, tablet: 24, desktop: 28)),
                  _buildBioCard(context, userState),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoleDisplayName(UserState userState) {
    if (userState.isOwner) {
      return 'Service Customer';
    } else if (userState.isServiceProfessional) {
      return 'Service Professional';
    } else if (userState.isRepairman) {
      return 'Auto Repair Professional';
    } else {
      return 'Unknown Role';
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
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
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(BuildContext context, UserState userState) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),

            if (userState.bio != null && userState.bio!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  userState.bio!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
            ],

            Semantics(
              label: 'Edit professional bio',
              button: true,
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
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Theme Settings",
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
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            _showThemeSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Storage Information",
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
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _storageInfo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            Semantics(
              label: 'Refresh storage information',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _loadStorageInfo,
                icon: Icon(Icons.refresh),
                label: Text(
                  "Refresh",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Management",
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
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            Text(
              "Manage your app data and storage",
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
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Clear user data',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: () => _showClearUserDataDialog(context),
                      icon: Icon(Icons.person_off),
                      label: Text(
                        "Clear User Data",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                Expanded(
                  child: Semantics(
                    label: 'Clear all app data',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: () => _showClearAllDataDialog(context),
                      icon: Icon(Icons.delete_forever),
                      label: Text(
                        "Clear All Data",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
            Semantics(
              label: 'Sign out',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: Icon(Icons.logout),
                label: Text(
                  "Sign Out",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "App Permissions",
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
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            Text(
              "Manage app permissions for camera, location, and storage access",
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
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Check current permission status',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: () => _checkPermissionStatus(context),
                      icon: Icon(Icons.security),
                      label: Text(
                        "Check Status",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                Expanded(
                  child: Semantics(
                    label: 'Request all required permissions',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: () => _requestAllPermissions(context),
                      icon: Icon(Icons.check_circle),
                      label: Text(
                        "Request All",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Onboarding",
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
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
            Text(
              "Reset onboarding to show the introduction screens again",
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
            Semantics(
              label: 'Reset onboarding status',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () => _toggleOnboarding(context),
                icon: Icon(Icons.refresh),
                label: Text(
                  "Reset Onboarding",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Theme Mode:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Light theme',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.themeMode == ThemeMode.light
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        foregroundColor: themeProvider.themeMode == ThemeMode.light
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: Text(
                        "Light",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                Expanded(
                  child: Semantics(
                    label: 'Dark theme',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.themeMode == ThemeMode.dark
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        foregroundColor: themeProvider.themeMode == ThemeMode.dark
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: Text(
                        "Dark",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16)),
                Expanded(
                  child: Semantics(
                    label: 'System theme',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () => themeProvider.setThemeMode(ThemeMode.system),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.themeMode == ThemeMode.system
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        foregroundColor: themeProvider.themeMode == ThemeMode.system
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: Text(
                        "System",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleOnboarding(BuildContext context) async {
    try {
      await LocalStorageService.setOnboardingCompleted(completed: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Onboarding reset successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset onboarding: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showClearUserDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear User Data"),
        content: Text("This will clear all your user data including profile information. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await LocalStorageService.clearUserData();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User data cleared successfully!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear user data: ${e.toString()}'),
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
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Data"),
        content: Text("This will clear ALL app data including user data, settings, and preferences. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await LocalStorageService.clearAllData();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All data cleared successfully!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear all data: ${e.toString()}'),
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
            child: Text("Clear All"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPermissionStatus(BuildContext context) async {
    try {
      await PermissionService.showPermissionStatus(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permissions: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _requestAllPermissions(BuildContext context) async {
    try {
      final allGranted = await PermissionService.checkAllRequiredPermissions(context);
      if (mounted) {
        if (allGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All required permissions granted!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Some permissions were not granted. Check the permission status for details.'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final authService = context.read<FirebaseAuthService>();
      final userState = context.read<UserState>();
      
      await authService.signOut();
      userState.clearUserState();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed out successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                    Navigator.of(context).pop();
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

  Widget _buildBankingDetailsCard(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isServiceProfessional || userState.userId == null) {
          return SizedBox.shrink();
        }

        return StreamBuilder<BankingDetails?>(
          stream: BankingDetailsService.instance.streamBankingDetails(userState.userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return BankingDetailsCard(
                isLoading: true,
              );
            }

            return BankingDetailsCard(
              bankingDetails: snapshot.data,
              onEdit: () => _showBankingDetailsDialog(context, userState.userId!, snapshot.data),
              onAdd: () => _showBankingDetailsDialog(context, userState.userId!, null),
            );
          },
        );
      },
    );
  }

  void _showBankingDetailsDialog(BuildContext context, String professionalId, BankingDetails? existingDetails) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: ResponsiveUtils.getResponsiveWidth(context, mobile: 400, tablet: 500, desktop: 600),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        existingDetails != null ? 'Edit Banking Details' : 'Add Banking Details',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
              // Form content
              Flexible(
                child: BankingDetailsForm(
                  initialData: existingDetails != null 
                      ? BankingDetailsFormData.fromBankingDetails(existingDetails)
                      : null,
                  onSave: (formData) async {
                    try {
                      final bankingDetails = formData.toBankingDetails(professionalId);
                      final validationResult = BankingDetailsService.instance.validateBankingDetails(bankingDetails);
                      
                      if (!validationResult.isValid) {
                        // Show validation errors
                        final errorMessages = validationResult.errors.values.join('\n');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please fix the following errors:\n$errorMessages'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }

                      // Save banking details
                      await BankingDetailsService.instance.saveBankingDetails(bankingDetails);
                      
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(existingDetails != null 
                                ? 'Banking details updated successfully!' 
                                : 'Banking details added successfully!'),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save banking details: ${e.toString()}'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/user_state.dart';
import '../services/firebase_auth_service.dart';
import '../utils/responsive_utils.dart';
import 'profile_avatar.dart';

/// Web-optimized layout wrapper with sidebar navigation
/// This provides a professional web app experience
class WebLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final Function(String)? onNavigate;

  const WebLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final userState = Provider.of<UserState>(context);
    final authService = Provider.of<FirebaseAuthService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768; // Mobile breakpoint
    final isTablet = screenWidth >= 768 && screenWidth < 1024; // Tablet breakpoint

    if (!isWeb) {
      // On native mobile, just return the child without web layout
      return child;
    }

    // On mobile web, use mobile layout with drawer
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getPageTitle(currentRoute)),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(context, userState, authService),
        body: child,
      );
    }

    // Determine max width based on screen size
    final maxWidth = _getMaxWidth(screenWidth);
    final isLargeScreen = screenWidth > 1600;

    return Scaffold(
      drawer: isTablet ? _buildDrawer(context, userState, authService) : null,
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            children: [
              // Sidebar Navigation (hidden on tablet, shown on desktop)
              if (!isTablet) _buildSidebar(context, userState, authService),
              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar
                    _buildTopBar(context, userState, authService, isTablet),
                    // Main Content with padding
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 32 : (isTablet ? 16 : 24),
                          vertical: 16,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    // Responsive max widths based on screen size
    if (screenWidth > 1920) {
      return 1600; // Ultra-wide screens
    } else if (screenWidth > 1600) {
      return 1400; // Large desktop
    } else if (screenWidth > 1280) {
      return 1200; // Standard desktop
    } else if (screenWidth > 1024) {
      return 1000; // Small desktop/large tablet
    } else {
      return screenWidth; // Tablet and below - use full width
    }
  }

  Widget _buildSidebar(BuildContext context, UserState userState, FirebaseAuthService authService) {
    final isOwner = userState.isOwner;
    final isProfessional = userState.isServiceProfessional || userState.isRepairman;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sidebar width
    final sidebarWidth = (screenWidth > 1600 ? 280.0 : 260.0);

    return Container(
      width: sidebarWidth,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Logo/Brand
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.handyman,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'ServicePro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isOwner) ..._buildOwnerNavItems(context),
                if (isProfessional) ..._buildProfessionalNavItems(context),
              ],
            ),
          ),
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: ProfileAvatar(
                    profilePhotoUrl: userState.profilePhotoUrl,
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    fallbackIcon: Icons.person,
                    fallbackIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  title: Text(
                    userState.fullName ?? 'User',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    userState.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => _navigate(context, '/customerEditProfile'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigate(context, '/settings'),
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Settings'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context, authService),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
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

  List<Widget> _buildOwnerNavItems(BuildContext context) {
    // Check if current route has estimates tab parameter
    final hasEstimatesTab = currentRoute.contains('tab=estimates');
    // Dashboard is active only if route is exactly /ownerDashboard (no query params)
    final isDashboardRoute = currentRoute == '/ownerDashboard';
    
    return [
      _buildNavItem(
        context,
        icon: Icons.home, // Changed from dashboard to match mobile
        label: 'Dashboard',
        route: '/ownerDashboard',
        isActive: isDashboardRoute,
        onTap: () {
          // Navigate to dashboard home tab
          if (onNavigate != null) {
            onNavigate!('/ownerDashboard');
          } else {
            Navigator.pushNamed(context, '/ownerDashboard');
          }
        },
      ),
      _buildNavItem(
        context,
        icon: Icons.add, // Changed from add_circle_outline to match mobile
        label: 'Create Request',
        route: '/serviceRequest',
        isActive: currentRoute == '/serviceRequest',
      ),
      _buildNavItem(
        context,
        icon: Icons.search,
        label: 'Search Professionals',
        route: '/searchProfessionals',
        isActive: currentRoute == '/searchProfessionals',
      ),
      _buildNavItem(
        context,
        icon: Icons.assessment,
        label: 'My Requests',
        route: '/myServiceRequests',
        isActive: currentRoute == '/myServiceRequests',
      ),
      _buildNavItem(
        context,
        icon: Icons.receipt_long,
        label: 'Estimates',
        route: '/ownerDashboard?tab=estimates',
        isActive: hasEstimatesTab,
        onTap: () {
          // Navigate and set estimates tab immediately
          if (onNavigate != null) {
            onNavigate!('/ownerDashboard?tab=estimates');
          } else {
            Navigator.pushNamed(context, '/ownerDashboard');
          }
        },
      ),
      _buildNavItem(
        context,
        icon: Icons.chat, // Changed from chat_bubble_outline to match mobile
        label: 'Messages',
        route: '/chatList',
        isActive: currentRoute.startsWith('/chat'),
      ),
      _buildNavItem(
        context,
        icon: Icons.calendar_today,
        label: 'Bookings',
        route: '/myBookings',
        isActive: currentRoute == '/myBookings',
      ),
      _buildNavItem(
        context,
        icon: Icons.star_outline,
        label: 'Reviews',
        route: '/reviews',
        isActive: currentRoute == '/reviews',
      ),
    ];
  }

  List<Widget> _buildProfessionalNavItems(BuildContext context) {
    return [
      _buildNavItem(
        context,
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/repairmanDashboard',
        isActive: currentRoute == '/repairmanDashboard',
      ),
      _buildNavItem(
        context,
        icon: Icons.work_outline,
        label: 'Job Requests',
        route: '/jobRequests',
        isActive: currentRoute == '/jobRequests',
      ),
      _buildNavItem(
        context,
        icon: Icons.chat_bubble_outline,
        label: 'Messages',
        route: '/chatList',
        isActive: currentRoute.startsWith('/chat'),
      ),
      _buildNavItem(
        context,
        icon: Icons.calendar_today,
        label: 'Bookings',
        route: '/professionalBookings',
        isActive: currentRoute == '/professionalBookings',
      ),
      _buildNavItem(
        context,
        icon: Icons.account_balance_wallet,
        label: 'Earnings',
        route: '/cashout',
        isActive: currentRoute == '/cashout',
      ),
      _buildNavItem(
        context,
        icon: Icons.star_outline,
        label: 'Reviews',
        route: '/reviews',
        isActive: currentRoute == '/reviews',
      ),
    ];
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap ?? () => _navigate(context, route),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, UserState userState, FirebaseAuthService authService, [bool showMenuButton = false]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth > 1600 ? 32.0 : (screenWidth < 1024 ? 16.0 : 24.0));
    
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu button for tablet (when sidebar is hidden)
          if (showMenuButton)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          // Page Title
          Expanded(
            child: Text(
              _getPageTitle(currentRoute),
              style: TextStyle(
                fontSize: screenWidth < 1024 ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Search Bar (optional, can be added)
          // Action Buttons
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          // Quick Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'help':
                  // Show help
                  break;
                case 'feedback':
                  // Show feedback
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help & Support'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'feedback',
                child: Row(
                  children: [
                    Icon(Icons.feedback_outlined),
                    SizedBox(width: 8),
                    Text('Send Feedback'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserState userState, FirebaseAuthService authService) {
    final isOwner = userState.isOwner;
    final isProfessional = userState.isServiceProfessional || userState.isRepairman;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User info header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ProfileAvatar(
                  profilePhotoUrl: userState.profilePhotoUrl,
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  fallbackIcon: Icons.person,
                  fallbackIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  userState.fullName ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userState.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Navigation items
          if (isOwner) ..._buildDrawerNavItems(context, _buildOwnerNavItems(context)),
          if (isProfessional) ..._buildDrawerNavItems(context, _buildProfessionalNavItems(context)),
          const Divider(),
          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              _navigate(context, '/settings');
            },
          ),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, authService);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerNavItems(BuildContext context, List<Widget> navItems) {
    final List<Widget> drawerItems = [];
    
    for (var item in navItems) {
      // Extract ListTile from Container wrapper
      if (item is Container) {
        final child = item.child;
        if (child is ListTile) {
          drawerItems.add(
            ListTile(
              leading: child.leading,
              title: child.title,
              onTap: child.onTap,
              selected: child.selected,
              selectedTileColor: child.selectedTileColor,
            ),
          );
        }
      } else {
        drawerItems.add(item);
      }
    }
    
    return drawerItems;
  }

  String _getPageTitle(String route) {
    switch (route) {
      case '/ownerDashboard':
      case '/ownerDashboard?tab=estimates':
        return 'Dashboard';
      case '/repairmanDashboard':
        return 'Professional Dashboard';
      case '/serviceRequest':
        return 'Create Service Request';
      case '/searchProfessionals':
        return 'Search Professionals';
      case '/myServiceRequests':
        return 'My Service Requests';
      case '/chat':
      case '/chatList':
        return 'Messages';
      case '/myBookings':
        return 'My Bookings';
      case '/professionalBookings':
        return 'Manage Bookings';
      case '/reviews':
        return 'Reviews';
      case '/cashout':
        return 'Earnings & Cashout';
      case '/settings':
        return 'Settings';
      case '/customerEditProfile':
        return 'Edit Profile';
      default:
        return 'ServicePro';
    }
  }

  void _navigate(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      // Handle routes with query parameters
      if (route.contains('?')) {
        final uri = Uri.parse(route);
        Navigator.pushNamed(context, uri.path, arguments: uri.queryParameters);
      } else {
        Navigator.pushNamed(context, route);
      }
    }
  }

  ImageProvider _buildImageProvider(String imageUrl) {
    // Use NetworkImage directly - it works on both web and mobile
    return NetworkImage(imageUrl);
  }

  void _showLogoutDialog(BuildContext context, FirebaseAuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context); // Close dialog first
                
                // Sign out from Firebase
                await authService.signOut();
                
                // Clear user state
                final userState = Provider.of<UserState>(context, listen: false);
                userState.clearUserState();
                
                // Navigate to login/homepage
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/homepage',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}


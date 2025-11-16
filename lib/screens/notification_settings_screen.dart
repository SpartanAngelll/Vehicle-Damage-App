import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_models.dart';
import '../services/comprehensive_notification_service.dart';
import '../widgets/responsive_layout.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final ComprehensiveNotificationService _notificationService = ComprehensiveNotificationService();
  
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // For now, create default preferences
      // In a real app, you'd load from Firestore
      _preferences = NotificationPreferences(
        userId: 'current_user_id', // Replace with actual user ID
        enablePushNotifications: true,
        enableEmailNotifications: true,
        enableSmsNotifications: false,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notification preferences: $e';
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    try {
      await _notificationService.updateUserNotificationPreferences(_preferences!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateTypePreference(NotificationType type, bool enabled) {
    if (_preferences == null) return;

    setState(() {
      _preferences = _preferences!.copyWith(
        typePreferences: {
          ..._preferences!.typePreferences,
          type: enabled,
        },
      );
    });
  }

  void _updatePriorityOverride(NotificationType type, NotificationPriority priority) {
    if (_preferences == null) return;

    setState(() {
      _preferences = _preferences!.copyWith(
        priorityOverrides: {
          ..._preferences!.priorityOverrides,
          type: priority,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPreferences,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_preferences == null) {
      return const Center(
        child: Text('No notification preferences found'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralSettings(context),
          const SizedBox(height: 24),
          _buildNotificationTypes(context),
          const SizedBox(height: 24),
          _buildQuietHours(context),
          const SizedBox(height: 24),
          _buildPriorityOverrides(context),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: _preferences!.enablePushNotifications,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    enablePushNotifications: value,
                  );
                });
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _preferences!.enableEmailNotifications,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    enableEmailNotifications: value,
                  );
                });
              },
            ),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive notifications via SMS'),
              value: _preferences!.enableSmsNotifications,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    enableSmsNotifications: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypes(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...NotificationType.values.map((type) {
              final isEnabled = _preferences!.typePreferences[type] ?? true;
              return SwitchListTile(
                title: Text(_getNotificationTypeTitle(type)),
                subtitle: Text(_getNotificationTypeDescription(type)),
                value: isEnabled,
                onChanged: (value) => _updateTypePreference(type, value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHours(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'During quiet hours, you will only receive urgent notifications.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Implement quiet hours configuration UI
            const Text('Quiet hours configuration coming soon...'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityOverrides(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority Overrides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Override the default priority for specific notification types.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Implement priority override UI
            const Text('Priority overrides configuration coming soon...'),
          ],
        ),
      ),
    );
  }

  String _getNotificationTypeTitle(NotificationType type) {
    switch (type) {
      case NotificationType.bookingReminder24h:
        return '24-Hour Booking Reminders';
      case NotificationType.bookingReminder1h:
        return '1-Hour Booking Reminders';
      case NotificationType.newChatMessage:
        return 'New Chat Messages';
      case NotificationType.newEstimate:
        return 'New Estimates';
      case NotificationType.newServiceRequest:
        return 'New Service Requests';
      case NotificationType.bookingStatusUpdate:
        return 'Booking Status Updates';
      case NotificationType.paymentUpdate:
        return 'Payment Updates';
      case NotificationType.systemAlert:
        return 'System Alerts';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.bookingReminder24h:
        return 'Get reminded 24 hours before your appointments';
      case NotificationType.bookingReminder1h:
        return 'Get reminded 1 hour before your appointments';
      case NotificationType.newChatMessage:
        return 'Be notified when you receive new messages';
      case NotificationType.newEstimate:
        return 'Get notified when professionals submit estimates';
      case NotificationType.newServiceRequest:
        return 'Be notified of new service requests in your categories';
      case NotificationType.bookingStatusUpdate:
        return 'Get updates on your booking status changes';
      case NotificationType.paymentUpdate:
        return 'Be notified about payment status changes';
      case NotificationType.systemAlert:
        return 'Receive important system notifications';
    }
  }
}

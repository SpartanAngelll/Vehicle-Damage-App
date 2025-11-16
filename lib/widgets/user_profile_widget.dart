import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_state.dart';
import 'profile_avatar.dart';

class UserProfileWidget extends StatelessWidget {
  final double avatarRadius;
  final bool showUsername;
  final bool showEmail;
  final bool showRole;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const UserProfileWidget({
    super.key,
    this.avatarRadius = 30,
    this.showUsername = true,
    this.showEmail = true,
    this.showRole = true,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isAuthenticated) {
          return Container(
            padding: padding,
            child: Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: avatarRadius,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not signed in',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding,
            child: Row(
              children: [
                ProfileAvatar(
                  profilePhotoUrl: userState.profilePhotoUrl,
                  radius: avatarRadius,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  fallbackIcon: Icons.person,
                  fallbackIconColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userState.fullName ?? userState.email ?? 'User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showUsername && userState.username != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@${userState.username}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      if (showEmail && userState.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          userState.email!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (showRole) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getRoleDisplayName(userState),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
      return 'Repair Professional';
    }
    return 'User';
  }
}

class CompactUserProfileWidget extends StatelessWidget {
  final double avatarRadius;
  final VoidCallback? onTap;

  const CompactUserProfileWidget({
    super.key,
    this.avatarRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        return GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(
                profilePhotoUrl: userState.profilePhotoUrl,
                radius: avatarRadius,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                fallbackIcon: Icons.person,
                fallbackIconColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userState.fullName ?? userState.username ?? 'User',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (userState.username != null && userState.fullName != null)
                    Text(
                      '@${userState.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

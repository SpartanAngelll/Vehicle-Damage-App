import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profilePhotoUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData? fallbackIcon;
  final Color? fallbackIconColor;

  const ProfileAvatar({
    super.key,
    this.profilePhotoUrl,
    this.radius = 30,
    this.backgroundColor,
    this.fallbackIcon = Icons.person,
    this.fallbackIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    final defaultFallbackIconColor = Theme.of(context).colorScheme.primary;

    // On web, use a different approach for CircleAvatar with network images
    if (kIsWeb && profilePhotoUrl != null && profilePhotoUrl!.startsWith('http')) {
      return _buildWebAvatar(context, defaultBackgroundColor, defaultFallbackIconColor);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? defaultBackgroundColor,
      backgroundImage: _getBackgroundImage(),
      child: _getChild(context, defaultFallbackIconColor),
    );
  }

  Widget _buildWebAvatar(BuildContext context, Color defaultBackgroundColor, Color defaultFallbackIconColor) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? defaultBackgroundColor,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: profilePhotoUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: backgroundColor ?? defaultBackgroundColor,
            child: Icon(
              fallbackIcon,
              size: radius,
              color: fallbackIconColor ?? defaultFallbackIconColor,
            ),
          ),
          errorWidget: (context, url, error) {
            debugPrint('❌ [ProfileAvatar] Error loading image: $error');
            debugPrint('❌ [ProfileAvatar] URL: $url');
            return Container(
              color: backgroundColor ?? defaultBackgroundColor,
              child: Icon(
                fallbackIcon,
                size: radius,
                color: fallbackIconColor ?? defaultFallbackIconColor,
              ),
            );
          },
          httpHeaders: {
            'Cache-Control': 'no-cache',
          },
          // Add retry logic for web
          maxWidthDiskCache: 200,
          maxHeightDiskCache: 200,
        ),
      ),
    );
  }

  ImageProvider? _getBackgroundImage() {
    if (profilePhotoUrl == null) return null;
    
    // Check if it's a local file path or network URL
    if (profilePhotoUrl!.startsWith('http')) {
      // Use NetworkImage directly - it works on both web and mobile
      return NetworkImage(profilePhotoUrl!);
    } else {
      // Local file path (mobile only)
      final file = File(profilePhotoUrl!);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return null;
    }
  }

  Widget? _getChild(BuildContext context, Color defaultFallbackIconColor) {
    if (profilePhotoUrl == null) {
      return Icon(
        fallbackIcon,
        size: radius,
        color: fallbackIconColor ?? defaultFallbackIconColor,
      );
    }
    
    // For local files, check if they exist
    if (!profilePhotoUrl!.startsWith('http')) {
      final file = File(profilePhotoUrl!);
      if (!file.existsSync()) {
        return Icon(
          fallbackIcon,
          size: radius,
          color: fallbackIconColor ?? defaultFallbackIconColor,
        );
      }
    }
    
    return null;
  }
}

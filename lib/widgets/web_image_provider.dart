import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Helper widget for web-compatible image loading
class WebCompatibleImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const WebCompatibleImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? _defaultErrorWidget();
    }

    // On web, use CachedNetworkImage for better CORS handling
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
          errorWidget: (context, url, error) {
            debugPrint('❌ [WebCompatibleImage] Error loading image: $error');
            debugPrint('❌ [WebCompatibleImage] URL: $url');
            return errorWidget ?? _defaultErrorWidget();
          },
          httpHeaders: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
    }

    // On mobile, use regular Image.network with error handling
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ [WebCompatibleImage] Error loading image: $error');
          return errorWidget ?? _defaultErrorWidget();
        },
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.grey),
      ),
    );
  }
}

/// Web-compatible image provider for CircleAvatar backgrounds
/// Returns NetworkImage directly - no wrapper needed
ImageProvider webCompatibleNetworkImage(String url, {Map<String, String>? headers, double scale = 1.0}) {
  return NetworkImage(url, headers: headers, scale: scale);
}


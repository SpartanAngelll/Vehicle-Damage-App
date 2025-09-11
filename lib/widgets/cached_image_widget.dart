import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../services/image_cache_service.dart';

class CachedImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableCaching;
  final bool showLoadingIndicator;

  const CachedImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableCaching = true,
    this.showLoadingIndicator = true,
  });

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  File? _cachedFile;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null && widget.enableCaching) {
      _loadCachedImage();
    }
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      if (widget.imageUrl != null && widget.enableCaching) {
        _loadCachedImage();
      } else {
        if (mounted) {
          setState(() {
            _cachedFile = null;
            _hasError = false;
          });
        }
      }
    }
  }

  Future<void> _loadCachedImage() async {
    if (widget.imageUrl == null) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      // Check if image is already cached
      final cachedFile = await ImageCacheService.getCachedImage(widget.imageUrl!);
      
      if (cachedFile != null && await cachedFile.exists()) {
        if (mounted) {
          setState(() {
            _cachedFile = cachedFile;
            _isLoading = false;
          });
        }
        return;
      }

      // If not cached, download and cache the image with timeout
      final response = await http.get(
        Uri.parse(widget.imageUrl!),
        headers: {
          'User-Agent': 'VehicleDamageApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;
        final cachedFile = await ImageCacheService.cacheImageFromUrl(
          widget.imageUrl!,
          imageData,
        );
        
        if (cachedFile != null) {
          if (mounted) {
            setState(() {
              _cachedFile = cachedFile;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [CachedImageWidget] Error loading cached image: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null) {
      return _buildErrorWidget();
    }

    // If we have a cached file, use it
    if (_cachedFile != null && _cachedFile!.existsSync()) {
      return _buildCachedImage();
    }

    // If caching is disabled, use CachedNetworkImage directly
    if (!widget.enableCaching) {
      return _buildNetworkImage();
    }

    // Show loading or error state
    if (_isLoading && widget.showLoadingIndicator) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    // Fallback to network image
    return _buildNetworkImage();
  }

  Widget _buildCachedImage() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.file(
          _cachedFile!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [CachedImageWidget] Error displaying cached image: $error');
            return _buildErrorWidget();
          },
        ),
      ),
    );
  }

  Widget _buildNetworkImage() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: (context, url) => _buildLoadingWidget(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[400],
        size: widget.width != null && widget.height != null
            ? (widget.width! < widget.height! ? widget.width! * 0.3 : widget.height! * 0.3)
            : 24,
      ),
    );
  }
}

// Specialized widgets for different use cases
class CachedProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const CachedProfileImage({
    super.key,
    this.imageUrl,
    this.size = 80,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
        ),
        child: Icon(
          Icons.person,
          color: Colors.grey[400],
          size: size * 0.5,
        ),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
        ),
        child: Icon(
          Icons.person,
          color: Colors.grey[400],
          size: size * 0.5,
        ),
      ),
    );
  }
}

class CachedCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final BorderRadius? borderRadius;

  const CachedCoverImage({
    super.key,
    this.imageUrl,
    this.height = 200,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      placeholder: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.image,
          color: Colors.grey[400],
          size: 48,
        ),
      ),
      errorWidget: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
          size: 48,
        ),
      ),
    );
  }
}

class CachedWorkShowcaseImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const CachedWorkShowcaseImage({
    super.key,
    this.imageUrl,
    this.width = 120,
    this.height = 120,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CachedImageWidget(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        placeholder: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.photo,
            color: Colors.grey[400],
            size: 32,
          ),
        ),
        errorWidget: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
            size: 32,
          ),
        ),
      ),
    );
  }
}

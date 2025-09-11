import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

class ExpandablePhotoViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? title;

  const ExpandablePhotoViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title ?? 'Photos',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${initialIndex + 1} of ${imageUrls.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child:               _buildImageWidget(imageUrls[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    // Validate URL
    if (imageUrl.isEmpty || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              'Invalid image URL',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) {
        print('❌ [ExpandablePhotoViewer] Error loading image: $error');
        print('❌ [ExpandablePhotoViewer] URL: $url');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PhotoThumbnail extends StatelessWidget {
  final String imageUrl;
  final List<String> allImageUrls;
  final int index;
  final double width;
  final double height;
  final String? title;

  const PhotoThumbnail({
    super.key,
    required this.imageUrl,
    required this.allImageUrls,
    required this.index,
    this.width = 100,
    this.height = 100,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExpandablePhotoViewer(
              imageUrls: allImageUrls,
              initialIndex: index,
              title: title,
            ),
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              _buildThumbnailImage(imageUrl, width, height),
              // Add a subtle overlay to indicate it's clickable
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(String imageUrl, double width, double height) {
    // Validate URL
    if (imageUrl.isEmpty || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(height: 4),
            Text(
              'Invalid URL',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, color: Colors.grey, size: 32),
            const SizedBox(height: 4),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      errorWidget: (context, url, error) {
        print('❌ [PhotoThumbnail] Error loading image: $error');
        print('❌ [PhotoThumbnail] URL: $url');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(height: 4),
              Text(
                'Failed to load',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

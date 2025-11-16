import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_service.dart';
import '../services/platform_image_service.dart';
import '../services/storage_service.dart';
import '../models/image_quality.dart';

class ImageUploadWidget extends StatefulWidget {
  final Function(List<String>) onImagesUploaded;
  final Function(List<File>) onImagesSelected;
  final int maxImages;
  final String title;
  final String subtitle;
  final bool showQualitySelector;
  final ImageQuality defaultQuality;

  const ImageUploadWidget({
    super.key,
    required this.onImagesUploaded,
    required this.onImagesSelected,
    this.maxImages = 5,
    this.title = 'Upload Images',
    this.subtitle = 'Select images from gallery or take photos',
    this.showQualitySelector = true,
    this.defaultQuality = ImageQuality.medium,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final List<File> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = []; // For web
  final List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  ImageQuality _selectedQuality = ImageQuality.medium;

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.defaultQuality;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.subtitle.isNotEmpty)
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.showQualitySelector) _buildQualitySelector(),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Image selection buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length >= widget.maxImages ? null : _pickImagesFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length >= widget.maxImages ? null : _pickImagesFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Selected images preview
        if (_selectedImages.isNotEmpty || _uploadedImageUrls.isNotEmpty) ...[
          Text(
            'Images (${_selectedImages.length + _uploadedImageUrls.length}/${widget.maxImages})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildImageGrid(),
          const SizedBox(height: 16),
        ],
        
        // Upload button
        if (_selectedImages.isNotEmpty && !_isUploading)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadImages,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload Images'),
            ),
          ),
        
        // Upload progress
        if (_isUploading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 8),
          Text(
            'Uploading... ${(_uploadProgress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        
        // Error message
        if (_uploadError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _uploadError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _uploadError = null),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQualitySelector() {
    return PopupMenuButton<ImageQuality>(
      initialValue: _selectedQuality,
      onSelected: (ImageQuality quality) {
        setState(() {
          _selectedQuality = quality;
        });
      },
      itemBuilder: (BuildContext context) => ImageQuality.values.map((ImageQuality quality) {
        return PopupMenuItem<ImageQuality>(
          value: quality,
          child: Row(
            children: [
              Icon(
                quality == _selectedQuality ? Icons.check : Icons.radio_button_unchecked,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(quality.displayName),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedQuality.displayName),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final totalImages = _selectedImages.length + _uploadedImageUrls.length;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalImages,
      itemBuilder: (context, index) {
        // Determine if this is a selected image or uploaded image
        final isSelectedImage = index < _selectedImages.length;
        final imageIndex = isSelectedImage ? index : index - _selectedImages.length;
        
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isSelectedImage
                  ? Image.file(
                      _selectedImages[imageIndex],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : (kIsWeb 
                      ? CachedNetworkImage(
                          imageUrl: _uploadedImageUrls[imageIndex],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            );
                          },
                        )
                      : Image.network(
                          _uploadedImageUrls[imageIndex],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            );
                          },
                        )),
            ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => isSelectedImage 
                      ? _removeImage(imageIndex)
                      : _removeUploadedImage(imageIndex),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ),
            ),
            // Upload status indicator
            if (isSelectedImage)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ImageService.getFileSizeString(_selectedImages[imageIndex]),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              // Uploaded indicator
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      if (kIsWeb) {
        // On web, pick images one at a time using PlatformImageService
        final remainingSlots = widget.maxImages - (_selectedImages.length + _selectedImageBytes.length);
        if (remainingSlots <= 0) {
          _showError('Maximum ${widget.maxImages} images allowed');
          return;
        }
        
        // Pick one image at a time on web
        final bytes = await PlatformImageService.pickImage(
          source: ImageSource.gallery,
          quality: _selectedQuality,
        );
        
        if (bytes != null) {
          setState(() {
            _selectedImageBytes.add(bytes);
          });
          // Convert to File-like structure for compatibility
          // On web, we'll handle upload differently
          await _uploadWebImage(bytes);
        }
      } else {
        // On mobile, use the existing File-based approach
        final images = await ImageService.pickMultipleImagesFromGallery(
          quality: _selectedQuality,
          maxImages: widget.maxImages - _selectedImages.length,
        );
        
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
          widget.onImagesSelected(_selectedImages);
        }
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _pickImagesFromCamera() async {
    try {
      if (kIsWeb) {
        // On web, camera access is limited - pick one image at a time
        final remainingSlots = widget.maxImages - (_selectedImages.length + _selectedImageBytes.length);
        if (remainingSlots <= 0) {
          _showError('Maximum ${widget.maxImages} images allowed');
          return;
        }
        
        final bytes = await PlatformImageService.pickImage(
          source: ImageSource.camera,
          quality: _selectedQuality,
        );
        
        if (bytes != null) {
          setState(() {
            _selectedImageBytes.add(bytes);
          });
          await _uploadWebImage(bytes);
        }
      } else {
        // On mobile, use the existing File-based approach
        final images = await ImageService.pickMultipleImagesFromCamera(
          quality: _selectedQuality,
          maxImages: widget.maxImages - _selectedImages.length,
        );
        
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
          widget.onImagesSelected(_selectedImages);
        }
      }
    } catch (e) {
      _showError('Failed to take photos: $e');
    }
  }

  Future<void> _uploadWebImage(Uint8List imageBytes) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadError = null;
      });

      // Upload image bytes directly to Firebase Storage
      final imageUrl = await StorageService.uploadImageBytes(
        imageBytes: imageBytes,
        path: 'service_requests/temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      setState(() {
        _uploadedImageUrls.add(imageUrl);
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      widget.onImagesUploaded(_uploadedImageUrls);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Upload failed: $e';
      });
      _showError('Failed to upload image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesSelected(_selectedImages);
  }

  void _removeUploadedImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
    widget.onImagesUploaded(_uploadedImageUrls);
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
    });

    try {
      // Upload images to Firebase Storage
      final imageUrls = await StorageService.uploadServiceRequestImages(
        requestId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        images: _selectedImages,
        customerId: 'temp_customer', // This will be updated when the actual request is created
      );
      
      // Store uploaded URLs and clear selected images
      setState(() {
        _uploadedImageUrls.addAll(imageUrls);
        _selectedImages.clear();
        _isUploading = false;
        _uploadProgress = 1.0;
      });
      
      // Notify parent of changes
      widget.onImagesUploaded(_uploadedImageUrls);
      widget.onImagesSelected(_selectedImages);
      
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Upload failed: $e';
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}


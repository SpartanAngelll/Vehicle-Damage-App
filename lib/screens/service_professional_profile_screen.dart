import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/service_professional.dart';
import '../models/user_state.dart';
import '../services/firebase_firestore_service.dart';
import '../services/storage_service.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/map_picker_widget.dart';
import '../widgets/embedded_map_widget.dart';
import '../widgets/cached_image_widget.dart';
import '../screens/reviews_screen.dart';

class ServiceProfessionalProfileScreen extends StatefulWidget {
  final String? professionalId; // If null, shows current user's profile
  
  const ServiceProfessionalProfileScreen({
    super.key,
    this.professionalId,
  });

  @override
  State<ServiceProfessionalProfileScreen> createState() => _ServiceProfessionalProfileScreenState();
}

class _ServiceProfessionalProfileScreenState extends State<ServiceProfessionalProfileScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  
  ServiceProfessional? _professional;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isCurrentUser = false;
  
  // Form controllers for editing
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  
  // Cover photo and work showcase
  String? _coverPhotoUrl;
  List<String> _workShowcaseImages = [];
  final PageController _workShowcaseController = PageController();
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _websiteController.dispose();
    _workShowcaseController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final userState = Provider.of<UserState>(context, listen: false);
      final currentUserId = userState.userId ?? userState.currentUser?.uid;
      
      print('🔍 [ProfileScreen] Loading profile for user: $currentUserId');
      print('🔍 [ProfileScreen] Professional ID from widget: ${widget.professionalId}');
      print('🔍 [ProfileScreen] UserState.userId: ${userState.userId}');
      print('🔍 [ProfileScreen] UserState.currentUser?.uid: ${userState.currentUser?.uid}');
      print('🔍 [ProfileScreen] UserState.isAuthenticated: ${userState.isAuthenticated}');
      print('🔍 [ProfileScreen] UserState.role: ${userState.role}');
      
      if (widget.professionalId != null) {
        // Loading another professional's profile
        _isCurrentUser = widget.professionalId == currentUserId;
        print('🔍 [ProfileScreen] Loading another professional\'s profile: ${widget.professionalId}');
        _professional = await _firestoreService.getServiceProfessional(widget.professionalId!);
      } else if (currentUserId != null) {
        // Loading current user's profile
        _isCurrentUser = true;
        print('🔍 [ProfileScreen] Loading current user\'s profile: $currentUserId');
        _professional = await _firestoreService.getServiceProfessional(currentUserId);
      } else {
        print('❌ [ProfileScreen] No user ID available for profile loading');
        throw Exception('No user ID available for profile loading');
      }
      
      print('🔍 [ProfileScreen] Profile loaded: ${_professional != null ? 'SUCCESS' : 'FAILED'}');
      if (_professional != null) {
        print('🔍 [ProfileScreen] Professional data: fullName="${_professional!.fullName}", email="${_professional!.email}", Role: ${_professional!.categoryIds}');
        _bioController.text = _professional!.bio ?? '';
        _locationController.text = _professional!.serviceAreas.isNotEmpty 
            ? _professional!.serviceAreas.first 
            : '';
        _businessNameController.text = _professional!.businessName ?? '';
        _businessAddressController.text = _professional!.businessAddress ?? '';
        _businessPhoneController.text = _professional!.businessPhone ?? '';
        _websiteController.text = _professional!.website ?? '';
        
        // Load cover photo and work showcase images in parallel
        await Future.wait([
          _loadCoverPhoto(),
          _loadWorkShowcaseImages(),
        ]);
      } else {
        print('❌ [ProfileScreen] No professional profile found for user: $currentUserId');
        throw Exception('No professional profile found for user: $currentUserId');
      }
      
    } catch (e) {
      print('❌ [ProfileScreen] Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadProfile(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCoverPhoto() async {
    if (_professional == null) return;
    
    try {
      // Load cover photo URL from the professional's data
      _coverPhotoUrl = _professional!.coverPhotoUrl;
      print('🔍 Loaded cover photo URL: $_coverPhotoUrl');
    } catch (e) {
      print('❌ Error loading cover photo: $e');
    }
  }

  Future<void> _loadWorkShowcaseImages() async {
    if (_professional == null) return;
    
    try {
      // Load work showcase images from the professional's data
      _workShowcaseImages = List<String>.from(_professional!.workShowcaseImages);
      print('🔍 Loaded work showcase images: ${_workShowcaseImages.length} images');
    } catch (e) {
      print('❌ Error loading work showcase images: $e');
    }
  }
  
  Future<void> _updateProfile() async {
    if (_professional == null) return;
    
    try {
      final updatedProfessional = _professional!.copyWith(
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        serviceAreas: _locationController.text.trim().isEmpty 
            ? [] 
            : [_locationController.text.trim()],
        businessName: _businessNameController.text.trim().isEmpty ? null : _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isEmpty ? null : _businessAddressController.text.trim(),
        businessPhone: _businessPhoneController.text.trim().isEmpty ? null : _businessPhoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        // Preserve existing location data when updating profile
        latitude: _professional!.latitude,
        longitude: _professional!.longitude,
        address: _professional!.address,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateServiceProfessional(updatedProfessional);
      
      setState(() {
        _professional = updatedProfessional;
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }
  
  Future<void> _uploadProfilePhoto() async {
    try {
      // Show source selection dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Photo Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      
      if (source != null) {
        final imageFile = await ImageService.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 90,
        );
        
        if (imageFile != null) {
          // Show cropping dialog
          final croppedImage = await _showCroppingDialog(imageFile);
          
          if (croppedImage != null) {
            final photoUrl = await StorageService.uploadUserProfileImage(
              userId: _professional!.userId,
              imageFile: croppedImage,
            );
            
            if (photoUrl != null) {
                    final updatedProfessional = _professional!.copyWith(
        profilePhotoUrl: photoUrl,
        // Preserve existing location data
        latitude: _professional!.latitude,
        longitude: _professional!.longitude,
        address: _professional!.address,
        updatedAt: DateTime.now(),
      );
              
              await _firestoreService.updateServiceProfessional(updatedProfessional);
              
              setState(() {
                _professional = updatedProfessional;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile photo updated!')),
              );
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    }
  }
  
  Future<File?> _showCroppingDialog(File imageFile) async {
    return await showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Your Photo'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Position your face or logo in the center of the frame',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, imageFile),
            child: const Text('Use This Photo'),
          ),
        ],
      ),
    );
  }
  
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'Year' : 'Years'} Ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'Month' : 'Months'} Ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'Day' : 'Days'} Ago';
    } else {
      return 'Today';
    }
  }
  
  Widget _buildStarRating(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (index) => const Icon(
          Icons.star,
          color: Colors.amber,
          size: 20,
        )),
        if (hasHalfStar) const Icon(
          Icons.star_half,
          color: Colors.amber,
          size: 20,
        ),
        ...List.generate(emptyStars, (index) => const Icon(
          Icons.star_border,
          color: Colors.amber,
          size: 20,
        )),
        const SizedBox(width: 8),
        Text(
          '${rating.toStringAsFixed(1)}/5',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${_professional?.totalReviews ?? 0} reviews)',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Cover photo upload method
  Future<void> _uploadCoverPhoto() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Cover Photo Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final imageFile = await ImageService.pickImage(source: source);
        if (imageFile != null) {
          // Show cropping dialog for cover photo
          final croppedFile = await _showCoverPhotoCroppingDialog(imageFile);
          if (croppedFile != null) {
            // Upload to Firebase Storage
            final photoUrl = await StorageService.uploadCoverPhoto(
              professionalId: _professional!.id,
              imageFile: croppedFile,
            );

            if (photoUrl != null) {
              // Update cover photo URL in Firestore
                    final updatedProfessional = _professional!.copyWith(
        coverPhotoUrl: photoUrl,
        // Preserve existing location data
        latitude: _professional!.latitude,
        longitude: _professional!.longitude,
        address: _professional!.address,
        updatedAt: DateTime.now(),
      );
              
              await _firestoreService.updateServiceProfessional(updatedProfessional);
              
              setState(() {
                _professional = updatedProfessional;
                _coverPhotoUrl = photoUrl;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cover photo updated!')),
              );
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload cover photo: $e')),
      );
    }
  }

  // Work showcase image upload method
  Future<void> _uploadWorkShowcaseImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Work Showcase Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final imageFile = await ImageService.pickImage(source: source);
        if (imageFile != null) {
          // Show cropping dialog for work showcase image
          final croppedFile = await _showWorkShowcaseCroppingDialog(imageFile);
          if (croppedFile != null) {
            // Upload to Firebase Storage
            final photoUrl = await StorageService.uploadWorkShowcaseImage(
              professionalId: _professional!.id,
              imageFile: croppedFile,
            );

            if (photoUrl != null) {
              // Update work showcase images in Firestore
              final updatedImages = List<String>.from(_workShowcaseImages)..add(photoUrl);
              final updatedProfessional = _professional!.copyWith(
                workShowcaseImages: updatedImages,
                updatedAt: DateTime.now(),
              );
              
              await _firestoreService.updateServiceProfessional(updatedProfessional);
              
              setState(() {
                _professional = updatedProfessional;
                _workShowcaseImages = updatedImages;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Work showcase image added!')),
              );
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload work showcase image: $e')),
      );
    }
  }

  // Cover photo cropping dialog
  Future<File?> _showCoverPhotoCroppingDialog(File imageFile) async {
    return await showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Cover Photo'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Position your cover photo for best display',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, imageFile),
            child: const Text('Use This Photo'),
          ),
        ],
      ),
    );
  }

  // Work showcase cropping dialog
  Future<File?> _showWorkShowcaseCroppingDialog(File imageFile) async {
    return await showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Work Showcase Image'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Crop your work showcase image',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, imageFile),
            child: const Text('Use This Photo'),
          ),
        ],
      ),
    );
  }

  // Show work showcase image in full screen
  void _showWorkShowcaseImage(String imageUrl, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (_isCurrentUser)
              Positioned(
                bottom: 40,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () => _removeWorkShowcaseImage(index),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Remove work showcase image
  Future<void> _removeWorkShowcaseImage(int index) async {
    try {
      final updatedImages = List<String>.from(_workShowcaseImages)..removeAt(index);
      final updatedProfessional = _professional!.copyWith(
        workShowcaseImages: updatedImages,
        // Preserve existing location data
        latitude: _professional!.latitude,
        longitude: _professional!.longitude,
        address: _professional!.address,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateServiceProfessional(updatedProfessional);
      
      setState(() {
        _professional = updatedProfessional;
        _workShowcaseImages = updatedImages;
      });
      
      Navigator.pop(context); // Close the full screen dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work showcase image removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove image: $e')),
      );
    }
  }

  // Handle location selection from map picker
  Future<void> _onLocationSelected(double latitude, double longitude, String address) async {
    try {
      final updatedProfessional = _professional!.copyWith(
        latitude: latitude,
        longitude: longitude,
        address: address,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateServiceProfessional(updatedProfessional);
      
      setState(() {
        _professional = updatedProfessional;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update location: $e')),
      );
    }
  }

  // Open map picker
  void _openMapPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerWidget(
          initialLatitude: _professional?.latitude,
          initialLongitude: _professional?.longitude,
          initialAddress: _professional?.address,
          onLocationSelected: _onLocationSelected,
          isReadOnly: !_isCurrentUser,
        ),
      ),
    );
  }

  // Show add dialog for certifications and specialties
  void _showAddDialog(String title, String hint, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hint,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter $title',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context);
                onAdd(value);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Add certification
  Future<void> _addCertification(String certification) async {
    if (_professional == null) return;
    
    try {
      print('🔍 [Profile] Adding certification: $certification');
      print('🔍 [Profile] Current certifications: ${_professional!.certifications}');
      
      final updatedCertifications = List<String>.from(_professional!.certifications);
      if (!updatedCertifications.contains(certification)) {
        updatedCertifications.add(certification);
        print('🔍 [Profile] Updated certifications: $updatedCertifications');
        
        final updatedProfessional = _professional!.copyWith(
          certifications: updatedCertifications,
          updatedAt: DateTime.now(),
        );
        
        print('🔍 [Profile] Calling updateServiceProfessional with certifications: ${updatedProfessional.certifications}');
        await _firestoreService.updateServiceProfessional(updatedProfessional);
        
        setState(() {
          _professional = updatedProfessional;
        });
        
        print('🔍 [Profile] Certification added successfully, new state: ${_professional!.certifications}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certification "$certification" added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certification "$certification" already exists!')),
        );
      }
    } catch (e) {
      print('❌ [Profile] Error adding certification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add certification: $e')),
      );
    }
  }

  // Remove certification
  Future<void> _removeCertification(String certification) async {
    if (_professional == null) return;
    
    try {
      print('🔍 [Profile] Removing certification: $certification');
      print('🔍 [Profile] Current certifications: ${_professional!.certifications}');
      
      final updatedCertifications = List<String>.from(_professional!.certifications);
      updatedCertifications.remove(certification);
      print('🔍 [Profile] Updated certifications: $updatedCertifications');
      
      final updatedProfessional = _professional!.copyWith(
        certifications: updatedCertifications,
        updatedAt: DateTime.now(),
      );
      
      print('🔍 [Profile] Calling updateServiceProfessional with certifications: ${updatedProfessional.certifications}');
      await _firestoreService.updateServiceProfessional(updatedProfessional);
      
      setState(() {
        _professional = updatedProfessional;
      });
      
      print('🔍 [Profile] Certification removed successfully, new state: ${_professional!.certifications}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certification "$certification" removed successfully!')),
      );
    } catch (e) {
      print('❌ [Profile] Error removing certification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove certification: $e')),
      );
    }
  }

  // Add specialty
  Future<void> _addSpecialty(String specialty) async {
    if (_professional == null) return;
    
    try {
      print('🔍 [Profile] Adding specialty: $specialty');
      print('🔍 [Profile] Current specialties: ${_professional!.specializations}');
      
      final updatedSpecializations = List<String>.from(_professional!.specializations);
      if (!updatedSpecializations.contains(specialty)) {
        updatedSpecializations.add(specialty);
        print('🔍 [Profile] Updated specialties: $updatedSpecializations');
        
        final updatedProfessional = _professional!.copyWith(
          specializations: updatedSpecializations,
          updatedAt: DateTime.now(),
        );
        
        print('🔍 [Profile] Calling updateServiceProfessional with specializations: ${updatedProfessional.specializations}');
        await _firestoreService.updateServiceProfessional(updatedProfessional);
        
        setState(() {
          _professional = updatedProfessional;
        });
        
        print('🔍 [Profile] Specialty added successfully, new state: ${_professional!.specializations}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Specialty "$specialty" added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Specialty "$specialty" already exists!')),
        );
      }
    } catch (e) {
      print('❌ [Profile] Error adding specialty: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add specialty: $e')),
      );
    }
  }

  // Remove specialty
  Future<void> _removeSpecialty(String specialty) async {
    if (_professional == null) return;
    
    try {
      print('🔍 [Profile] Removing specialty: $specialty');
      print('🔍 [Profile] Current specialties: ${_professional!.specializations}');
      
      final updatedSpecializations = List<String>.from(_professional!.specializations);
      updatedSpecializations.remove(specialty);
      print('🔍 [Profile] Updated specialties: $updatedSpecializations');
      
      final updatedProfessional = _professional!.copyWith(
        specializations: updatedSpecializations,
        updatedAt: DateTime.now(),
      );
      
      print('🔍 [Profile] Calling updateServiceProfessional with specializations: ${updatedProfessional.specializations}');
      await _firestoreService.updateServiceProfessional(updatedProfessional);
      
      setState(() {
        _professional = updatedProfessional;
      });
      
      print('🔍 [Profile] Specialty removed successfully, new state: ${_professional!.specializations}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Specialty "$specialty" removed successfully!')),
      );
    } catch (e) {
      print('❌ [Profile] Error removing specialty: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove specialty: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_professional == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile not found')),
      );
    }
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: _coverPhotoUrl != null 
                    ? null 
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                ),
                child: Stack(
                  children: [
                    // Cover photo background
                    if (_coverPhotoUrl != null)
                      Positioned.fill(
                        child: CachedCoverImage(
                          imageUrl: _coverPhotoUrl!,
                          height: double.infinity,
                        ),
                      ),
                    // Dark overlay for better text readability
                    if (_coverPhotoUrl != null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Background pattern (subtle)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ),
                    // Name and Location - Positioned at top
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _professional!.fullName.isNotEmpty 
                                    ? _professional!.fullName 
                                    : _professional!.email.split('@').first,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _professional!.serviceAreas.isNotEmpty
                                    ? _professional!.serviceAreas.first
                                    : 'Location not set',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Profile Photo - Positioned at bottom
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _isCurrentUser ? _uploadProfilePhoto : null,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                CachedProfileImage(
                                  imageUrl: _professional!.profilePhotoUrl,
                                  size: 80,
                                ),
                                // Upload overlay indicator
                                if (_isCurrentUser)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Upload instruction text
                    if (_isCurrentUser)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Tap photo to upload',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              if (_isCurrentUser) ...[
                IconButton(
                  icon: const Icon(Icons.photo_camera),
                  onPressed: _uploadCoverPhoto,
                  tooltip: 'Upload Cover Photo',
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (_isEditing) {
                      _updateProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                ),
              ],
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stats Row
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        _professional!.jobsCompleted.toString(),
                        'Jobs\nCompleted',
                      ),
                      _buildStatItem(
                        _professional!.averageRating.toStringAsFixed(1),
                        'Average\nRating',
                      ),
                      _buildStatItem(
                        _getTimeAgo(_professional!.createdAt),
                        'Years\nActive',
                      ),
                    ],
                  ),
                ),
                
                // Profile Sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildProfileSection(
                        'Joined',
                        _getTimeAgo(_professional!.createdAt),
                        Icons.calendar_today,
                      ),
                      _buildProfileSection(
                        'Bio',
                        _professional!.bio ?? 'No bio added yet',
                        Icons.info,
                        isEditable: _isEditing && _isCurrentUser,
                        controller: _bioController,
                      ),
                      _buildProfileSection(
                        'Location',
                        _professional!.serviceAreas.isNotEmpty
                            ? _professional!.serviceAreas.first
                            : 'Location not set',
                        Icons.location_on,
                        isEditable: _isEditing && _isCurrentUser,
                        controller: _locationController,
                      ),
                      _buildProfileSection(
                        'Business Name',
                        _professional!.businessName ?? 'No business name added',
                        Icons.business,
                        isEditable: _isEditing && _isCurrentUser,
                        controller: _businessNameController,
                      ),
                      _buildProfileSection(
                        'Business Address',
                        _professional!.businessAddress ?? 'No business address added',
                        Icons.location_city,
                        isEditable: _isEditing && _isCurrentUser,
                        controller: _businessAddressController,
                      ),
                      _buildProfileSection(
                        'Business Phone',
                        _professional!.businessPhone ?? 'No business phone added',
                        Icons.phone,
                        isEditable: _isEditing && _isCurrentUser,
                        controller: _businessPhoneController,
                      ),
                      _buildProfileSection(
                        'Website',
                        _professional!.website ?? 'No website added',
                        Icons.web,
                        isEditable: _isEditing && _isCurrentUser,
                        controller: _websiteController,
                      ),
                      _buildProfileSection(
                        'Ratings',
                        '',
                        Icons.star,
                        customWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStarRating(_professional!.averageRating),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewsScreen(
                                      professionalId: _professional!.id,
                                      professionalName: _professional!.fullName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.rate_review, size: 16),
                              label: const Text('View Reviews'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Certifications & Specialties Section
                if (_professional!.certifications.isNotEmpty || _professional!.specializations.isNotEmpty || (_isCurrentUser && _isEditing)) ...[
                  const SizedBox(height: 20),
                  _buildCertificationsAndSpecialtiesSection(),
                ],
                
                // Work Showcase Section
                const SizedBox(height: 20),
                _buildWorkShowcaseSection(),
                
                // Location Section
                const SizedBox(height: 20),
                _buildLocationSection(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.2,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileSection(
    String title,
    String content,
    IconData icon, {
    bool isEditable = false,
    TextEditingController? controller,
    Widget? customWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        subtitle: customWidget ?? (isEditable && controller != null
            ? TextField(
                controller: controller,
                maxLines: title == 'Bio' ? 3 : 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your ${title.toLowerCase()}',
                ),
              )
            : Text(
                content,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              )),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }

  // Build certifications and specialties section
  Widget _buildCertificationsAndSpecialtiesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Certifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (_isCurrentUser && _isEditing)
                TextButton.icon(
                  onPressed: () => _showAddDialog('Certification', 'Enter a new certification', _addCertification),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_professional!.certifications.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _professional!.certifications.map((cert) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cert,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      if (_isCurrentUser && _isEditing) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeCertification(cert),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else if (_isCurrentUser && _isEditing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'No certifications added yet. Tap Add to add some.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          
          // Specialties
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Specialties',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (_isCurrentUser && _isEditing)
                TextButton.icon(
                  onPressed: () => _showAddDialog('Specialty', 'Enter a new specialty', _addSpecialty),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_professional!.specializations.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _professional!.specializations.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        specialty,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      if (_isCurrentUser && _isEditing) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeSpecialty(specialty),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else if (_isCurrentUser && _isEditing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'No specialties added yet. Tap Add to add some.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build work showcase section
  Widget _buildWorkShowcaseSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Work Showcase',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (_isCurrentUser)
                TextButton.icon(
                  onPressed: _uploadWorkShowcaseImage,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_workShowcaseImages.isEmpty)
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCurrentUser 
                        ? 'Add photos of your work to showcase your skills'
                        : 'No work photos available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _workShowcaseController,
                itemCount: _workShowcaseImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _showWorkShowcaseImage(_workShowcaseImages[index], index),
                      child: CachedWorkShowcaseImage(
                        imageUrl: _workShowcaseImages[index],
                        width: double.infinity,
                        height: 120,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Page indicators
          if (_workShowcaseImages.length > 1) ...[
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_workShowcaseImages.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 ? AppTheme.primaryColor : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build location section
  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (_isCurrentUser)
                TextButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.edit_location, size: 18),
                  label: Text(_professional?.latitude != null ? 'Update Location' : 'Set Location'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Embedded Map Widget
          Builder(
            builder: (context) {
              print('🗺️ [ProfileScreen] Passing coordinates to EmbeddedMapWidget:');
              print('   - Latitude: ${_professional?.latitude}');
              print('   - Longitude: ${_professional?.longitude}');
              print('   - Address: ${_professional?.address}');
              
              return EmbeddedMapWidget(
                latitude: _professional?.latitude,
                longitude: _professional?.longitude,
                address: _professional?.address,
                isReadOnly: !_isCurrentUser,
                height: 200,
                onTap: _isCurrentUser ? _openMapPicker : null,
              );
            },
          ),
          

        ],
      ),
    );
  }
}

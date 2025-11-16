import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_state.dart';
import '../services/firebase_firestore_service.dart';
import '../services/storage_service.dart';
import '../services/profile_auto_fill_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';

class CustomerEditProfileScreen extends StatefulWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  State<CustomerEditProfileScreen> createState() => _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState extends State<CustomerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web platform
  String? _profilePhotoUrl;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  String? _usernameError;
  String? _originalUsername;
  Timer? _usernameCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _usernameCheckTimer?.cancel();
    super.dispose();
  }

  void _loadExistingProfile() async {
    final userState = context.read<UserState>();
    
    // Get auto-fill data and suggestions
    final suggestions = ProfileAutoFillService.getSuggestedValues(userState);
    
    // Auto-fill form controllers with existing data
    final controllers = {
      'fullName': _fullNameController,
      'username': _usernameController,
      'bio': _bioController,
    };
    
    ProfileAutoFillService.populateFormControllers(
      controllers: controllers,
      userState: userState,
      suggestions: suggestions,
    );
    
    // Set original username for validation
    if (userState.username != null) {
      _originalUsername = userState.username!;
    }
    
    // Load profile photo with local storage priority
    final displayPhoto = await userState.getDisplayProfilePhoto();
    if (displayPhoto != null) {
      _profilePhotoUrl = displayPhoto;
    }
    
    // Show suggestions if any new ones are available
    if (suggestions.isNotEmpty) {
      _showAutoFillSuggestions(suggestions);
    }
  }
  
  void _showAutoFillSuggestions(Map<String, dynamic> suggestions) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile Suggestions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We\'ve found some suggestions to improve your profile:'),
                const SizedBox(height: 16),
                if (suggestions['suggestedFullName'] != null)
                  Text('• Suggested name: ${suggestions['suggestedFullName']}'),
                if (suggestions['suggestedUsername'] != null)
                  Text('• Suggested username: ${suggestions['suggestedUsername']}'),
                const SizedBox(height: 16),
                const Text('You can edit these suggestions in the form below.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // On web, read bytes directly from XFile
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
            _profilePhotoUrl = null; // Clear existing URL when new image is selected
          });
        } else {
          // On mobile, use File
          final imageFile = File(image.path);
          setState(() {
            _selectedImage = imageFile;
            _selectedImageBytes = null;
            _profilePhotoUrl = imageFile.path; // Set to local file path for immediate display
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // On web, read bytes directly from XFile
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
            _profilePhotoUrl = null; // Clear existing URL when new image is selected
          });
        } else {
          // On mobile, use File
          final imageFile = File(image.path);
          setState(() {
            _selectedImage = imageFile;
            _selectedImageBytes = null;
            _profilePhotoUrl = imageFile.path; // Set to local file path for immediate display
          });
        }
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  void _debouncedUsernameCheck(String username) {
    // Clear any existing error when user starts typing
    if (_usernameError != null && _usernameError!.contains('Unable to check')) {
      setState(() {
        _usernameError = null;
      });
    }
    
    _usernameCheckTimer?.cancel();
    _usernameCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.trim().isEmpty || username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = null;
      });
      return;
    }

    // If username hasn't changed, it's available
    if (username.trim() == _originalUsername) {
      setState(() {
        _isUsernameAvailable = true;
        _usernameError = null;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final firestoreService = FirebaseFirestoreService();
      final isTaken = await firestoreService.isUsernameTaken(username.trim());
      
      if (mounted) {
        setState(() {
          _isUsernameAvailable = !isTaken;
          _usernameError = isTaken ? 'Username is already taken' : null;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameError = 'Unable to check username. Please try again.';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userState = context.read<UserState>();
      final firestoreService = FirebaseFirestoreService();
      
      String? finalProfilePhotoUrl = _profilePhotoUrl;

      // Handle profile picture - save locally first, then upload to Firebase
      if (kIsWeb && _selectedImageBytes != null) {
        // On web, use bytes-based upload
        finalProfilePhotoUrl = await StorageService.uploadUserProfileImageFromBytes(
          userId: userState.userId!,
          imageBytes: _selectedImageBytes!,
        );
      } else if (!kIsWeb && _selectedImage != null) {
        // On mobile, save locally for immediate access
        await userState.saveProfilePictureFile(_selectedImage!);
        
        // Upload to Firebase for cloud storage
        finalProfilePhotoUrl = await StorageService.uploadUserProfileImage(
          userId: userState.userId!,
          imageFile: _selectedImage!,
        );
      }

      // Update profile in Firestore
      await firestoreService.updateUserProfile(
        userId: userState.userId!,
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        profilePhotoUrl: finalProfilePhotoUrl,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      );

      // Update local user state (this will save to local storage)
      await userState.updateProfile(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        profilePhotoUrl: finalProfilePhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            _buildProfileImage(),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                                  onPressed: () => _showImagePickerOptions(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to change profile picture',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Full Name Field
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Choose a unique username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      suffixIcon: _isCheckingUsername
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _usernameController.text.isNotEmpty
                              ? Icon(
                                  _isUsernameAvailable ? Icons.check_circle : Icons.cancel,
                                  color: _isUsernameAvailable ? Colors.green : Colors.red,
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _usernameError,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _debouncedUsernameCheck(value);
                      } else {
                        setState(() {
                          _isUsernameAvailable = false;
                          _usernameError = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.length > 20) {
                        return 'Username must be 20 characters or less';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return 'Username can only contain letters, numbers, and underscores';
                      }
                      // Only show username error if it's a real validation error (taken), not a checking error
                      if (_usernameError != null && _usernameError!.contains('already taken')) {
                        return _usernameError;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Bio Field
                  TextFormField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: 'Bio (Optional)',
                      hintText: 'Share a bit about yourself (e.g., interests, hobbies, or what you enjoy)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
              if (_selectedImage != null || _selectedImageBytes != null || _profilePhotoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                      _profilePhotoUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    // If there's a selected image on web (bytes), display it
    if (kIsWeb && _selectedImageBytes != null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        backgroundImage: MemoryImage(_selectedImageBytes!),
      );
    }
    
    // If there's a selected local image on mobile, show it
    if (!kIsWeb && _selectedImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        backgroundImage: FileImage(_selectedImage!),
      );
    }
    
    // If there's a profile photo URL, use ProfileAvatar for web compatibility
    if (_profilePhotoUrl != null && _profilePhotoUrl!.startsWith('http')) {
      return ProfileAvatar(
        profilePhotoUrl: _profilePhotoUrl,
        radius: 60,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        fallbackIcon: Icons.person,
        fallbackIconColor: AppTheme.primaryColor,
      );
    }
    
    // If it's a local file path (mobile only)
    if (!kIsWeb && _profilePhotoUrl != null && !_profilePhotoUrl!.startsWith('http')) {
      final file = File(_profilePhotoUrl!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: FileImage(file),
        );
      }
    }
    
    // Default: show icon
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 60,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

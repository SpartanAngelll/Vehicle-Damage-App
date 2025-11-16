import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import '../services/services.dart';
import '../services/firebase_firestore_service.dart';
import '../models/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _isPasswordReset = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _selectedRole = 'owner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          // Header
          Semantics(
            label: 'Authentication heading',
            header: true,
            child: Text(
              _isPasswordReset ? "Reset Password" : (_isSignUp ? "Join Multi-Service Network" : "Sign In"),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 28, tablet: 32, desktop: 36),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 30, tablet: 40, desktop: 50)),
          
          // Input Fields
          _buildInputFields(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Action Buttons
          _buildActionButtons(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Toggle between Sign In and Sign Up
          if (!_isPasswordReset) _buildToggleButtons(context),
          
          // Password Reset Link
          if (!_isSignUp && !_isPasswordReset) _buildPasswordResetLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildInputFields(BuildContext context) {
    return Column(
      children: [
        // Email Field
        Semantics(
          label: 'Email input field',
          textField: true,
          child: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email",
              hintText: "Enter your email address",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
        
        // Password Field (only show if not password reset)
        if (!_isPasswordReset) ...[
          Semantics(
            label: 'Password input field',
            textField: true,
            child: TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Enter your password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                  vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                ),
              ),
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
        ],
        
        // Confirm Password Field (only show on sign up)
        if (_isSignUp && !_isPasswordReset) ...[
          Semantics(
            label: 'Confirm password input field',
            textField: true,
            child: TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                hintText: "Confirm your password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                  vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                ),
              ),
              obscureText: !_showConfirmPassword,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
        ],
        
        // Phone Number Field (only show on sign up)
        if (_isSignUp && !_isPasswordReset) ...[
          Semantics(
            label: 'Phone number input field',
            textField: true,
            child: TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter your phone number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                  vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                ),
              ),
              keyboardType: TextInputType.phone,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
        ],
        
        // Role Selection (only show on sign up)
        if (_isSignUp && !_isPasswordReset) ...[
          Semantics(
            label: 'User role selection',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select your role:",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text("Service Customer"),
                        subtitle: Text("Request services"),
                        value: "owner",
                        groupValue: _selectedRole,
                        onChanged: (value) => setState(() => _selectedRole = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text("Service Professional"),
                        subtitle: Text("Provide services"),
                        value: "service_professional",
                        groupValue: _selectedRole,
                        onChanged: (value) => setState(() => _selectedRole = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Main Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
              ),
            ),
            onPressed: _isLoading ? null : _handleAction,
            child: _isLoading
                ? SizedBox(
                    height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                    width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                    ),
                  )
                : Text(
                    _isPasswordReset ? "Send Reset Email" : (_isSignUp ? "Join Network" : "Sign In"),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? "Already have an account? " : "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => setState(() {
            _isSignUp = !_isSignUp;
            _clearControllers();
          }),
          child: Text(_isSignUp ? "Sign In" : "Sign Up"),
        ),
      ],
    );
  }

  Widget _buildPasswordResetLink(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() {
        _isPasswordReset = true;
        _clearControllers();
      }),
      child: Text("Forgot Password?"),
    );
  }

  Future<void> _handleAction() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<FirebaseAuthService>();
      
      if (_isPasswordReset) {
        await _handlePasswordReset(authService);
      } else if (_isSignUp) {
        await _handleSignUp(authService);
      } else {
        await _handleSignIn(authService);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordReset(FirebaseAuthService authService) async {
    await authService.resetPassword(_emailController.text.trim());
    
    if (mounted) {
      if (authService.error != null) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } else {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        setState(() {
          _isPasswordReset = false;
          _clearControllers();
        });
      }
    }
  }

  Future<void> _handleSignUp(FirebaseAuthService authService) async {
    final credential = await authService.signUpWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      userType: _selectedRole,
    );

    if (credential == null && mounted) {
      // Sign up failed - show error message
      final errorMessage = authService.error ?? 'Sign up failed. Please try again.';
      debugPrint('❌ [Login] Sign up failed: $errorMessage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    if (credential != null && mounted) {
      // Create user profile in Firestore
      final firestoreService = context.read<FirebaseFirestoreService>();
      await firestoreService.createUserProfile({
        'id': credential.user!.uid,
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'phone': _phoneController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Initialize UserState before navigation
      final userState = context.read<UserState>();
      userState.initializeFromFirebase(
        userId: credential.user!.uid,
        email: _emailController.text.trim(),
        userType: _selectedRole,
        phoneNumber: _phoneController.text.trim(),
        bio: null,
      );

      // Navigate to appropriate screen
      if (_selectedRole == 'owner') {
        Navigator.pushReplacementNamed(context, '/customerProfileSetup');
      } else {
        // For repair professionals, go to the new registration flow
        Navigator.pushReplacementNamed(context, '/serviceProfessionalRegistration');
      }
    }
  }

  Future<void> _handleSignIn(FirebaseAuthService authService) async {
    final credential = await authService.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (credential == null && mounted) {
      // Authentication failed - show error message
      final errorMessage = authService.error ?? 'Login failed. Please check your credentials and try again.';
      debugPrint('❌ [Login] Authentication failed: $errorMessage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    if (credential != null && mounted) {
      // Get user profile to determine role
      final firestoreService = context.read<FirebaseFirestoreService>();
      final userProfile = await firestoreService.getUserProfile(credential.user!.uid);
      
      if (userProfile != null) {
        // Use 'role' field from Firestore, fallback to 'userType' for backward compatibility
        final userType = userProfile['role'] as String? ?? userProfile['userType'] as String? ?? 'owner';
        
        debugPrint('🔍 [Login] User profile from Firestore: $userProfile');
        debugPrint('🔍 [Login] Extracted userType: $userType');
        debugPrint('🔍 [Login] User role field: ${userProfile['role']}');
        debugPrint('🔍 [Login] User userType field: ${userProfile['userType']}');
        
        // Initialize UserState before navigation
        final userState = context.read<UserState>();
        userState.initializeFromFirebase(
          userId: credential.user!.uid,
          email: userProfile['email'] ?? credential.user!.email ?? '',
          userType: userType,
          phoneNumber: userProfile['phone'],
          bio: userProfile['bio'],
          fullName: userProfile['fullName'],
          username: userProfile['username'],
          profilePhotoUrl: userProfile['profilePhotoUrl'],
          currentUser: credential.user,
        );
        
        if (userType == 'owner') {
          Navigator.pushReplacementNamed(context, '/ownerDashboard');
        } else {
          // For service professionals, check if they have a complete profile
          final firestoreService = context.read<FirebaseFirestoreService>();
          try {
            final professionalProfile = await firestoreService.getServiceProfessional(credential.user!.uid);
            if (professionalProfile != null) {
              // Profile exists, go to service professional dashboard
              debugPrint('🔍 [Login] Navigating to service professional dashboard');
              Navigator.pushReplacementNamed(context, '/repairmanDashboard');
            } else {
              // Profile doesn't exist, go to registration
              debugPrint('🔍 [Login] No profile found, navigating to registration');
              Navigator.pushReplacementNamed(context, '/serviceProfessionalRegistration');
            }
          } catch (e) {
            // If there's an error, go to registration
            debugPrint('🔍 [Login] Error checking profile, navigating to registration: $e');
            Navigator.pushReplacementNamed(context, '/serviceProfessionalRegistration');
          }
        }
      } else {
        // Fallback to owner dashboard if profile not found
        Navigator.pushReplacementNamed(context, '/ownerDashboard');
      }
    }
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address')),
      );
      return false;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    if (_isPasswordReset) return true;

    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your password')),
      );
      return false;
    }

    if (_isSignUp) {
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password must be at least 6 characters long')),
        );
        return false;
      }

      final confirmPassword = _confirmPasswordController.text;
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return false;
      }

      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter your phone number')),
        );
        return false;
      }
    }
    
    return true;
  }

  void _clearControllers() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

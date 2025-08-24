import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import '../models/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

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
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'Sign Up heading',
            header: true,
            child: Text(
              "Sign Up", 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 28, tablet: 32, desktop: 36), 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              )
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 30, tablet: 40, desktop: 50)),
          _buildInputFields(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24)),
          _buildSocialButtons(context),
          SizedBox(height: ResponsiveUtils.getResponsivePadding(context, mobile: 30, tablet: 40, desktop: 50)),
          _buildRoleButtons(context),
        ],
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
        Semantics(
          label: 'Email input field',
          textField: true,
          child: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email",
              hintText: "Enter your email address",
              border: OutlineInputBorder(),
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
        Semantics(
          label: 'Phone number input field',
          textField: true,
          child: TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: "Phone Number",
              hintText: "Enter your phone number",
              border: OutlineInputBorder(),
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
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Semantics(
          label: 'Sign in with Google',
          button: true,
          child: ElevatedButton.icon(
            icon: Semantics(
              label: 'Google logo',
              child: Icon(Icons.g_mobiledata, size: ResponsiveUtils.getResponsiveIconSize(context)),
            ),
            label: Text(
              "Google",
              style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20)),
            ),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
              ),
            ),
          ),
        ),
        Semantics(
          label: 'Sign in with Apple',
          button: true,
          child: ElevatedButton.icon(
            icon: Semantics(
              label: 'Apple logo',
              child: Icon(Icons.apple, size: ResponsiveUtils.getResponsiveIconSize(context)),
            ),
            label: Text(
              "Apple",
              style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20)),
            ),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsivePadding(context, mobile: 16, tablet: 20, desktop: 24),
                vertical: ResponsiveUtils.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Semantics(
          label: 'Select Vehicle Owner role',
          button: true,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(
                ResponsiveUtils.getResponsiveButtonWidth(context, mobile: 120, tablet: 140, desktop: 160),
                ResponsiveUtils.getResponsiveButtonHeight(context, mobile: 50, tablet: 60, desktop: 70),
              ),
            ),
            onPressed: () async {
              if (_validateInputs()) {
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  final userState = context.read<UserState>();
                  
                  // Use actual user input
                  await userState.signIn(
                    email: _emailController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                    role: UserRole.owner,
                  );
                  
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/ownerDashboard');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login failed: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
            child: _isLoading 
              ? SizedBox(
                  height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 30, tablet: 36, desktop: 40),
                  width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 30, tablet: 36, desktop: 40),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                  ),
                )
              : Column(
                  children: [
                    Semantics(
                      label: 'Vehicle icon',
                      child: Icon(
                        Icons.directions_car, 
                        size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 30, tablet: 36, desktop: 40)
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Vehicle Owner",
                      style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18)),
                    ),
                  ],
                ),
          ),
        ),
        Semantics(
          label: 'Select Auto Repair Professional role',
          button: true,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(
                ResponsiveUtils.getResponsiveButtonWidth(context, mobile: 120, tablet: 140, desktop: 160),
                ResponsiveUtils.getResponsiveButtonHeight(context, mobile: 50, tablet: 60, desktop: 70),
              ),
            ),
            onPressed: () async {
              if (_validateInputs()) {
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  final userState = context.read<UserState>();
                  
                  // Use actual user input
                  await userState.signIn(
                    email: _emailController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                    role: UserRole.repairman,
                  );
                  
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/repairmanDashboard');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login failed: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
            child: _isLoading 
              ? SizedBox(
                  height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 30, tablet: 36, desktop: 40),
                  width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 30, tablet: 36, desktop: 40),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                  ),
                )
              : Column(
                  children: [
                    Semantics(
                      label: 'Tools icon',
                      child: Icon(
                        Icons.build, 
                        size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 30, tablet: 36, desktop: 40)
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Auto Repair Pro",
                      style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18)),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address')),
      );
      return false;
    }
    
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your phone number')),
      );
      return false;
    }
    
    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }
    
    // Basic phone validation
    if (!RegExp(r'^\+?[\d\s-]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number')),
      );
      return false;
    }
    
    return true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

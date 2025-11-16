import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/user_state.dart';
import '../services/services.dart';
import '../services/service_category_service.dart';
import '../services/firebase_firestore_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import 'search_professionals_screen.dart';
import 'login_screen.dart';
import 'service_professional_registration_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newsletterZipController = TextEditingController();
  
  List<ServiceCategory> _categories = [];
  bool _isLoadingCategories = true;
  final ServiceCategoryService _categoryService = ServiceCategoryService();

  // Popular projects data (similar to Angi.com)
  final List<Map<String, dynamic>> _popularProjects = [
    {
      'name': 'Vehicle Repair',
      'icon': Icons.build,
      'rating': 4.7,
      'reviews': '12.5k+',
      'price': 'from \$150',
      'color': Color(0xFFDC143C),
    },
    {
      'name': 'Home Cleaning',
      'icon': Icons.cleaning_services,
      'rating': 4.5,
      'reviews': '8.2k+',
      'price': 'from \$85',
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Plumbing Services',
      'icon': Icons.plumbing,
      'rating': 4.6,
      'reviews': '15.3k+',
      'price': 'from \$120',
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Electrical Work',
      'icon': Icons.electrical_services,
      'rating': 4.8,
      'reviews': '9.7k+',
      'price': 'from \$180',
      'color': Color(0xFFFFC107),
    },
    {
      'name': 'HVAC Services',
      'icon': Icons.ac_unit,
      'rating': 4.7,
      'reviews': '6.4k+',
      'price': 'from \$200',
      'color': Color(0xFF00BCD4),
    },
    {
      'name': 'Landscaping',
      'icon': Icons.landscape,
      'rating': 4.4,
      'reviews': '5.1k+',
      'price': 'from \$150',
      'color': Color(0xFF8BC34A),
    },
    {
      'name': 'Painting',
      'icon': Icons.format_paint,
      'rating': 4.6,
      'reviews': '7.8k+',
      'price': 'from \$300',
      'color': Color(0xFFE91E63),
    },
    {
      'name': 'IT Support',
      'icon': Icons.computer,
      'rating': 4.9,
      'reviews': '4.2k+',
      'price': 'from \$100',
      'color': Color(0xFF455A64),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _zipCodeController.dispose();
    _emailController.dispose();
    _newsletterZipController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories.take(12).toList(); // Show first 12 categories
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    final zipCode = _zipCodeController.text.trim();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchProfessionalsScreen(
          initialQuery: query.isNotEmpty ? query : null,
          zipCode: zipCode.isNotEmpty ? zipCode : null,
        ),
      ),
    );
  }

  void _handleNewsletterSignup() {
    // TODO: Implement newsletter signup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for signing up!'),
        backgroundColor: Color(0xFFDC143C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isPortrait = ResponsiveUtils.isPortrait(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header
          _buildHeader(isWeb, screenWidth, isMobile, isPortrait),
          
          // Hero Section
          SliverToBoxAdapter(
            child: _buildHeroSection(isWeb, screenWidth, isMobile, isPortrait, screenHeight),
          ),
          
          // Service Categories
          SliverToBoxAdapter(
            child: _buildServiceCategories(isWeb, screenWidth, isMobile, isPortrait, isLandscape),
          ),
          
          // Popular Projects
          SliverToBoxAdapter(
            child: _buildPopularProjects(isWeb, screenWidth, isMobile, isTablet, isPortrait, isLandscape),
          ),
          
          // Newsletter Signup
          SliverToBoxAdapter(
            child: _buildNewsletterSection(isWeb, screenWidth, isMobile, isPortrait, isLandscape),
          ),
          
          // Footer
          SliverToBoxAdapter(
            child: _buildFooter(isWeb, screenWidth, isMobile, isPortrait),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWeb, double screenWidth, bool isMobile, bool isPortrait) {
    // Force mobile layout if screen width is less than 768px, even on web
    final forceMobile = screenWidth < 768;
    // In landscape on mobile, we have more horizontal space
    final isMobileLandscape = forceMobile && !isPortrait;
    
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.all(forceMobile ? (isPortrait ? 4.0 : 6.0) : 8.0),
        child: Text(
          'ServicePro',
          style: TextStyle(
            fontSize: forceMobile 
              ? (isPortrait ? 18 : 20) 
              : (isWeb ? 28 : 24),
            fontWeight: FontWeight.bold,
            color: Color(0xFFDC143C), // Angi red
            fontFamily: 'Poppins',
          ),
        ),
      ),
      leadingWidth: forceMobile 
        ? (isPortrait ? 120 : 140) 
        : (isWeb ? 200 : 150),
      actions: [
        // Show navigation links in landscape mobile if there's enough space
        if ((isWeb && !forceMobile && screenWidth >= 768) || 
            (isMobileLandscape && screenWidth >= 600)) ...[
          TextButton(
            onPressed: () {},
            child: Text(
              'Services',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'How It Works',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Resources',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
        if (forceMobile || (!isWeb && isMobile))
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: Colors.black87),
            onSelected: (value) {
              if (value == 'join') {
                Navigator.pushNamed(context, '/serviceProfessionalRegistration');
              } else if (value == 'login') {
                Navigator.pushNamed(context, '/login');
              } else if (value == 'signup') {
                Navigator.pushNamed(context, '/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'join',
                child: Text('Join as a Pro'),
              ),
              PopupMenuItem(
                value: 'login',
                child: Text('Log In'),
              ),
              PopupMenuItem(
                value: 'signup',
                child: Text('Sign Up'),
              ),
            ],
          )
        else if ((isWeb && !forceMobile && screenWidth >= 768) || 
                 (isMobileLandscape && screenWidth >= 600)) ...[
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/serviceProfessionalRegistration');
            },
            child: Text(
              'Join as a Pro',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              'Log In',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC143C),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text('Sign Up', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroSection(bool isWeb, double screenWidth, bool isMobile, bool isPortrait, double screenHeight) {
    final forceMobile = screenWidth < 768;
    // In portrait, use more height. In landscape, use less height but more width
    final heroHeight = forceMobile 
      ? (isPortrait ? 350.0 : 280.0)
      : (isWeb ? 500.0 : 400.0);
    
    return Container(
      height: heroHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5F5F5),
                    Color(0xFFE8E8E8),
                  ],
                ),
              ),
            ),
          ),
          // Content overlay
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWeb && !forceMobile
                  ? ResponsiveUtils.getWebMaxWidth(context) * 0.8
                  : screenWidth - 32,
              ),
              padding: EdgeInsets.all(
                forceMobile 
                  ? (isPortrait ? 16 : 12) 
                  : (isWeb ? 40 : 24)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Find top-rated pros in your area',
                    style: TextStyle(
                      fontSize: forceMobile 
                        ? (isPortrait ? 24 : 20)
                        : (isWeb ? 48 : 32),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: forceMobile 
                    ? (isPortrait ? 20 : 12) 
                    : 32),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ((isWeb && !forceMobile && screenWidth >= 768) ||
                            (forceMobile && !isPortrait && screenWidth >= 600))
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'What can we help you with?',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                  onSubmitted: (_) => _handleSearch(),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _zipCodeController,
                                  decoration: InputDecoration(
                                    hintText: 'Zip Code',
                                    prefixIcon: Icon(Icons.location_on),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onSubmitted: (_) => _handleSearch(),
                                ),
                              ),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Color(0xFFDC143C),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.search, color: Colors.white),
                                  onPressed: _handleSearch,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'What can we help you with?',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                onSubmitted: (_) => _handleSearch(),
                              ),
                              Divider(height: 1),
                              TextField(
                                controller: _zipCodeController,
                                decoration: InputDecoration(
                                  hintText: 'Zip Code',
                                  prefixIcon: Icon(Icons.location_on),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onSubmitted: (_) => _handleSearch(),
                              ),
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Color(0xFFDC143C),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.search, color: Colors.white),
                                  onPressed: _handleSearch,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (!forceMobile) ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Find top-rated pros in your area'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategories(bool isWeb, double screenWidth, bool isMobile, bool isPortrait, bool isLandscape) {
    final forceMobile = screenWidth < 768;
    final maxWidth = (isWeb && !forceMobile) ? ResponsiveUtils.getWebMaxWidth(context) : screenWidth;
    final padding = ResponsiveUtils.getWebContentPadding(context);
    
    return Container(
      padding: forceMobile
        ? EdgeInsets.symmetric(
            vertical: isPortrait ? 30 : 20,
            horizontal: isPortrait ? 16 : 20
          )
        : (isWeb 
          ? EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              top: 60,
              bottom: 60,
            )
          : EdgeInsets.symmetric(vertical: 40, horizontal: 24)),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingCategories)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Wrap(
                  spacing: forceMobile 
                    ? (isPortrait ? 12 : 16)
                    : (isWeb ? 24 : 16),
                  runSpacing: forceMobile 
                    ? (isPortrait ? 12 : 10)
                    : (isWeb ? 24 : 16),
                  alignment: WrapAlignment.center,
                  children: _categories.map((category) {
                    return _buildCategoryCard(category, isWeb, forceMobile, isPortrait);
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ServiceCategory category, bool isWeb, bool isMobile, bool isPortrait) {
    final screenWidth = MediaQuery.of(context).size.width;
    final forceMobile = screenWidth < 768;
    // In landscape, we can make cards slightly larger
    final cardWidth = forceMobile 
      ? (isPortrait ? 90.0 : 100.0)
      : (isWeb ? 140.0 : 100.0);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchProfessionalsScreen(
              initialQuery: category.name,
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.all(
          forceMobile 
            ? (isPortrait ? 12 : 14)
            : (isWeb ? 20 : 16)
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: forceMobile 
                ? (isPortrait ? 32 : 36)
                : (isWeb ? 48 : 36),
              color: category.color,
            ),
            SizedBox(height: forceMobile 
              ? (isPortrait ? 8 : 6)
              : 12),
            Text(
              category.name,
              style: TextStyle(
                fontSize: forceMobile 
                  ? (isPortrait ? 11 : 12)
                  : (isWeb ? 14 : 12),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProjects(bool isWeb, double screenWidth, bool isMobile, bool isTablet, bool isPortrait, bool isLandscape) {
    final forceMobile = screenWidth < 768;
    final maxWidth = (isWeb && !forceMobile) ? ResponsiveUtils.getWebMaxWidth(context) : screenWidth;
    final padding = ResponsiveUtils.getWebContentPadding(context);
    
    // Determine cross axis count based on screen size and orientation
    int crossAxisCount;
    if (forceMobile) {
      // In landscape mobile, we can fit 3 columns instead of 2
      crossAxisCount = isPortrait ? 2 : 3;
    } else if (isTablet || screenWidth < 1024) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }
    
    return Container(
      padding: forceMobile
        ? EdgeInsets.symmetric(
            vertical: isPortrait ? 30 : 20,
            horizontal: isPortrait ? 16 : 20
          )
        : (isWeb 
          ? EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              top: 60,
              bottom: 60,
            )
          : EdgeInsets.symmetric(vertical: 40, horizontal: 24)),
      color: Colors.grey[50],
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular projects near you',
                style: TextStyle(
                  fontSize: forceMobile ? 20 : (isWeb ? 32 : 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: forceMobile ? 20 : 32),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: forceMobile 
                    ? (isPortrait ? 8 : 10)
                    : 16,
                  mainAxisSpacing: forceMobile 
                    ? (isPortrait ? 8 : 10)
                    : 16,
                  childAspectRatio: forceMobile 
                    ? (isPortrait ? 0.85 : 0.75)
                    : (isWeb ? 0.85 : 0.9),
                ),
                itemCount: _popularProjects.length,
                itemBuilder: (context, index) {
                  final project = _popularProjects[index];
                  return _buildProjectCard(project, isWeb, forceMobile, isPortrait);
                },
              ),
              SizedBox(height: forceMobile ? 12 : 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: forceMobile ? 0 : 0),
                child: Text(
                  'Price shown is the national median price. Actual pricing may vary.',
                  style: TextStyle(
                    fontSize: forceMobile ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, bool isWeb, bool isMobile, bool isPortrait) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchProfessionalsScreen(
                initialQuery: project['name'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(
            isMobile 
              ? (isPortrait ? 12 : 10)
              : (isWeb ? 20 : 16)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                project['icon'],
                size: isMobile 
                  ? (isPortrait ? 28 : 24)
                  : (isWeb ? 40 : 32),
                color: project['color'],
              ),
              SizedBox(height: isMobile 
                ? (isPortrait ? 8 : 6)
                : 12),
              Text(
                project['name'],
                style: TextStyle(
                  fontSize: isMobile 
                    ? (isPortrait ? 13 : 12)
                    : (isWeb ? 16 : 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile 
                ? (isPortrait ? 6 : 4)
                : 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star, 
                    size: isMobile 
                      ? (isPortrait ? 14 : 12)
                      : 16, 
                    color: Colors.amber
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${project['rating']}',
                    style: TextStyle(
                      fontSize: isMobile 
                        ? (isPortrait ? 12 : 11)
                        : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${project['reviews']})',
                      style: TextStyle(
                        fontSize: isMobile 
                          ? (isPortrait ? 10 : 9)
                          : 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile 
                ? (isPortrait ? 8 : 6)
                : 12),
              Text(
                project['price'],
                style: TextStyle(
                  fontSize: isMobile 
                    ? (isPortrait ? 13 : 12)
                    : (isWeb ? 16 : 14),
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC143C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsletterSection(bool isWeb, double screenWidth, bool isMobile, bool isPortrait, bool isLandscape) {
    final forceMobile = screenWidth < 768;
    final maxWidth = (isWeb && !forceMobile) ? ResponsiveUtils.getWebMaxWidth(context) : screenWidth;
    final padding = ResponsiveUtils.getWebContentPadding(context);
    // In landscape mobile, we can use row layout
    final useRowLayout = (isWeb && !forceMobile && screenWidth >= 768) || 
                         (forceMobile && !isPortrait && screenWidth >= 600);
    
    return Container(
      padding: forceMobile
        ? EdgeInsets.symmetric(
            vertical: isPortrait ? 30 : 20,
            horizontal: isPortrait ? 16 : 20
          )
        : (isWeb 
          ? EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              top: 60,
              bottom: 60,
            )
          : EdgeInsets.symmetric(vertical: 40, horizontal: 24)),
      color: Color(0xFFF5F5F5),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
          child: useRowLayout
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Knowledge is priceless - so our cost guides are free.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sign up to get free project cost info in your inbox.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 40),
                  Expanded(
                    flex: 1,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email address',
                              prefixIcon: Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: _newsletterZipController,
                            decoration: InputDecoration(
                              hintText: 'Zip code',
                              prefixIcon: Icon(Icons.location_on),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleNewsletterSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFDC143C),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Sign me up'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Knowledge is priceless - so our cost guides are free.',
                    style: TextStyle(
                      fontSize: forceMobile 
                        ? (isPortrait ? 18 : 16)
                        : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Sign up to get free project cost info in your inbox.',
                    style: TextStyle(
                      fontSize: forceMobile 
                        ? (isPortrait ? 12 : 11)
                        : 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _newsletterZipController,
                    decoration: InputDecoration(
                      hintText: 'Zip code',
                      prefixIcon: Icon(Icons.location_on),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleNewsletterSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDC143C),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Sign me up'),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isWeb, double screenWidth, bool isMobile, bool isPortrait) {
    final forceMobile = screenWidth < 768;
    final maxWidth = (isWeb && !forceMobile) ? ResponsiveUtils.getWebMaxWidth(context) : screenWidth;
    final padding = ResponsiveUtils.getWebContentPadding(context);
    
    return Container(
      padding: forceMobile
        ? EdgeInsets.symmetric(
            vertical: isPortrait ? 20 : 16,
            horizontal: isPortrait ? 16 : 20
          )
        : (isWeb 
          ? EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              top: 40,
              bottom: 40,
            )
          : EdgeInsets.symmetric(vertical: 24, horizontal: 24)),
      color: Colors.grey[900],
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
          child: Column(
            children: [
              forceMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ServicePro',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: Text('About', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('Contact', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('Privacy', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('Terms', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ServicePro',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (isWeb && !forceMobile)
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text('About', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text('Contact', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text('Privacy', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text('Terms', style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                    ],
                  ),
              SizedBox(height: 20),
              Divider(color: Colors.white24),
              SizedBox(height: 20),
              Text(
                '© 2024 ServicePro. All rights reserved.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: forceMobile ? 10 : 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
        ),
        ),
      ),
    );
  }
}


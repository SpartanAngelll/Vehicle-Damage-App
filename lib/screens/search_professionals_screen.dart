import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/service_professional.dart';
import '../models/user_state.dart';
import '../models/chat_models.dart';
import '../services/firebase_firestore_service.dart';
import '../services/chat_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/web_layout.dart';
import 'customer_booking_screen.dart';

class SearchProfessionalsScreen extends StatefulWidget {
  final String? initialQuery;
  final String? zipCode;
  
  const SearchProfessionalsScreen({
    super.key,
    this.initialQuery,
    this.zipCode,
  });

  @override
  State<SearchProfessionalsScreen> createState() => _SearchProfessionalsScreenState();
}

class _SearchProfessionalsScreenState extends State<SearchProfessionalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  
  List<ServiceProfessional> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    
    // Add a small delay to focus the search field and perform search if query exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus();
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _performSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _firestoreService.searchServiceProfessionalsByName(query);
      setState(() {
        _searchResults = results;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search professionals: $e';
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _errorMessage = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    // Build the search content
    final searchContent = Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or business...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  onSubmitted: (value) => _performSearch(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearching ? null : _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: _isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Search',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
        
        // Results
        Expanded(
          child: _buildResults(),
        ),
      ],
    );
    
    // On web, use WebLayout with max width constraint
    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      final maxContentWidth = (screenWidth > 1400 ? 1200.0 : 1100.0);
      
      return WebLayout(
        currentRoute: '/searchProfessionals',
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            width: double.infinity,
            child: searchContent,
          ),
        ),
      );
    }
    
    // On mobile, use regular Scaffold
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Professionals',
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: searchContent,
    );
  }

  Widget _buildResults() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildSearchResults();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for Service Professionals',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a name or business name to find professionals',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              fontFamily: 'Inter',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching professionals...',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              fontFamily: 'Inter',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Professionals Found',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different name or business',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              fontFamily: 'Inter',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Error',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              fontFamily: 'Inter',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _performSearch,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final professional = _searchResults[index];
        return _buildProfessionalCard(professional);
      },
    );
  }

  Widget _buildProfessionalCard(ServiceProfessional professional) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProfessionalActions(professional),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile avatar
              ProfileAvatar(
                profilePhotoUrl: professional.profilePhotoUrl,
                radius: 30,
              ),
              const SizedBox(width: 16),
              
              // Professional info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.fullName,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (professional.businessName != null && professional.businessName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        professional.businessName!,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          fontFamily: 'Inter',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    
                    // Rating and experience
                    Row(
                      children: [
                        if (professional.averageRating > 0) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            professional.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (professional.yearsOfExperience > 0) ...[
                          Icon(
                            Icons.work,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${professional.yearsOfExperience} years exp.',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                              fontFamily: 'Inter',
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Specializations
                    if (professional.specializations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: professional.specializations.take(3).map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              spec,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 10,
                                  tablet: 12,
                                  desktop: 14,
                                ),
                                fontFamily: 'Inter',
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // More options button
              Icon(
                Icons.more_vert,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfessionalActions(ServiceProfessional professional) async {
    // Check if there's an existing chat first
    final userState = context.read<UserState>();
    ChatRoom? existingChat;
    
    if (userState.isAuthenticated && userState.userId != null) {
      try {
        final chatService = ChatService();
        existingChat = await chatService.getExistingChatRoom(
          userState.userId!,
          professional.userId,
        );
      } catch (e) {
        print('Error checking for existing chat: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildActionSheet(professional, existingChat),
    );
  }

  Widget _buildActionSheet(ServiceProfessional professional, ChatRoom? existingChat) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Professional info header
          Row(
            children: [
              ProfileAvatar(
                profilePhotoUrl: professional.profilePhotoUrl,
                radius: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.fullName,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (professional.businessName != null && professional.businessName!.isNotEmpty)
                      Text(
                        professional.businessName!,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          fontFamily: 'Inter',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButton(
            icon: Icons.person,
            title: 'View Profile',
            subtitle: 'See full professional details',
            onTap: () {
              Navigator.pop(context);
              _viewProfessionalProfile(professional);
            },
          ),
          
          const SizedBox(height: 12),
          
          // Show either "Start Chat" or "View Existing Chat" based on whether chat exists
          if (existingChat != null) ...[
            _buildActionButton(
              icon: Icons.history,
              title: 'View Existing Chat',
              subtitle: 'Continue previous conversation',
              onTap: () {
                Navigator.pop(context);
                _viewExistingChat(professional);
              },
            ),
          ] else ...[
            _buildActionButton(
              icon: Icons.chat,
              title: 'Start Chat',
              subtitle: 'Send a message to this professional',
              onTap: () {
                Navigator.pop(context);
                _startChat(professional);
              },
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Book Appointment button
          _buildActionButton(
            icon: Icons.calendar_today,
            title: 'Book Appointment',
            subtitle: 'Schedule a service appointment',
            onTap: () {
              Navigator.pop(context);
              _bookAppointment(professional);
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      fontFamily: 'Inter',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _viewProfessionalProfile(ServiceProfessional professional) {
    // Navigate to professional profile screen
    Navigator.pushNamed(
      context,
      '/serviceProfessionalProfile',
      arguments: professional.id,
    );
  }

  Future<void> _startChat(ServiceProfessional professional) async {
    try {
      final userState = context.read<UserState>();
      if (!userState.isAuthenticated || userState.userId == null) {
        _showErrorSnackBar('Please log in to start a chat');
        return;
      }

      final chatService = ChatService();
      
      // Check if there's an existing chat
      final existingChat = await chatService.getExistingChatRoom(
        userState.userId!,
        professional.userId,
      );

      if (existingChat != null) {
        // Navigate to existing chat
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: existingChat.id,
        );
      } else {
        // Create new direct chat
        // IMPORTANT: Use currentUser?.uid to ensure we use the current Firebase Auth UID
        final currentCustomerId = userState.currentUser?.uid ?? userState.userId;
        if (currentCustomerId == null) {
          _showErrorSnackBar('Please log in to start a chat');
          return;
        }
        final newChat = await chatService.createDirectChatRoom(
          customerId: currentCustomerId,
          professionalId: professional.userId,
          customerName: userState.fullName ?? 'Customer',
          professionalName: professional.fullName,
          customerPhotoUrl: userState.profilePhotoUrl,
          professionalPhotoUrl: professional.profilePhotoUrl,
        );

        // Navigate to new chat
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: newChat.id,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start chat: $e');
    }
  }

  Future<void> _viewExistingChat(ServiceProfessional professional) async {
    try {
      final userState = context.read<UserState>();
      if (!userState.isAuthenticated || userState.userId == null) {
        _showErrorSnackBar('Please log in to view chats');
        return;
      }

      final chatService = ChatService();
      
      // Check if there's an existing chat
      final existingChat = await chatService.getExistingChatRoom(
        userState.userId!,
        professional.userId,
      );

      if (existingChat != null) {
        // Navigate to existing chat
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: existingChat.id,
        );
      } else {
        _showErrorSnackBar('No existing chat found with this professional');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load chat: $e');
    }
  }

  void _bookAppointment(ServiceProfessional professional) {
    final userState = context.read<UserState>();
    if (!userState.isAuthenticated || userState.userId == null) {
      _showErrorSnackBar('Please log in to book an appointment');
      return;
    }

    // IMPORTANT: Use currentUser?.uid to ensure we use the current Firebase Auth UID
    final currentCustomerId = userState.currentUser?.uid ?? userState.userId;
    if (currentCustomerId == null) {
      _showErrorSnackBar('Please log in to book an appointment');
      return;
    }
    
    // For now, we'll use placeholder values for the booking
    // In a real app, these would come from a service request or user input
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerBookingScreen(
          professional: professional,
          customerId: currentCustomerId,
          customerName: userState.fullName ?? 'Customer',
          serviceTitle: 'Service Request', // This would come from the actual service request
          serviceDescription: 'Please describe your service needs', // This would be more specific
          agreedPrice: 0.0, // This would come from an estimate
          location: 'Service Location', // This would come from user input
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

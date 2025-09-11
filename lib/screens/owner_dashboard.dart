import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../models/review_models.dart';
import '../widgets/widgets.dart';
import '../utils/responsive_utils.dart';
import '../services/services.dart';
import '../services/firebase_firestore_service.dart';
import '../services/review_service.dart';
import '../screens/chat_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/my_service_requests_screen.dart';
import '../screens/reviews_screen.dart';
import '../widgets/glow_card.dart';
import '../widgets/auto_scrolling_services.dart';
import '../widgets/instructional_overlay.dart';

// Custom data structure to hold job request with estimate status
class JobRequestWithEstimate {
  final JobRequest jobRequest;
  final EstimateStatus? estimateStatus;
  final String? estimateId;

  JobRequestWithEstimate({
    required this.jobRequest,
    this.estimateStatus,
    this.estimateId,
  });
}


class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  int _refreshCounter = 0;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.person),
          onPressed: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
          tooltip: 'Profile',
        ),
        title: Text(
          _getAppBarTitle(),
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getBottomNavIndex(),
        onTap: (index) {
          if (index == 2) {
            // + button - navigate to create service request
            Navigator.pushNamed(context, '/serviceRequest');
          } else {
            // Map bottom nav index to internal tab index
            int internalIndex = _getInternalIndexFromBottomNav(index);
            setState(() {
              _selectedIndex = internalIndex;
            });
          }
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Estimates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(context);
      case 1:
        return _buildProfileTab(context);
      case 2:
        return _buildMyEstimatesTab(context);
      case 3:
        return _buildChatTab(context);
      case 4:
        return _buildMyBookingsTab(context);
      default:
        return _buildHomeTab(context);
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Profile';
      case 2:
        return 'Estimates';
      case 3:
        return 'Chat';
      case 4:
        return 'Bookings';
      default:
        return 'Home';
    }
  }

  // Map internal tab index to bottom navigation index
  int _getBottomNavIndex() {
    switch (_selectedIndex) {
      case 0: // Home 
        return 0;
      case 1: // Profile - not in bottom nav, but show Home as selected
        return 0;
      case 2: // Estimates
        return 1;
      case 3: // Chat
        return 3;
      case 4: // Bookings
        return 4;
      default:
        return 0;
    }
  }

  // Map bottom navigation index to internal tab index
  int _getInternalIndexFromBottomNav(int bottomNavIndex) {
    switch (bottomNavIndex) {
      case 0: // Home
        return 0;
      case 1: // Estimates
        return 2;
      case 3: // Chat
        return 3;
      case 4: // Bookings
        return 4;
      default:
        return 0; // Default to Home
    }
  }

  // Home Tab - Interactive Landing Screen
  Widget _buildHomeTab(BuildContext context) {
    return Column(
      children: [
        // Instructional overlay at the top
        const InstructionalOverlay(),
        
        // Auto-scrolling services
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            child: const AutoScrollingServices(),
          ),
        ),
        
        // Bottom spacing for bottom navigation
        const SizedBox(height: 20),
      ],
    );
  }

  // Profile Tab
  Widget _buildProfileTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 24),
              
              // Profile Card
              GlowCard(
                glowColor: Theme.of(context).colorScheme.primary,
                borderRadius: 16,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                                Text(
                                  userState.email ?? 'Customer',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
          ),
        ),
                                SizedBox(height: 4),
        Text(
                                  'Service Request Customer',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildProfileInfoRow(context, 'Email', userState.email ?? 'Not provided'),
                      _buildProfileInfoRow(context, 'User ID', userState.userId ?? 'Not available'),
                      _buildProfileInfoRow(context, 'Account Type', 'Customer'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Reviews Section
              _buildReviewsSection(context, userState),
              
              SizedBox(height: 24),
              
              // My Service Requests Section
              _buildMyServiceRequestsSection(context),
            ],
          ),
        );
      },
    );
  }

  // My Estimates Tab
  Widget _buildMyEstimatesTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (userState.userId == null) {
          return Center(
            child: Text(
              'Please sign in to view your estimates.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return FutureBuilder<List<Estimate>>(
          key: ValueKey('estimates_$_refreshCounter'),
          future: _loadUserEstimates(userState.userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error loading estimates: ${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final estimates = snapshot.data ?? [];

            if (estimates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No estimates received yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Estimates from professionals will appear here once you submit service requests.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

                        return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: estimates.length,
              itemBuilder: (context, index) {
                final estimate = estimates[index];
                return CustomerEstimateCard(
                  estimate: estimate,
                  onStatusChanged: () {
                    // Refresh both estimates and service requests when status changes
                    setState(() {
                      _refreshCounter++;
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Chat Tab
  Widget _buildChatTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (userState.userId == null) {
          return Center(
            child: Text(
              'Please sign in to view your chats.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return StreamBuilder<List<ChatRoom>>(
          stream: _chatService.getUserChatRoomsStream(userState.userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading chats: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final chatRooms = snapshot.data ?? [];

            if (chatRooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active chats yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chat conversations will appear here once you accept an estimate and start messaging with service professionals.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 2; // Switch to Estimates tab
                        });
                      },
                      icon: Icon(Icons.assessment),
                      label: Text('View Estimates'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                return ChatCard(
                  glowColor: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatRoomId: chatRoom.id,
                          otherUserName: chatRoom.professionalName,
                          otherUserPhotoUrl: chatRoom.professionalPhotoUrl,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: chatRoom.professionalPhotoUrl != null
                            ? NetworkImage(chatRoom.professionalPhotoUrl!)
                            : null,
                        child: chatRoom.professionalPhotoUrl == null
                            ? Icon(Icons.person)
                            : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chatRoom.professionalName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (chatRoom.lastMessage != null)
                              Text(
                                chatRoom.lastMessage!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatLastMessageTime(chatRoom.lastMessageAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // My Bookings Tab
  Widget _buildMyBookingsTab(BuildContext context) {
    return const MyBookingsScreen();
  }

  // Service Requests Log Tab
  Widget _buildServiceRequestsLogTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (userState.userId == null) {
          return Center(
            child: Text(
              'Please sign in to view your service requests.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return FutureBuilder<List<JobRequestWithEstimate>>(
          key: ValueKey('service_requests_$_refreshCounter'),
          future: _loadUserServiceRequestsWithEstimates(userState.userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error loading service requests: ${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No service requests yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first service request to get started.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 0; // Switch to Home tab
                        });
                      },
                      icon: Icon(Icons.add_task),
                      label: Text('Create Request'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final requestWithEstimate = requests[index];
                final request = requestWithEstimate.jobRequest;
                final estimateStatus = requestWithEstimate.estimateStatus;
                
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEstimateStatusColor(estimateStatus),
                      child: Icon(
                        _getEstimateStatusIcon(estimateStatus),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      request.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.description),
                        SizedBox(height: 4),
                        Text(
                          'Status: ${_getEstimateStatusText(estimateStatus)}',
                  style: TextStyle(
                            color: _getEstimateStatusColor(estimateStatus),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (request.estimatedBudget != null)
                          Text('Budget: \$${request.estimatedBudget!.toStringAsFixed(0)}'),
                        Text('Created: ${_formatDate(request.createdAt)}'),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navigate to request details
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper Methods
  Widget _buildServiceCategoriesGrid(BuildContext context) {
    final categories = [
      {'id': 'mechanics', 'name': 'Automotive', 'icon': Icons.directions_car, 'color': Colors.blue},
      {'id': 'plumbers', 'name': 'Plumbing', 'icon': Icons.plumbing, 'color': Colors.cyan},
      {'id': 'electricians', 'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.amber},
      {'id': 'hairdressers_barbers', 'name': 'Hair', 'icon': Icons.content_cut, 'color': Colors.pink},
      {'id': 'makeup_artists', 'name': 'Makeup', 'icon': Icons.face, 'color': Colors.purple},
      {'id': 'nail_technicians', 'name': 'Nails', 'icon': Icons.brush, 'color': Colors.red},
      {'id': 'cleaners', 'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.green},
      {'id': 'landscapers', 'name': 'Landscaping', 'icon': Icons.grass, 'color': Colors.lightGreen},
    ];

    // Responsive grid columns
    final crossAxisCount = ResponsiveUtils.isTablet(context) ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryColor = category['color'] as Color;
        return ServiceCategoryCard(
          name: category['name'] as String,
          icon: category['icon'] as IconData,
          color: categoryColor,
          onTap: () => Navigator.pushNamed(context, '/serviceRequest'),
        );
      },
    );
  }

  Widget _buildProfileInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
                      child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyServiceRequestsSection(BuildContext context) {
    return GlowCard(
      glowColor: Theme.of(context).colorScheme.secondary,
      borderRadius: 16,
      onTap: () => _navigateToMyServiceRequests(context),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment,
                size: 24,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Service Requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View and manage your service requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  void _navigateToMyServiceRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyServiceRequestsScreen(),
      ),
    );
  }

  Future<List<JobRequest>> _loadUserServiceRequests(String userId) async {
    try {
      final firestoreService = FirebaseFirestoreService();
      final requestsData = await firestoreService.getJobRequestsForCustomer(userId);
      return requestsData.map((data) => JobRequest.fromMap(data, data['id'])).toList();
    } catch (e) {
      print('Error loading user service requests: $e');
      return [];
    }
  }

  Future<List<JobRequestWithEstimate>> _loadUserServiceRequestsWithEstimates(String userId) async {
    try {
      final firestoreService = FirebaseFirestoreService();
      
      // Load job requests and estimates in parallel for better performance
      final futures = await Future.wait([
        firestoreService.getJobRequestsForCustomer(userId),
        firestoreService.getAllEstimatesForOwner(userId),
      ]);
      
      final jobRequests = futures[0] as List<JobRequest>;
      final estimatesData = futures[1] as List<Map<String, dynamic>>;
      
      // Create a map of requestId -> estimate status for quick lookup
      final estimateStatusMap = <String, EstimateStatus>{};
      final estimateIdMap = <String, String>{};
      
      for (final estimateData in estimatesData) {
        final requestId = estimateData['requestId'] as String?;
        if (requestId != null) {
          final statusString = estimateData['status'] as String;
          final status = _parseEstimateStatus(statusString);
          estimateStatusMap[requestId] = status;
          estimateIdMap[requestId] = estimateData['id'] as String;
        }
      }
      
      // Combine job requests with their estimate status
      final result = jobRequests.map((jobRequest) {
        final estimateStatus = estimateStatusMap[jobRequest.id];
        final estimateId = estimateIdMap[jobRequest.id];
        
        return JobRequestWithEstimate(
          jobRequest: jobRequest,
          estimateStatus: estimateStatus,
          estimateId: estimateId,
        );
      }).toList();
      
      return result;
    } catch (e) {
      print('Error loading user service requests with estimates: $e');
      return [];
    }
  }

  Future<List<Estimate>> _loadUserEstimates(String userId) async {
    try {
      print('🔍 [Customer Dashboard] Loading estimates for user: $userId');
      final firestoreService = FirebaseFirestoreService();
      final estimatesData = await firestoreService.getAllEstimatesForOwner(userId);
      print('🔍 [Customer Dashboard] Raw estimates data: $estimatesData');
      
      final estimates = <Estimate>[];
      for (final estimateData in estimatesData) {
        print('🔍 [Customer Dashboard] Processing estimate: ${estimateData['id']}');
        final estimate = Estimate(
          id: estimateData['id'] as String,
          reportId: estimateData['reportId'] as String? ?? '',
          jobRequestId: estimateData['requestId'] as String? ?? estimateData['jobRequestId'] as String?,
          ownerId: estimateData['customerId'] as String? ?? estimateData['ownerId'] as String? ?? '',
          repairProfessionalId: estimateData['professionalId'] as String,
          repairProfessionalEmail: estimateData['professionalEmail'] as String,
          repairProfessionalBio: estimateData['professionalBio'] as String?,
          cost: (estimateData['cost'] as num).toDouble(),
          leadTimeDays: estimateData['leadTimeDays'] as int,
          description: estimateData['description'] as String,
          imageUrls: List<String>.from(estimateData['imageUrls'] ?? []),
          status: _parseEstimateStatus(estimateData['status'] as String),
          submittedAt: (estimateData['submittedAt'] as Timestamp).toDate(),
          updatedAt: estimateData['updatedAt'] != null 
              ? (estimateData['updatedAt'] as Timestamp).toDate() 
              : null,
          acceptedAt: estimateData['acceptedAt'] != null 
              ? (estimateData['acceptedAt'] as Timestamp).toDate() 
              : null,
          declinedAt: estimateData['declinedAt'] != null 
              ? (estimateData['declinedAt'] as Timestamp).toDate() 
              : null,
        );
        estimates.add(estimate);
      }
      
      return estimates;
    } catch (e) {
      print('Error loading user estimates: $e');
      return [];
    }
  }



  Color _getRequestStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getRequestStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Icons.pending;
      case JobStatus.inProgress:
        return Icons.work;
      case JobStatus.completed:
        return Icons.check_circle;
      case JobStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getRequestStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatLastMessageTime(DateTime? lastMessageAt) {
    if (lastMessageAt == null) return 'No messages';

    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Estimate status helper methods
  Color _getEstimateStatusColor(EstimateStatus? status) {
    if (status == null) return Colors.orange; // No estimate yet
    
    switch (status) {
      case EstimateStatus.pending:
        return Colors.orange;
      case EstimateStatus.accepted:
        return Colors.green;
      case EstimateStatus.declined:
        return Colors.red;
    }
  }

  IconData _getEstimateStatusIcon(EstimateStatus? status) {
    if (status == null) return Icons.access_time; // No estimate yet
    
    switch (status) {
      case EstimateStatus.pending:
        return Icons.access_time;
      case EstimateStatus.accepted:
        return Icons.check_circle;
      case EstimateStatus.declined:
        return Icons.cancel;
    }
  }

  String _getEstimateStatusText(EstimateStatus? status) {
    if (status == null) return 'No Estimate';
    
    switch (status) {
      case EstimateStatus.pending:
        return 'Estimate Pending';
      case EstimateStatus.accepted:
        return 'Estimate Accepted';
      case EstimateStatus.declined:
        return 'Estimate Declined';
    }
  }

  EstimateStatus _parseEstimateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return EstimateStatus.accepted;
      case 'declined':
        return EstimateStatus.declined;
      case 'pending':
      default:
        return EstimateStatus.pending;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = context.read<FirebaseAuthService>();
                final userState = context.read<UserState>();
                
                await authService.signOut();
                userState.clearUserState();
                
                Navigator.pop(context); // Close dialog first
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                Navigator.pop(context); // Close dialog on error too
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  // Reviews Section
  Widget _buildReviewsSection(BuildContext context, UserState userState) {
    return GlowCard(
      glowColor: Theme.of(context).colorScheme.primary,
      borderRadius: 16,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Reviews you\'ve received from service professionals',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16),
            // This will show a preview of recent reviews
            _buildReviewsPreview(context, userState),
          ],
        ),
      ),
    );
  }

  // Reviews Preview
  Widget _buildReviewsPreview(BuildContext context, UserState userState) {
    return FutureBuilder<List<ProfessionalReview>>(
      future: ReviewService().getCustomerReviews(userState.userId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.star_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You\'ll see reviews from service professionals here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final reviews = snapshot.data!;
        final recentReviews = reviews.take(2).toList();

        return Column(
          children: recentReviews.map((review) => 
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: review.professionalPhotoUrl != null
                        ? NetworkImage(review.professionalPhotoUrl!)
                        : null,
                    child: review.professionalPhotoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.professionalName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: index < review.rating ? Colors.amber[600] : Colors.grey[400],
                            );
                          }),
                        ),
                        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            review.reviewText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        );
      },
    );
  }


}

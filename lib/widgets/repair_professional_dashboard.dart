import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/responsive_utils.dart';
import 'service_request_card.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_firestore_service.dart';
import '../services/chat_service.dart';
import '../screens/service_professional_profile_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/cashout_screen.dart';
import 'profile_avatar.dart';
import 'glow_card.dart';
import 'time_picker_widget.dart';
import 'balances_button.dart';

class RepairProfessionalDashboard extends StatefulWidget {
  const RepairProfessionalDashboard({super.key});

  @override
  State<RepairProfessionalDashboard> createState() => _RepairProfessionalDashboardState();
}

class _RepairProfessionalDashboardState extends State<RepairProfessionalDashboard> {
  int _selectedIndex = 0;
  Set<String> _dismissedRequestIds = {};
  List<Estimate> _cachedEstimates = [];
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    
    // Load dismissed requests from storage
    _loadDismissedRequests();
    
    // Refresh service professional profile to ensure categories are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = Provider.of<UserState>(context, listen: false);
      if (userState.isAuthenticated && userState.userId != null) {
        userState.refreshServiceProfessionalProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Consumer<UserState>(
          builder: (context, userState, child) {
            if (userState.isAuthenticated && userState.userId != null) {
              return CompactBalancesButton(
                professionalId: userState.userId!,
                onPressed: () => _navigateToCashOut(userState.userId!),
              );
            }
            return const SizedBox.shrink();
          },
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
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
            icon: Icon(Icons.work),
            label: 'Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'My Est',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildServiceRequestsTab(context);
      case 1:
        return _buildMyEstimatesTab(context);
      case 2:
        return _buildChatTab(context);
      case 3:
        return _buildMyBookingsTab(context);
      case 4:
        return _buildProfileTab(context);
      default:
        return _buildServiceRequestsTab(context);
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Service Requests';
      case 1:
        return 'My Estimates';
      case 2:
        return 'Chat';
      case 3:
        return 'Bookings';
      case 4:
        return 'Profile';
      default:
        return 'Service Requests';
    }
  }

  Widget _buildServiceRequestsTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isServiceProfessional || userState.userId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Access denied. Please sign in as a service professional.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Current role: ${userState.role?.toString() ?? "Unknown"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Update user role in Firebase
                    final firestoreService = FirebaseFirestoreService();
                    await firestoreService.updateUserRole(userState.userId!, 'service_professional');
                    
                    // Force refresh user state
                    await userState.forceUpdateRoleFromFirebase();
                  },
                  child: const Text('Fix Role (Debug)'),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<JobRequest>>(
          future: _loadServiceRequests(userState),
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
                    Text('Error loading service requests: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
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
                    const SizedBox(height: 16),
                Text(
                      'No service requests available',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                Text(
                      'New requests matching your service categories will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

    return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
      itemBuilder: (context, index) {
                final request = requests[index];
                return ServiceRequestCard(
                  request: request,
          index: index,
          showEstimateInput: true,
                  onEstimateSubmitted: () => _showEstimateDialog(context, request),
                  onDismiss: () => _handleDismissRequest(context, request),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMyEstimatesTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isServiceProfessional || userState.userId == null) {
          return Center(
            child: Text(
              'Access denied. Please sign in as a service professional.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return FutureBuilder<List<Estimate>>(
          future: _loadEstimates(userState),
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
                    Text('Error loading estimates: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
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
                    const SizedBox(height: 16),
            Text(
                      'No estimates submitted yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
            Text(
                      'Your submitted estimates will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
              padding: const EdgeInsets.all(16),
      itemCount: estimates.length,
      itemBuilder: (context, index) {
        final estimate = estimates[index];
    return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(estimate.status),
                      child: Icon(
                        _getStatusIcon(estimate.status),
                      color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Estimate for Request',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('Cost: \$${estimate.cost.toStringAsFixed(2)}'),
                        Text('Lead Time: ${estimate.leadTimeDisplay}'),
                        Text('Status: ${estimate.status.name}'),
                        Text('Submitted: ${_formatDate(estimate.submittedAt)}'),
                      ],
                    ),
                    trailing: Text(
                      estimate.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(estimate.status),
                          fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isServiceProfessional || userState.userId == null) {
          return Center(
            child: Text(
              'Access denied. Please sign in as a service professional.',
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
                      'Chat conversations will appear here once customers start messaging you about accepted estimates.',
                      textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                                  ),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ProfileAvatar(
                      profilePhotoUrl: chatRoom.customerPhotoUrl,
                      radius: 20,
                      fallbackIcon: Icons.person,
                    ),
                    title: Text(
                      chatRoom.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (chatRoom.lastMessage != null)
                          Text(
                            chatRoom.lastMessage!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                          Text(
                          _formatLastMessageTime(chatRoom.lastMessageAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                              context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: chatRoom.id,
                            otherUserName: chatRoom.customerName,
                            otherUserPhotoUrl: chatRoom.customerPhotoUrl,
                          ),
                        ),
                      );
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

  Widget _buildMyBookingsTab(BuildContext context) {
    return const MyBookingsScreen();
  }

  Widget _buildProfileTab(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (!userState.isServiceProfessional || userState.userId == null) {
          return Center(
            child: Text(
              'Access denied. Please sign in as a service professional.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        // Return the full profile screen directly
        return ServiceProfessionalProfileScreen();
      },
    );
  }

  Future<List<JobRequest>> _loadServiceRequests(UserState userState) async {
    try {
      if (userState.userId == null || userState.serviceCategoryIds.isEmpty) {
        print('🔍 [Dashboard] Cannot load service requests - userId: ${userState.userId}, categories: ${userState.serviceCategoryIds}');
        return [];
      }

      print('🔍 [Dashboard] Loading service requests for categories: ${userState.serviceCategoryIds}');
      final firestoreService = context.read<FirebaseFirestoreService>();
      final requestsData = await firestoreService.getJobRequestsByCategories(userState.serviceCategoryIds);
      final requests = requestsData.map((data) => JobRequest.fromMap(data, data['id'])).toList();
      
      // Load estimates to check which requests already have estimates
      final estimates = await _loadEstimates(userState);
      _cachedEstimates = estimates; // Cache the estimates
      
      // Filter out dismissed requests and requests that already have estimates
      final filteredRequests = requests.where((request) {
        // Skip if dismissed
        if (_dismissedRequestIds.contains(request.id)) {
          print('🔍 [Dashboard] Filtering out dismissed request: ${request.id}');
          return false;
        }
        
        // Skip if already has an estimate from this professional
        final hasEstimate = estimates.any((estimate) {
          final matchesRequest = estimate.jobRequestId == request.id || estimate.reportId == request.id;
          final matchesProfessional = estimate.repairProfessionalId == userState.userId;
          print('🔍 [Dashboard] Checking estimate: jobRequestId=${estimate.jobRequestId}, reportId=${estimate.reportId}, requestId=${request.id}, professionalId=${estimate.repairProfessionalId}, matchesRequest=$matchesRequest, matchesProfessional=$matchesProfessional');
          return matchesRequest && matchesProfessional;
        });
        
        if (hasEstimate) {
          print('🔍 [Dashboard] Filtering out request with existing estimate: ${request.id}');
        }
        
        return !hasEstimate;
      }).toList();
      
      print('🔍 [Dashboard] Found ${requests.length} service requests, ${filteredRequests.length} after filtering');
      print('🔍 [Dashboard] Dismissed requests: $_dismissedRequestIds');
      print('🔍 [Dashboard] Estimates found: ${estimates.length}');
      for (final estimate in estimates) {
        print('🔍 [Dashboard] Estimate for request: jobRequestId=${estimate.jobRequestId}, reportId=${estimate.reportId}, professional: ${estimate.repairProfessionalId}');
      }
      
      return filteredRequests;
    } catch (e) {
      print('❌ [Dashboard] Error loading service requests: $e');
      return [];
    }
  }

  Future<List<Estimate>> _loadEstimates(UserState userState) async {
    try {
      if (userState.userId == null) {
        print('🔍 [Dashboard] Cannot load estimates - userId is null');
        return [];
      }

      print('🔍 [Dashboard] Loading estimates for professional: ${userState.userId}');
      final firestoreService = context.read<FirebaseFirestoreService>();
      final estimatesData = await firestoreService.getAllEstimatesForProfessional(userState.userId!);
      
      final estimates = <Estimate>[];
      for (final estimateData in estimatesData) {
        final estimate = Estimate(
          id: estimateData['id'] as String,
          reportId: estimateData['reportId'] as String? ?? '',
          jobRequestId: estimateData['jobRequestId'] as String? ?? estimateData['requestId'] as String?,
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
      
      print('🔍 [Dashboard] Found ${estimates.length} estimates');
      return estimates;
    } catch (e) {
      print('❌ [Dashboard] Error loading estimates: $e');
      return [];
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

  void _showEstimateDialog(BuildContext context, JobRequest request) {
    final TextEditingController costController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    // Time picker state
    int selectedDays = 0;
    int selectedHours = 0;
    int selectedMinutes = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Submit Estimate for ${request.title}'),
          content: SizedBox(
            width: 400,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Submit an estimate for: ${request.title}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: costController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Cost (\$)',
                      hintText: 'Enter your estimate',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Lead Time Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lead Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Time Picker Widget
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TimePickerWidget(
                      initialDays: selectedDays,
                      initialHours: selectedHours,
                      initialMinutes: selectedMinutes,
                      onTimeChanged: (days, hours, minutes) {
                        setState(() {
                          selectedDays = days;
                          selectedHours = hours;
                          selectedMinutes = minutes;
                        });
                      },
                      height: 200,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Service Description',
                      hintText: 'Describe the service work in detail',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
              final userState = context.read<UserState>();
              final firestoreService = context.read<FirebaseFirestoreService>();

              if (userState.userId == null || userState.email == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not authenticated.')),
                );
                return;
              }

              final cost = double.tryParse(costController.text);
              final description = descriptionController.text.trim();
              
              // Convert time picker values to total minutes
              final totalMinutes = TimeHelper.toTotalMinutes(selectedDays, selectedHours, selectedMinutes);

              if (cost == null || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all estimate fields correctly.')),
                );
                return;
              }

              if (totalMinutes == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a lead time.')),
                  );
                  return;
                }

                try {
                await firestoreService.createEstimateForServiceRequest(
                  jobRequestId: request.id,
                  professionalId: userState.userId!,
                  professionalEmail: userState.email ?? '',
                  professionalBio: userState.bio ?? '',
                  cost: cost,
                  leadTimeDays: totalMinutes, // Store as total minutes
                  description: description,
                );

                // Update the job request status to 'inProgress'
                // await firestoreService.updateJobRequestStatus(request.id, JobStatus.inProgress);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Estimate submitted successfully!')),
                  );
                  Navigator.pop(context);
                  
                  // Clear cached estimates to force reload
                  _cachedEstimates.clear();
                  
                  // Refresh the list
                  setState(() {});
                  }
                } catch (e) {
                print('❌ Error submitting estimate: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit estimate: $e')),
                    );
                  }
                }
              },
            child: const Text('Submit Estimate'),
          ),
        ],
      ),
    ));
  }

  void _navigateToCashOut(String professionalId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashOutScreen(
          professionalId: professionalId,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
                final authService = context.read<FirebaseAuthService>();
                await authService.signOut();
                if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Logout'),
              ),
            ],
                    ),
                  );
                }

  Color _getStatusColor(EstimateStatus status) {
    switch (status) {
      case EstimateStatus.pending:
        return Colors.orange;
      case EstimateStatus.accepted:
        return Colors.green;
      case EstimateStatus.declined:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(EstimateStatus status) {
    switch (status) {
      case EstimateStatus.pending:
        return Icons.pending;
      case EstimateStatus.accepted:
        return Icons.check;
      case EstimateStatus.declined:
        return Icons.close;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleDismissRequest(BuildContext context, JobRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dismiss Request'),
          content: Text('Are you sure you want to dismiss "${request.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _dismissedRequestIds.add(request.id);
                  print('🔍 [Dashboard] Added to dismissed requests: ${request.id}, total dismissed: ${_dismissedRequestIds.length}');
                });
                _saveDismissedRequests();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request "${request.title}" dismissed'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Dismiss'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadDismissedRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = userState.userId;
      
      if (userId != null) {
        final dismissedKey = 'dismissed_requests_$userId';
        final dismissedList = prefs.getStringList(dismissedKey) ?? [];
        _dismissedRequestIds = dismissedList.toSet();
        print('🔍 [Dashboard] Loaded ${_dismissedRequestIds.length} dismissed requests for user $userId');
      }
    } catch (e) {
      print('❌ [Dashboard] Error loading dismissed requests: $e');
    }
  }

  Future<void> _saveDismissedRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = userState.userId;
      
      if (userId != null) {
        final dismissedKey = 'dismissed_requests_$userId';
        await prefs.setStringList(dismissedKey, _dismissedRequestIds.toList());
        print('🔍 [Dashboard] Saved ${_dismissedRequestIds.length} dismissed requests for user $userId');
      }
    } catch (e) {
      print('❌ [Dashboard] Error saving dismissed requests: $e');
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
}
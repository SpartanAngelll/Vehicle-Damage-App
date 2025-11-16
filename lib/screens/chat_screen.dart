import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../models/booking_models.dart';
import '../models/job_request.dart';
import '../models/damage_report.dart';
import '../services/chat_service.dart';
import '../services/openai_service.dart';
import '../services/firebase_firestore_service.dart';
import '../services/device_cache_service.dart';
import '../services/content_filter_service.dart';
import '../models/user_state.dart';
import '../widgets/booking_confirmation_dialog.dart';
import '../widgets/service_request_details_dialog.dart';
import '../widgets/estimate_details_dialog.dart';
import '../widgets/content_filter_warning_dialog.dart';
import '../widgets/web_layout.dart';
import '../widgets/profile_avatar.dart';
import 'booking_summary_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final OpenAIService _openAIService = OpenAIService();
  final DeviceCacheService _cacheService = DeviceCacheService();
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final ContentFilterService _contentFilter = ContentFilterService();
  
  bool _isGeneratingBooking = false;
  List<ChatMessage> _messages = [];
  ChatRoom? _chatRoom;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final userState = context.read<UserState>();
    if (userState.userId == null || userState.email == null) return;

    // Check content for violations
    final filterResult = _contentFilter.filterContent(content);
    
    if (filterResult.hasViolations) {
      // Show warning dialog
      final shouldProceed = await ContentFilterWarningDialog.show(
        context,
        detectedPatterns: filterResult.detectedPatterns,
      );
      
      if (shouldProceed != true) {
        // User chose to edit the message, don't send
        return;
      }
    }

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: userState.userId!,
        senderName: userState.fullName ?? userState.email!.split('@')[0], // Use fullName or email prefix
        content: content,
        senderPhotoUrl: userState.profilePhotoUrl, // Use profilePhotoUrl from UserState
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future<void> _showServiceRequestDetails() async {
    try {
      final chatRoom = await _chatService.getChatRoom(widget.chatRoomId);
      if (chatRoom == null) {
        print('❌ [Chat] Chat room not found: ${widget.chatRoomId}');
        return;
      }

      print('🔍 [Chat] Loading estimate: ${chatRoom.estimateId}');
      final estimate = await _loadEstimateFromCache(chatRoom.estimateId);
      if (estimate == null) {
        print('❌ [Chat] Estimate not found: ${chatRoom.estimateId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estimate not found')),
          );
        }
        return;
      }

      print('🔍 [Chat] Estimate found - jobRequestId: ${estimate.jobRequestId}, reportId: ${estimate.reportId}');
      
      // Try to load service request - check both jobRequestId and reportId
      JobRequest? serviceRequest;
      String? requestId;
      
      if (estimate.jobRequestId != null && estimate.jobRequestId!.isNotEmpty) {
        requestId = estimate.jobRequestId;
        print('🔍 [Chat] Loading job request: $requestId');
        serviceRequest = await _loadServiceRequestFromCache(requestId);
      } else if (estimate.reportId != null && estimate.reportId!.isNotEmpty) {
        // For damage reports, we need to convert them to a JobRequest format
        requestId = estimate.reportId;
        print('🔍 [Chat] Loading damage report as service request: $requestId');
        serviceRequest = await _loadDamageReportAsServiceRequest(requestId);
      } else {
        // No linked service request or damage report - create a generic service request from estimate
        print('🔍 [Chat] No linked service request found, creating generic service request from estimate');
        serviceRequest = await _createServiceRequestFromEstimate(estimate);
      }
      
      if (serviceRequest != null && mounted) {
        print('✅ [Chat] Service request loaded successfully');
        showDialog(
          context: context,
          builder: (context) => ServiceRequestDetailsDialog(request: serviceRequest!),
        );
      } else {
        print('❌ [Chat] Service request not found for ID: $requestId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service request not found')),
          );
        }
      }
    } catch (e) {
      print('❌ [Chat] Error loading service request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load service request: $e')),
        );
      }
    }
  }

  Future<void> _showEstimateDetails() async {
    try {
      final chatRoom = await _chatService.getChatRoom(widget.chatRoomId);
      if (chatRoom == null) return;

      // Load estimate from cache or Firebase
      final estimate = await _loadEstimateFromCache(chatRoom.estimateId);
      
      if (estimate != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => EstimateDetailsDialog(estimate: estimate),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estimate not found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load estimate: $e')),
        );
      }
    }
  }

  Future<JobRequest?> _loadServiceRequestFromCache(String? jobRequestId) async {
    if (jobRequestId == null || jobRequestId.isEmpty) return null;
    
    try {
      // Try to load from device cache first
      final cachedRequest = await _loadServiceRequestFromDeviceCache(jobRequestId);
      if (cachedRequest != null) {
        print('🔍 [Chat] Loaded service request from device cache: $jobRequestId');
        return cachedRequest;
      }
      
      // Fallback to Firebase
      print('🔍 [Chat] Loading service request from Firebase: $jobRequestId');
      final firestoreService = FirebaseFirestoreService();
      final requestData = await firestoreService.getJobRequest(jobRequestId);
      
      if (requestData != null) {
        // Cache for future use
        await _cacheServiceRequestToDevice(requestData);
        return JobRequest.fromMap(requestData, jobRequestId);
      }
      
      return null;
    } catch (e) {
      print('❌ [Chat] Error loading service request: $e');
      return null;
    }
  }

  Future<Estimate?> _loadEstimateFromCache(String? estimateId) async {
    if (estimateId == null || estimateId.isEmpty) {
      print('❌ [Chat] Estimate ID is null or empty');
      return null;
    }
    
    try {
      // Try to load from device cache first
      final cachedEstimate = await _loadEstimateFromDeviceCache(estimateId);
      if (cachedEstimate != null) {
        print('🔍 [Chat] Loaded estimate from device cache: $estimateId');
        return cachedEstimate;
      }
      
      // Fallback to Firebase
      print('🔍 [Chat] Loading estimate from Firebase: $estimateId');
      final firestoreService = FirebaseFirestoreService();
      final estimateData = await firestoreService.getEstimate(estimateId);
      
      if (estimateData != null) {
        print('✅ [Chat] Estimate data loaded from Firebase: ${estimateData.keys}');
        print('🔍 [Chat] Estimate data values: ${estimateData.toString()}');
        // Cache for future use
        await _cacheEstimateToDevice(estimateData);
        final estimate = Estimate.fromMap(estimateData, estimateId);
        print('🔍 [Chat] Estimate created - jobRequestId: ${estimate.jobRequestId}, reportId: ${estimate.reportId}');
        return estimate;
      } else {
        print('❌ [Chat] No estimate data found in Firebase for ID: $estimateId');
      }
      
      return null;
    } catch (e) {
      print('❌ [Chat] Error loading estimate: $e');
      return null;
    }
  }

  // Device cache methods using DeviceCacheService
  Future<JobRequest?> _loadServiceRequestFromDeviceCache(String jobRequestId) async {
    return await _cacheService.getCachedServiceRequest(jobRequestId);
  }

  Future<void> _cacheServiceRequestToDevice(Map<String, dynamic> requestData) async {
    final request = JobRequest.fromMap(requestData, requestData['id'] ?? '');
    await _cacheService.cacheServiceRequest(request);
  }

  Future<Estimate?> _loadEstimateFromDeviceCache(String estimateId) async {
    return await _cacheService.getCachedEstimate(estimateId);
  }

  Future<void> _cacheEstimateToDevice(Map<String, dynamic> estimateData) async {
    final estimate = Estimate.fromMap(estimateData, estimateData['id'] ?? '');
    await _cacheService.cacheEstimate(estimate);
  }

  Future<JobRequest?> _loadDamageReportAsServiceRequest(String reportId) async {
    try {
      print('🔍 [Chat] Converting damage report to service request: $reportId');
      
      // Load damage report from Firebase
      final firestoreService = FirebaseFirestoreService();
      final reportData = await firestoreService.getDamageReport(reportId);
      
      if (reportData != null) {
        // Convert damage report to JobRequest format
        final jobRequest = JobRequest(
          id: reportId,
          customerId: reportData['ownerId'] ?? 'unknown',
          customerEmail: 'customer@example.com', // Default email since damage reports don't have email
          title: 'Vehicle Repair - ${reportData['vehicleMake']} ${reportData['vehicleModel']}',
          description: reportData['damageDescription'] ?? 'Vehicle damage repair',
          categoryIds: ['vehicle_repair'], // Default category
          imageUrls: List<String>.from(reportData['imageUrls'] ?? []),
          priority: JobPriority.medium, // Default priority
          estimatedBudget: (reportData['estimatedCost'] as num?)?.toDouble(),
          location: 'To be confirmed',
          customFields: {
            'vehicleMake': reportData['vehicleMake'],
            'vehicleModel': reportData['vehicleModel'],
            'vehicleYear': reportData['vehicleYear'],
            'additionalNotes': reportData['additionalNotes'],
          },
        );
        
        print('✅ [Chat] Successfully converted damage report to service request');
        return jobRequest;
      }
      
      return null;
    } catch (e) {
      print('❌ [Chat] Error converting damage report to service request: $e');
      return null;
    }
  }

  Future<JobRequest?> _createServiceRequestFromEstimate(Estimate estimate) async {
    try {
      print('🔍 [Chat] Creating service request from estimate: ${estimate.id}');
      
      // Create a generic service request from estimate data
      print('🔍 [Chat] Estimate imageUrls: ${estimate.imageUrls}');
      print('🔍 [Chat] Estimate imageUrls length: ${estimate.imageUrls.length}');
      
      final jobRequest = JobRequest(
        id: 'estimate_${estimate.id}',
        customerId: estimate.ownerId,
        customerEmail: 'customer@example.com', // Default email
        title: 'Service Request - ${estimate.description}',
        description: estimate.description,
        categoryIds: ['general_service'], // Default category
        imageUrls: estimate.imageUrls,
        priority: JobPriority.medium, // Default priority
        estimatedBudget: estimate.cost,
        location: 'To be confirmed',
        customFields: {
          'estimateId': estimate.id,
          'professionalEmail': estimate.repairProfessionalEmail,
          'leadTimeDays': estimate.leadTimeDays,
          'status': estimate.status.name,
          'submittedAt': estimate.submittedAt.toIso8601String(),
          'professionalBio': estimate.repairProfessionalBio,
        },
      );
      
      print('🔍 [Chat] JobRequest imageUrls: ${jobRequest.imageUrls}');
      print('🔍 [Chat] JobRequest imageUrls length: ${jobRequest.imageUrls.length}');
      
      print('✅ [Chat] Successfully created service request from estimate');
      return jobRequest;
    } catch (e) {
      print('❌ [Chat] Error creating service request from estimate: $e');
      return null;
    }
  }

  Future<void> _generateBooking() async {
    if (_messages.isEmpty || _isGeneratingBooking) return;

    setState(() {
      _isGeneratingBooking = true;
    });

    try {
      final userState = context.read<UserState>();
      final chatRoom = await _chatService.getChatRoom(widget.chatRoomId);
      
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      // Load estimate data for better AI analysis
      final estimate = await _loadEstimateFromCache(chatRoom.estimateId);
      final estimateData = estimate?.toMap();

      // Analyze conversation with OpenAI (with estimate context)
      final jobSummary = await _openAIService.analyzeConversation(
        messages: _messages,
        estimateId: chatRoom.estimateId,
        chatRoomId: widget.chatRoomId,
        customerId: chatRoom.customerId,
        professionalId: chatRoom.professionalId,
        originalEstimate: estimate?.description ?? 'Service Request',
        estimateData: estimateData,
      );

      if (mounted) {
        // Show booking confirmation dialog
        final confirmed = await showDialog<JobSummary>(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (context) => BookingConfirmationDialog(
            key: const ValueKey('booking_confirmation_dialog'),
            jobSummary: jobSummary,
            chatRoom: chatRoom,
          ),
        );

        if (confirmed != null) {
          // Create the booking with confirmed details
          final confirmedSummary = confirmed;
          
          final booking = await _chatService.createBookingFromSummary(
            summary: confirmedSummary,
            serviceTitle: confirmedSummary.rawAnalysis?['service'] ?? 'Service Request',
            serviceDescription: confirmedSummary.conversationSummary,
            location: confirmedSummary.extractedLocation ?? 'To be confirmed',
          );

          if (mounted) {
            // Navigate to booking summary screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookingSummaryScreen(
                  jobSummary: confirmedSummary,
                  chatRoom: chatRoom,
                  bookingId: booking.id,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final chatBody = Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _chatService.getMessagesStream(widget.chatRoomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final messages = snapshot.data ?? [];
              _messages = messages;

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'Start the conversation!\nDiscuss job details, schedule, and requirements.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isWeb 
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Colors.white70,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message);
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );

    // On web, use web layout wrapper
    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      final maxChatWidth = (screenWidth > 1400 ? 1000.0 : 900.0);
      
      return WebLayout(
        currentRoute: '/chat',
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxChatWidth),
            child: Column(
              children: [
                // Chat header with actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        profilePhotoUrl: widget.otherUserPhotoUrl,
                        radius: 20,
                        fallbackIcon: Icons.person,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otherUserName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Discuss job details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        onPressed: () => _showServiceRequestDetails(),
                        tooltip: 'View Service Request',
                      ),
                      IconButton(
                        icon: const Icon(Icons.work_outline),
                        onPressed: () => _showEstimateDetails(),
                        tooltip: 'View Estimate',
                      ),
                      IconButton(
                        icon: _isGeneratingBooking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        onPressed: _isGeneratingBooking ? null : _generateBooking,
                        tooltip: 'Generate Booking',
                      ),
                    ],
                  ),
                ),
                // Chat messages
                Expanded(child: chatBody),
              ],
            ),
          ),
        ),
      );
    }

    // On mobile, use original layout
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ProfileAvatar(
              profilePhotoUrl: widget.otherUserPhotoUrl,
              radius: 16,
              fallbackIcon: Icons.person,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Discuss job details',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showServiceRequestDetails(),
            tooltip: 'View Service Request',
          ),
          IconButton(
            icon: const Icon(Icons.work_outline),
            onPressed: () => _showEstimateDetails(),
            tooltip: 'View Estimate',
          ),
          IconButton(
            icon: _isGeneratingBooking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _isGeneratingBooking ? null : _generateBooking,
            tooltip: 'Generate Booking',
          ),
        ],
      ),
      body: chatBody,
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final userState = context.read<UserState>();
    final isMe = message.senderId == userState.userId;
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            ProfileAvatar(
              profilePhotoUrl: message.senderPhotoUrl,
              radius: 16,
              fallbackIcon: Icons.person,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[800],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            ProfileAvatar(
              profilePhotoUrl: userState.profilePhotoUrl,
              radius: 16,
              fallbackIcon: Icons.person,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _sendMessage,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

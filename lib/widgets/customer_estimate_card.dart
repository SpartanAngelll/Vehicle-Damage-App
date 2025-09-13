import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/chat_models.dart';
import '../services/services.dart';
import '../services/firebase_firestore_service.dart';
import '../services/chat_service.dart';
import '../screens/service_professional_profile_screen.dart';
import '../screens/chat_screen.dart';
import 'glow_card.dart';

class CustomerEstimateCard extends StatefulWidget {
  final Estimate estimate;
  final VoidCallback? onStatusChanged;

  const CustomerEstimateCard({
    super.key,
    required this.estimate,
    this.onStatusChanged,
  });

  @override
  State<CustomerEstimateCard> createState() => _CustomerEstimateCardState();
}

class _CustomerEstimateCardState extends State<CustomerEstimateCard> {
  ServiceProfessional? _professional;
  JobRequest? _serviceRequest;
  bool _isLoading = false;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _loadProfessionalAndRequestDetails();
  }

  Future<void> _loadProfessionalAndRequestDetails() async {
    try {
      final firestoreService = FirebaseFirestoreService();
      
      // Load professional details
      _professional = await firestoreService.getServiceProfessional(widget.estimate.repairProfessionalId);

      // Load service request details if we have a jobRequestId
      if (widget.estimate.jobRequestId != null) {
        final requestData = await firestoreService.getJobRequest(widget.estimate.jobRequestId!);
        if (requestData != null) {
          _serviceRequest = JobRequest.fromMap(requestData, widget.estimate.jobRequestId!);
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading professional and request details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return EstimateCard(
      glowColor: _getStatusColor(),
      onTap: _professional != null ? _showProfessionalProfile : null,
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with professional info
              Row(
                children: [
                  // Professional profile photo
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: _professional?.profilePhotoUrl != null
                        ? NetworkImage(_professional!.profilePhotoUrl!)
                        : null,
                    child: _professional?.profilePhotoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 30,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  SizedBox(width: 12),
                  
                  // Professional name and business
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getProfessionalDisplayName(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_professional?.businessName != null) ...[
                          SizedBox(height: 2),
                          Text(
                            _professional!.businessName!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _professional?.averageRating.toStringAsFixed(1) ?? 'N/A',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${_professional?.totalReviews ?? 0} reviews)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.estimate.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Service request details
              if (_serviceRequest != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Request:',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _serviceRequest!.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _serviceRequest!.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Estimate details - Cost, Lead Time, and Submitted horizontally
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Cost',
                      '\$${widget.estimate.cost.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Lead Time',
                      widget.estimate.leadTimeDisplay,
                      Icons.schedule,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Submitted',
                      _formatDate(widget.estimate.submittedAt),
                      Icons.access_time,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Description button
              _buildDescriptionButton(context),
              
              SizedBox(height: 16),
              
              // Action buttons (only show for pending estimates)
              if (widget.estimate.status == EstimateStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _declineEstimate,
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _acceptEstimate,
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (widget.estimate.status == EstimateStatus.accepted) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Estimate Accepted',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _startChat,
                        icon: Icon(Icons.chat, size: 18),
                        label: Text('Start Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.estimate.status == EstimateStatus.declined) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Estimate Declined',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showDescriptionDialog(context),
        icon: Icon(
          Icons.description,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          'View Description',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8),
            Text('Estimate Description'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            widget.estimate.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollingText(BuildContext context, String text, TextStyle? style) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if text overflows
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);
        
        final isOverflowing = textPainter.didExceedMaxLines;
        
        if (!isOverflowing) {
          // If text fits, just display it normally
          return Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        
        // If text overflows, create scrolling animation
        return _ScrollingText(
          text: text,
          style: style,
          width: constraints.maxWidth,
        );
      },
    );
  }

  String _getProfessionalDisplayName() {
    if (_professional == null) return 'Loading...';
    
    if (_professional!.businessName != null && _professional!.businessName!.isNotEmpty) {
      return _professional!.businessName!;
    }
    
    return _professional!.fullName;
  }

  Color _getStatusColor() {
    switch (widget.estimate.status) {
      case EstimateStatus.pending:
        return Colors.orange;
      case EstimateStatus.accepted:
        return Colors.green;
      case EstimateStatus.declined:
        return Colors.red;
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

  Future<void> _acceptEstimate() async {
    await _updateEstimateStatus(EstimateStatus.accepted);
  }

  Future<void> _declineEstimate() async {
    await _updateEstimateStatus(EstimateStatus.declined);
  }

  Future<void> _updateEstimateStatus(EstimateStatus newStatus) async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = FirebaseFirestoreService();
      
      // Update estimate status
      await firestoreService.updateEstimateStatusWithEnum(
        widget.estimate.id,
        newStatus.name,
      );

      // Update job request status if we have a jobRequestId
      if (widget.estimate.jobRequestId != null && widget.estimate.jobRequestId!.isNotEmpty) {
        final now = DateTime.now();
        await firestoreService.updateJobRequestStatus(
          widget.estimate.jobRequestId!,
          newStatus == EstimateStatus.accepted ? 'accepted' : 'declined',
          additionalData: {
            'acceptedEstimateId': newStatus == EstimateStatus.accepted ? widget.estimate.id : null,
            'acceptedAt': newStatus == EstimateStatus.accepted ? now : null,
            'declinedAt': newStatus == EstimateStatus.declined ? now : null,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == EstimateStatus.accepted 
                  ? 'Estimate accepted successfully!' 
                  : 'Estimate declined successfully!',
            ),
            backgroundColor: newStatus == EstimateStatus.accepted ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Notify parent widget to refresh
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating estimate: ${e.toString()}'),
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

  void _showProfessionalProfile() {
    if (_professional == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: ServiceProfessionalProfileScreen(
            professionalId: _professional!.id,
          ),
        ),
      ),
    );
  }

  Future<void> _startChat() async {
    if (_professional == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if chat room already exists
      ChatRoom? existingChatRoom = await _chatService.getChatRoomByEstimateId(widget.estimate.id);
      
      if (existingChatRoom != null) {
        // Navigate to existing chat
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatRoomId: existingChatRoom.id,
                otherUserName: _professional!.fullName,
                otherUserPhotoUrl: _professional!.profilePhotoUrl,
              ),
            ),
          );
        }
      } else {
        // Create new chat room
        final chatRoom = await _chatService.createChatRoom(
          estimateId: widget.estimate.id,
          customerId: widget.estimate.ownerId,
          professionalId: widget.estimate.repairProfessionalId,
          customerName: 'Customer', // This should come from user state
          professionalName: _professional!.fullName,
          customerPhotoUrl: null, // This should come from user state
          professionalPhotoUrl: _professional!.profilePhotoUrl,
        );

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatRoomId: chatRoom.id,
                otherUserName: _professional!.fullName,
                otherUserPhotoUrl: _professional!.profilePhotoUrl,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
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
}

class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double width;

  const _ScrollingText({
    required this.text,
    required this.style,
    required this.width,
  });

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _textWidth = 0;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Calculate text width
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTextWidth();
    });
  }

  void _calculateTextWidth() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    _textWidth = textPainter.width;
    
    if (_textWidth > widget.width) {
      setState(() {
        _isScrolling = true;
      });
      _startScrolling();
    }
  }

  void _startScrolling() {
    if (!_isScrolling) return;
    
    // Calculate how much we need to scroll
    final scrollDistance = _textWidth - widget.width + 20; // Add some padding
    
    _animation = Tween<double>(
      begin: 0,
      end: -scrollDistance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isScrolling) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRect(
          child: Transform.translate(
            offset: Offset(_animation.value, 0),
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
            ),
          ),
        );
      },
    );
  }
}

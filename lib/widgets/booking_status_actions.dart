import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_models.dart';
import '../models/service.dart';
import '../models/review_models.dart';
import '../models/user_state.dart';
import '../services/firebase_firestore_service.dart';
import '../services/review_service.dart';
import '../widgets/review_submission_dialog.dart';

class BookingStatusActions extends StatefulWidget {
  final Booking booking;
  final bool isServiceProfessional;
  final VoidCallback? onStatusUpdated;

  const BookingStatusActions({
    super.key,
    required this.booking,
    required this.isServiceProfessional,
    this.onStatusUpdated,
  });

  @override
  State<BookingStatusActions> createState() => _BookingStatusActionsState();
}

class _BookingStatusActionsState extends State<BookingStatusActions> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status indicator
        _buildStatusIndicator(),
        const SizedBox(height: 16),
        
        // Action buttons based on status and user type
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_getStatusTimestamp() != null)
                Text(
                  _formatTimestamp(_getStatusTimestamp()!),
                  style: TextStyle(
                    color: _getStatusColor().withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          // Travel responsibility indicator
          if (widget.booking.finalTravelMode != null) ...[
            const SizedBox(height: 8),
            _buildTravelResponsibilityIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelResponsibilityIndicator() {
    final travelMode = widget.booking.finalTravelMode!;
    final isProfessional = widget.isServiceProfessional;
    
    String responsibilityText;
    IconData responsibilityIcon;
    Color responsibilityColor;
    
    switch (travelMode) {
      case TravelMode.customerTravels:
        responsibilityText = isProfessional 
            ? 'Awaiting Customer' 
            : 'You travel to shop';
        responsibilityIcon = isProfessional 
            ? Icons.schedule 
            : Icons.directions_car;
        responsibilityColor = isProfessional 
            ? Colors.orange 
            : Colors.blue;
        break;
      case TravelMode.proTravels:
        responsibilityText = isProfessional 
            ? 'You travel to customer' 
            : 'Pro travels to you';
        responsibilityIcon = isProfessional 
            ? Icons.directions_car 
            : Icons.schedule;
        responsibilityColor = isProfessional 
            ? Colors.green 
            : Colors.orange;
        break;
      case TravelMode.remote:
        responsibilityText = 'Remote service';
        responsibilityIcon = Icons.video_call;
        responsibilityColor = Colors.purple;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: responsibilityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            responsibilityIcon,
            color: responsibilityColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            responsibilityText,
            style: TextStyle(
              color: responsibilityColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final actions = _getAvailableActions();
    
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: actions.map((action) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleAction(action),
            icon: Icon(action.icon),
            label: Text(action.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      )).toList(),
    );
  }

  List<BookingAction> _getAvailableActions() {
    final actions = <BookingAction>[];
    final status = widget.booking.status;
    final isProfessional = widget.isServiceProfessional;
    final travelMode = widget.booking.finalTravelMode;

    switch (status) {
      case BookingStatus.confirmed:
        // Handle "On My Way" based on travel mode
        if (_shouldShowOnMyWayAction()) {
          actions.add(BookingAction(
            label: 'Mark On My Way',
            icon: Icons.directions_car,
            color: Colors.blue,
            action: BookingActionType.markOnMyWay,
          ));
        }
        break;
        
      case BookingStatus.inProgress:
        if (isProfessional) {
          actions.add(BookingAction(
            label: 'Mark Job Started',
            icon: Icons.play_arrow,
            color: Colors.green,
            action: BookingActionType.markJobStarted,
          ));
        } else {
          actions.add(BookingAction(
            label: 'Mark Job Completed',
            icon: Icons.check_circle,
            color: Colors.orange,
            action: BookingActionType.markJobCompleted,
          ));
        }
        break;
        
      case BookingStatus.completed:
        if (!isProfessional) {
          actions.add(BookingAction(
            label: 'Accept Job as Completed',
            icon: Icons.thumb_up,
            color: Colors.green,
            action: BookingActionType.acceptJobCompleted,
          ));
        } else {
          // Add review customer action for professionals
          actions.add(BookingAction(
            label: 'Rate Customer',
            icon: Icons.star_rate,
            color: Colors.amber,
            action: BookingActionType.rateCustomer,
          ));
        }
        break;
        
      case BookingStatus.reviewed:
        // Allow review actions even for reviewed bookings
        if (!isProfessional) {
          // Customer can still rate professional if they haven't
          actions.add(BookingAction(
            label: 'Rate Professional',
            icon: Icons.star_rate,
            color: Colors.amber,
            action: BookingActionType.rateProfessional,
          ));
        } else {
          // Professional can still rate customer if they haven't
          actions.add(BookingAction(
            label: 'Rate Customer',
            icon: Icons.star_rate,
            color: Colors.amber,
            action: BookingActionType.rateCustomer,
          ));
        }
        break;
        
      default:
        break;
    }

    return actions;
  }

  bool _shouldShowOnMyWayAction() {
    final isProfessional = widget.isServiceProfessional;
    final travelMode = widget.booking.finalTravelMode;
    
    // For remote services, skip travel steps
    if (travelMode == TravelMode.remote) {
      return false;
    }
    
    // Professional shows "On My Way" if they travel to customer
    if (isProfessional && travelMode == TravelMode.proTravels) {
      return true;
    }
    
    // Customer shows "On My Way" if they travel to shop
    if (!isProfessional && travelMode == TravelMode.customerTravels) {
      return true;
    }
    
    return false;
  }

  Future<void> _handleAction(BookingAction action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      switch (action.action) {
        case BookingActionType.markOnMyWay:
          await _firestoreService.markProfessionalOnWay(widget.booking.id);
          break;
          
        case BookingActionType.markJobStarted:
          await _showPinDialog();
          break;
          
        case BookingActionType.markJobCompleted:
          await _showCompletionDialog();
          break;
          
        case BookingActionType.acceptJobCompleted:
          print('🔍 [BookingStatusActions] Accept Job Completed action triggered');
          await _firestoreService.acceptJobAsCompleted(widget.booking.id);
          print('🔍 [BookingStatusActions] Job accepted as completed, showing review prompt');
          // Show review prompt after accepting job as completed
          await _showReviewPrompt();
          break;
          
        case BookingActionType.rateCustomer:
          await _showCustomerReviewPrompt();
          break;
          
        case BookingActionType.rateProfessional:
          await _showReviewPrompt();
          break;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.label} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action.label.toLowerCase()}: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  Future<void> _showPinDialog() async {
    final pinController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Customer PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the customer PIN to start the job:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'Customer PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _firestoreService.markJobStarted(
                    widget.booking.id, 
                    pinController.text,
                  );
                }
              },
              child: const Text('Start Job'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCompletionDialog() async {
    final notesController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark Job as Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add any notes about the completed work (optional):'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                print('🔍 [BookingStatusActions] Mark Completed button pressed');
                Navigator.of(context).pop();
                await _firestoreService.markJobCompleted(
                  widget.booking.id,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                
                print('🔍 [BookingStatusActions] Job marked as completed, showing review prompt');
                // Show review prompt after marking as completed
                await _showReviewPrompt();
              },
              child: const Text('Mark Completed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReviewPrompt() async {
    print('🔍 [BookingStatusActions] _showReviewPrompt called');
    final userState = Provider.of<UserState>(context, listen: false);
    final reviewService = ReviewService();
    
    if (userState.userId == null) {
      print('❌ [BookingStatusActions] UserState.userId is null');
      return;
    }

    print('🔍 [BookingStatusActions] Checking if customer has already reviewed booking: ${widget.booking.id}');
    
    // Check if customer has already reviewed this booking
    final hasReviewed = await reviewService.hasCustomerReviewedBooking(
      widget.booking.id,
      userState.userId!,
    );

    if (hasReviewed) {
      print('ℹ️ [BookingStatusActions] Customer has already reviewed this booking');
      return;
    }

    print('🔍 [BookingStatusActions] Showing review dialog for booking: ${widget.booking.id}');
    
    // Show review dialog for customer to rate professional
    await ReviewSubmissionDialog.show(
      context,
      bookingId: widget.booking.id,
      reviewerId: userState.userId!,
      reviewerName: userState.fullName ?? userState.email!.split('@')[0],
      reviewerPhotoUrl: userState.profilePhotoUrl,
      revieweeId: widget.booking.professionalId,
      revieweeName: widget.booking.professionalName,
      reviewType: ReviewType.customerToProfessional,
      onReviewSubmitted: () {
        print('✅ [BookingStatusActions] Review submitted successfully');
        widget.onStatusUpdated?.call();
      },
    );
  }

  Future<void> _showCustomerReviewPrompt() async {
    final userState = Provider.of<UserState>(context, listen: false);
    final reviewService = ReviewService();
    
    if (userState.userId == null) return;

    // Check if professional has already reviewed this booking
    final hasReviewed = await reviewService.hasProfessionalReviewedBooking(
      widget.booking.id,
      userState.userId!,
    );

    if (hasReviewed) return;

    // Show review dialog for professional to rate customer
    await ReviewSubmissionDialog.show(
      context,
      bookingId: widget.booking.id,
      reviewerId: userState.userId!,
      reviewerName: userState.fullName ?? userState.email!.split('@')[0],
      reviewerPhotoUrl: userState.profilePhotoUrl,
      revieweeId: widget.booking.customerId,
      revieweeName: widget.booking.customerName,
      reviewType: ReviewType.professionalToCustomer,
      onReviewSubmitted: () {
        widget.onStatusUpdated?.call();
      },
    );
  }

  Color _getStatusColor() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return Colors.grey;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.orange;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.reviewed:
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.inProgress:
        return Icons.work;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.reviewed:
        return Icons.star;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.reviewed:
        return 'Reviewed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  DateTime? _getStatusTimestamp() {
    switch (widget.booking.status) {
      case BookingStatus.confirmed:
        return widget.booking.confirmedAt;
      case BookingStatus.inProgress:
        return widget.booking.jobStartedAt ?? widget.booking.onMyWayAt;
      case BookingStatus.completed:
        return widget.booking.jobCompletedAt;
      case BookingStatus.reviewed:
        return widget.booking.reviewedAt;
      default:
        return null;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
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
}

class BookingAction {
  final String label;
  final IconData icon;
  final Color color;
  final BookingActionType action;

  BookingAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.action,
  });
}

enum BookingActionType {
  markOnMyWay,
  markJobStarted,
  markJobCompleted,
  acceptJobCompleted,
  rateCustomer,
  rateProfessional,
}

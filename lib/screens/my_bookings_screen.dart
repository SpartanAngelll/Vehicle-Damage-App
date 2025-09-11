import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_state.dart';
import '../models/booking_models.dart';
import '../models/chat_models.dart';
import '../models/service.dart';
import '../models/payment_models.dart';
import '../models/invoice_models.dart';
import '../services/firebase_firestore_service.dart';
import '../services/postgres_payment_service.dart';
import '../services/mock_payment_service.dart';
import '../services/payment_workflow_service.dart';
import 'booking_summary_screen.dart';
import '../widgets/glow_card.dart';
import '../widgets/booking_status_actions.dart';
import '../widgets/payment_status_widget.dart';
import '../widgets/mock_payment_dialog.dart';
import '../widgets/deposit_request_dialog.dart';
import '../widgets/balance_payment_dialog.dart';
import '../widgets/review_submission_dialog.dart';
import '../models/review_models.dart';
import '../services/review_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final PostgresPaymentService _paymentService = PostgresPaymentService.instance;
  final MockPaymentService _mockPaymentService = MockPaymentService.instance;
  bool _useMockPayments = false;
  List<Map<String, dynamic>> _bookings = [];
  Map<String, Payment> _payments = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final userState = context.read<UserState>();
      final userId = userState.userId;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Try to initialize PostgreSQL connection
      try {
        await _paymentService.initialize();
        _useMockPayments = false;
        print('✅ [MyBookings] Using PostgreSQL for payments');
      } catch (e) {
        print('❌ [MyBookings] PostgreSQL connection failed: $e');
        print('💡 [MyBookings] Check network connectivity and PostgreSQL configuration');
        // For now, let's still try to use mock payments as fallback
        await _mockPaymentService.initialize();
        _useMockPayments = true;
        print('⚠️ [MyBookings] Falling back to mock payments');
      }

      // Determine user type based on user state or profile
      final userType = userState.isServiceProfessional ? 'professional' : 'customer';
      
      final bookings = await _firestoreService.getUserBookings(userId, userType: userType);
      
      // Load payment data for each booking
      final Map<String, Payment> payments = {};
      for (final booking in bookings) {
        final bookingId = booking['id'] as String?;
        if (bookingId != null) {
          try {
            Payment? payment;
            if (_useMockPayments) {
              payment = await _mockPaymentService.getPaymentByBookingId(bookingId);
            } else {
              payment = await _paymentService.getPaymentByBookingId(bookingId);
            }
            
            if (payment != null) {
              payments[bookingId] = payment;
            }
          } catch (e) {
            print('⚠️ [MyBookings] Failed to load payment for booking $bookingId: $e');
          }
        }
      }
      
      // Debug logging
      print('🔍 [MyBookings] Retrieved ${bookings.length} bookings');
      print('🔍 [MyBookings] Retrieved ${payments.length} payments');
      
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [MyBookings] Error loading bookings: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your bookings...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your confirmed bookings will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final serviceName = booking['serviceName'] ?? booking['serviceTitle'] ?? 'Service Request';
    final date = _formatDate(booking['date'] ?? booking['scheduledStartTime']);
    final time = _formatTime(booking['time'] ?? booking['scheduledStartTime']);
    final price = booking['price']?.toString() ?? booking['agreedPrice']?.toString() ?? 'TBD';
    final currency = booking['currency'] ?? 'JMD';
    final location = booking['location'] ?? 'To be confirmed';
    final status = booking['status'] ?? 'confirmed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: BookingCard(
        glowColor: _getStatusColor(status),
        onTap: () => _viewBookingDetails(booking),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      serviceName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildEnhancedStatusChip(status, _convertToBooking(booking)),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Main content grid - 2x2 layout
              Container(
                child: Column(
                  children: [
                    // First row: Date and Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: date,
                            iconColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: time,
                            iconColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Second row: Location and Price
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.location_on,
                            label: 'Location',
                            value: location,
                            iconColor: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.attach_money,
                            label: 'Price',
                            value: _formatPrice(price, currency),
                            iconColor: Colors.green[600]!,
                            valueStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Payment status widget
              _buildPaymentStatusWidget(booking),
              
              const SizedBox(height: 20),
              
              // Dynamic action button - centered
              Center(
                child: _buildDynamicActionButton(booking),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    TextStyle? valueStyle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: valueStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        label = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatusChip(String status, Booking? booking) {
    Color color;
    String label;
    IconData icon;
    String? subLabel;
    IconData? subIcon;
    Color? subColor;
    
    // Handle BookingStatus enum instead of string
    if (booking != null) {
      switch (booking.status) {
        case BookingStatus.confirmed:
          color = Colors.green;
          label = 'Confirmed';
          icon = Icons.check_circle;
          
          // Add travel responsibility info
          if (booking.finalTravelMode != null) {
            final travelMode = booking.finalTravelMode!;
            final isProfessional = _isServiceProfessional();
            
            switch (travelMode) {
              case TravelMode.customerTravels:
                subLabel = isProfessional ? 'Awaiting Customer' : 'You travel to shop';
                subIcon = isProfessional ? Icons.schedule : Icons.directions_car;
                subColor = isProfessional ? Colors.orange : Colors.blue;
                break;
              case TravelMode.proTravels:
                subLabel = isProfessional ? 'You travel to customer' : 'Pro travels to you';
                subIcon = isProfessional ? Icons.directions_car : Icons.schedule;
                subColor = isProfessional ? Colors.green : Colors.orange;
                break;
              case TravelMode.remote:
                subLabel = 'Remote service';
                subIcon = Icons.video_call;
                subColor = Colors.purple;
                break;
            }
          }
          break;
        case BookingStatus.inProgress:
          color = Colors.blue;
          label = 'In Progress';
          icon = Icons.play_arrow;
          subLabel = 'Job in progress';
          subIcon = Icons.work;
          subColor = Colors.blue;
          break;
        case BookingStatus.completed:
          color = Colors.green;
          label = 'Completed';
          icon = Icons.done_all;
          subLabel = 'Awaiting approval';
          subIcon = Icons.thumb_up;
          subColor = Colors.orange;
          break;
        case BookingStatus.reviewed:
          color = Colors.purple;
          label = 'Reviewed';
          icon = Icons.star;
          subLabel = 'Job finished';
          subIcon = Icons.check;
          subColor = Colors.purple;
          break;
        case BookingStatus.cancelled:
          color = Colors.red;
          label = 'Cancelled';
          icon = Icons.cancel;
          break;
        case BookingStatus.pending:
          color = Colors.orange;
          label = 'Pending';
          icon = Icons.schedule;
          break;
      }
    } else {
      // Fallback to string-based status
      switch (status.toLowerCase()) {
        case 'confirmed':
          color = Colors.green;
          label = 'Confirmed';
          icon = Icons.check_circle;
          break;
        case 'pending':
          color = Colors.orange;
          label = 'Pending';
          icon = Icons.schedule;
          break;
        case 'cancelled':
          color = Colors.red;
          label = 'Cancelled';
          icon = Icons.cancel;
          break;
        case 'completed':
          color = Colors.blue;
          label = 'Completed';
          icon = Icons.done_all;
          break;
        default:
          color = Colors.grey;
          label = status;
          icon = Icons.help;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  subIcon!,
                  color: subColor,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: subColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _viewBookingDetails(Map<String, dynamic> booking) {
    // Navigate to the full booking summary screen with calendar features
    try {
      // Parse the date/time from the booking data
      DateTime? startTime;
      DateTime? endTime;
      
      if (booking['date'] != null) {
        if (booking['date'] is String) {
          startTime = DateTime.tryParse(booking['date']);
        } else if (booking['date'] is Timestamp) {
          startTime = (booking['date'] as Timestamp).toDate();
        }
      } else if (booking['scheduledStartTime'] != null) {
        if (booking['scheduledStartTime'] is String) {
          startTime = DateTime.tryParse(booking['scheduledStartTime']);
        } else if (booking['scheduledStartTime'] is Timestamp) {
          startTime = (booking['scheduledStartTime'] as Timestamp).toDate();
        }
      }
      
      if (booking['endTime'] != null) {
        if (booking['endTime'] is String) {
          endTime = DateTime.tryParse(booking['endTime']);
        } else if (booking['endTime'] is Timestamp) {
          endTime = (booking['endTime'] as Timestamp).toDate();
        }
      } else if (booking['scheduledEndTime'] != null) {
        if (booking['scheduledEndTime'] is String) {
          endTime = DateTime.tryParse(booking['scheduledEndTime']);
        } else if (booking['scheduledEndTime'] is Timestamp) {
          endTime = (booking['scheduledEndTime'] as Timestamp).toDate();
        }
      }
      
      // Parse price
      double? price;
      if (booking['price'] != null) {
        price = (booking['price'] as num).toDouble();
      } else if (booking['agreedPrice'] != null) {
        price = (booking['agreedPrice'] as num).toDouble();
      }
      
      // Create a JobSummary object from the booking data
      final jobSummary = JobSummary(
        id: booking['id'] ?? '',
        chatRoomId: booking['chatRoomId'] ?? '',
        estimateId: booking['estimateId'] ?? '',
        customerId: booking['customerId'] ?? '',
        professionalId: booking['professionalId'] ?? '',
        originalEstimate: booking['serviceDescription'] ?? 'Service Request',
        conversationSummary: booking['serviceDescription'] ?? 'Service Request',
        extractedPrice: price ?? 0.0,
        extractedStartTime: startTime,
        extractedEndTime: endTime,
        extractedLocation: booking['location'] ?? 'To be confirmed',
        extractedDeliverables: List<String>.from(booking['deliverables'] ?? []),
        extractedImportantPoints: List<String>.from(booking['importantPoints'] ?? []),
        confidenceScore: (booking['confidenceScore'] as num?)?.toDouble() ?? 0.8,
        createdAt: DateTime.now(),
        rawAnalysis: {
          'service': booking['serviceName'] ?? booking['serviceTitle'] ?? 'Service Request',
          'currency': booking['currency'] ?? 'JMD',
        },
      );
      
      // Create a ChatRoom object
      final chatRoom = ChatRoom(
        id: booking['chatRoomId'] ?? '',
        customerId: booking['customerId'] ?? '',
        professionalId: booking['professionalId'] ?? '',
        estimateId: booking['estimateId'] ?? '',
        customerName: 'Customer', // Default name since we don't have it in booking data
        professionalName: 'Professional', // Default name since we don't have it in booking data
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );
      
      // Navigate to BookingSummaryScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BookingSummaryScreen(
            jobSummary: jobSummary,
            chatRoom: chatRoom,
            bookingId: booking['id'] ?? '',
          ),
        ),
      );
    } catch (e) {
      print('❌ [MyBookings] Error navigating to booking details: $e');
      // Fallback to simple dialog if there's an error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(booking['serviceName'] ?? booking['serviceTitle'] ?? 'Service Request'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Date', _formatDate(booking['date'] ?? booking['scheduledStartTime'])),
                _buildDetailRow('Time', _formatTime(booking['time'] ?? booking['scheduledStartTime'])),
                _buildDetailRow('Location', booking['location'] ?? 'To be confirmed'),
                _buildDetailRow('Price', _formatPrice(booking['price']?.toString() ?? booking['agreedPrice']?.toString() ?? 'TBD', booking['currency'] ?? 'JMD')),
                _buildDetailRow('Status', booking['status'] ?? 'confirmed'),
                if (booking['serviceDescription'] != null)
                  _buildDetailRow('Description', booking['serviceDescription']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'TBD';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is Timestamp) {
        // Handle Firestore Timestamp
        date = dateValue.toDate();
      } else {
        return 'TBD';
      }
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('❌ [MyBookings] Error formatting date: $e');
      return 'TBD';
    }
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null) return 'TBD';
    
    try {
      DateTime time;
      if (timeValue is String) {
        time = DateTime.parse(timeValue);
      } else if (timeValue is DateTime) {
        time = timeValue;
      } else if (timeValue is Timestamp) {
        // Handle Firestore Timestamp
        time = timeValue.toDate();
      } else {
        return 'TBD';
      }
      
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('❌ [MyBookings] Error formatting time: $e');
      return 'TBD';
    }
  }

  String _formatPrice(String price, String currency) {
    if (price == 'TBD') return price;
    
    // Format price to 2 decimal places
    double? priceValue = double.tryParse(price);
    if (priceValue != null) {
      String formattedPrice = priceValue.toStringAsFixed(2);
      return currency == 'JMD' ? '$formattedPrice $currency' : '\$$formattedPrice $currency';
    }
    
    return currency == 'JMD' ? '$price $currency' : '\$$price $currency';
  }

  Booking? _convertToBooking(Map<String, dynamic> bookingData) {
    try {
      // Debug logging for travel mode data
      print('🔍 [MyBookings] Converting booking data: ${bookingData['id']}');
      print('🔍 [MyBookings] Travel mode: ${bookingData['finalTravelMode']}');
      print('🔍 [MyBookings] Customer address: ${bookingData['customerAddress']}');
      print('🔍 [MyBookings] Shop address: ${bookingData['shopAddress']}');
      print('🔍 [MyBookings] Travel fee: ${bookingData['travelFee']}');
      // Convert status string to enum
      BookingStatus status;
      switch (bookingData['status']?.toString().toLowerCase()) {
        case 'confirmed':
          status = BookingStatus.confirmed;
          break;
        case 'inprogress':
        case 'in_progress':
          status = BookingStatus.inProgress;
          break;
        case 'completed':
          status = BookingStatus.completed;
          break;
        case 'reviewed':
          status = BookingStatus.reviewed;
          break;
        case 'cancelled':
          status = BookingStatus.cancelled;
          break;
        default:
          status = BookingStatus.pending;
      }

      return Booking(
        id: bookingData['id'] ?? '',
        estimateId: bookingData['estimateId'] ?? '',
        chatRoomId: bookingData['chatRoomId'] ?? '',
        customerId: bookingData['customerId'] ?? '',
        professionalId: bookingData['professionalId'] ?? '',
        customerName: bookingData['customerName'] ?? '',
        professionalName: bookingData['professionalName'] ?? '',
        serviceTitle: bookingData['serviceTitle'] ?? bookingData['serviceName'] ?? '',
        serviceDescription: bookingData['serviceDescription'] ?? '',
        agreedPrice: (bookingData['agreedPrice'] as num?)?.toDouble() ?? 0.0,
        scheduledStartTime: _parseDateTime(bookingData['scheduledStartTime'] ?? bookingData['date']) ?? DateTime.now(),
        scheduledEndTime: _parseDateTime(bookingData['scheduledEndTime'] ?? bookingData['date']) ?? DateTime.now(),
        location: bookingData['location'] ?? '',
        deliverables: List<String>.from(bookingData['deliverables'] ?? []),
        importantPoints: List<String>.from(bookingData['importantPoints'] ?? []),
        status: status,
        createdAt: _parseDateTime(bookingData['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(bookingData['updatedAt']) ?? DateTime.now(),
        notes: bookingData['notes'],
        metadata: bookingData['metadata'],
        confirmedAt: _parseDateTime(bookingData['confirmedAt']),
        onMyWayAt: _parseDateTime(bookingData['onMyWayAt']),
        jobStartedAt: _parseDateTime(bookingData['jobStartedAt']),
        jobCompletedAt: _parseDateTime(bookingData['jobCompletedAt']),
        jobAcceptedAt: _parseDateTime(bookingData['jobAcceptedAt']),
        reviewedAt: _parseDateTime(bookingData['reviewedAt']),
        customerPin: bookingData['customerPin'],
        statusNotes: bookingData['statusNotes'],
        finalTravelMode: bookingData['finalTravelMode'] != null 
            ? TravelMode.values.firstWhere(
                (e) => e.name == bookingData['finalTravelMode'],
                orElse: () => TravelMode.customerTravels,
              )
            : null,
        customerAddress: bookingData['customerAddress'],
        shopAddress: bookingData['shopAddress'],
        travelFee: bookingData['travelFee']?.toDouble(),
      );
    } catch (e) {
      print('Error converting booking data: $e');
      return null;
    }
  }

  DateTime? _parseDateTime(dynamic date) {
    if (date == null) return null;
    
    try {
      if (date is String) {
        return DateTime.parse(date);
      } else if (date is Timestamp) {
        return date.toDate();
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  bool _isServiceProfessional() {
    try {
      final userState = context.read<UserState>();
      return userState.isServiceProfessional;
    } catch (e) {
      return false;
    }
  }

  Widget _buildDynamicActionButton(Map<String, dynamic> booking) {
    final bookingModel = _convertToBooking(booking);
    if (bookingModel == null) {
      return _buildViewDetailsButton(booking);
    }

    final status = bookingModel.status;
    final isProfessional = _isServiceProfessional();
    final travelMode = bookingModel.finalTravelMode;


    // Determine the appropriate action based on status and role
    String actionLabel;
    IconData actionIcon;
    Color actionColor;
    VoidCallback? onPressed;

    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.confirmed:
        // Check if "On My Way" should be shown based on travel mode
        if (_shouldShowOnMyWayAction(bookingModel, isProfessional)) {
          actionLabel = 'On My Way';
          actionIcon = Icons.directions_car;
          actionColor = Colors.blue;
          onPressed = () => _handleOnMyWayAction(bookingModel);
        } else if (isProfessional && _shouldShowMarkJobStarted(bookingModel)) {
          // Professional can mark job started when they arrive
          actionLabel = 'Mark Job Started';
          actionIcon = Icons.play_arrow;
          actionColor = Colors.green;
          onPressed = () => _handleMarkJobStarted(bookingModel);
        } else {
          // Show "View Details" if no action is available
          return _buildViewDetailsButton(booking);
        }
        break;
        
      case BookingStatus.inProgress:
        if (isProfessional) {
          actionLabel = 'Mark Job Completed';
          actionIcon = Icons.check_circle;
          actionColor = Colors.orange;
          onPressed = () => _handleMarkJobCompleted(bookingModel);
        } else {
          // Customer can't take action during in-progress
          return _buildViewDetailsButton(booking);
        }
        break;
        
      case BookingStatus.completed:
        if (!isProfessional) {
          actionLabel = 'Accept Job as Completed';
          actionIcon = Icons.thumb_up;
          actionColor = Colors.green;
          onPressed = () => _handleAcceptJobCompleted(bookingModel);
        } else {
          // Professional can't take action after completion
          return _buildViewDetailsButton(booking);
        }
        break;
        
      case BookingStatus.reviewed:
        // Allow review actions even for reviewed bookings
        if (!isProfessional) {
          actionLabel = 'Rate Professional';
          actionIcon = Icons.star_rate;
          actionColor = Colors.amber;
          onPressed = () => _handleRateProfessional(bookingModel);
        } else {
          actionLabel = 'Rate Customer';
          actionIcon = Icons.star_rate;
          actionColor = Colors.amber;
          onPressed = () => _handleRateCustomer(bookingModel);
        }
        break;
        
      default:
        // For other statuses, show view details
        return _buildViewDetailsButton(booking);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            actionColor,
            actionColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: actionColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(actionIcon, size: 18, color: Colors.white),
        label: Text(
          actionLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  Widget _buildViewDetailsButton(Map<String, dynamic> booking) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: () => _viewBookingDetails(booking),
        icon: const Icon(Icons.visibility, size: 18, color: Colors.white),
        label: const Text(
          'View Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  bool _shouldShowOnMyWayAction(Booking booking, bool isProfessional) {
    final travelMode = booking.finalTravelMode;
    
    // For remote services, skip travel steps
    if (travelMode == TravelMode.remote) {
      return false;
    }
    
    // Check if already on the way
    if (booking.onMyWayAt != null) {
      return false; // Already indicated they're on their way
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

  bool _shouldShowMarkJobStarted(Booking booking) {
    // Professional can mark job started when:
    // 1. They have arrived (onMyWayAt is set)
    // 2. Job hasn't started yet (jobStartedAt is null)
    return booking.onMyWayAt != null && booking.jobStartedAt == null;
  }

  Future<void> _handleOnMyWayAction(Booking booking) async {
    try {
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.markProfessionalOnWay(booking.id);
      
      // Show PIN for verification based on travel mode
      if (booking.finalTravelMode == TravelMode.customerTravels) {
        // Customer is traveling to shop - show PIN for professional verification
        if (!_isServiceProfessional()) {
          await _showPinDisplayDialog(booking);
        }
      } else if (booking.finalTravelMode == TravelMode.proTravels) {
        // Professional is traveling to customer - show PIN for customer verification
        if (_isServiceProfessional()) {
          await _showPinDisplayDialog(booking);
        }
      }
      
      // Refresh the bookings to show updated status
      _loadBookings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated: On My Way'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMarkJobStarted(Booking booking) async {
    // Show PIN verification dialog
    final enteredPin = await _showPinVerificationDialog();
    if (enteredPin == null) return; // User cancelled

    try {
      // Verify the PIN matches the stored PIN
      final isValidPin = await _verifyPin(booking.id, enteredPin);
      
      if (!isValidPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid PIN. Please check with the customer.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final firestoreService = FirebaseFirestoreService();
      await firestoreService.markJobStarted(booking.id, enteredPin);
      
      // Refresh the bookings to show updated status
      _loadBookings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _verifyPin(String bookingId, String enteredPin) async {
    try {
      final firestoreService = FirebaseFirestoreService();
      final bookingData = await firestoreService.getBooking(bookingId);
      
      print('🔍 [PIN Verification] Booking ID: $bookingId');
      print('🔍 [PIN Verification] Entered PIN: $enteredPin');
      print('🔍 [PIN Verification] Booking data: $bookingData');
      
      if (bookingData != null) {
        final storedPin = bookingData['customerPin']?.toString();
        print('🔍 [PIN Verification] Stored PIN: $storedPin');
        print('🔍 [PIN Verification] PIN match: ${storedPin == enteredPin}');
        return storedPin == enteredPin;
      }
      print('🔍 [PIN Verification] No booking data found');
      return false;
    } catch (e) {
      print('❌ [PIN Verification] Error verifying PIN: $e');
      return false;
    }
  }

  Future<String?> _showPinVerificationDialog() async {
    final pinController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify Customer PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the 4-digit PIN shown on the customer\'s screen:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'Customer PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (pinController.text.length == 4) {
                  Navigator.of(context).pop(pinController.text);
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPinDisplayDialog(Booking booking) async {
    // Generate a random 4-digit PIN
    final pin = _generateRandomPin();
    
    // Store the PIN in Firebase for verification
    await _storePinForVerification(booking.id, pin);
    
    // Add a small delay to ensure PIN is stored
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final isProfessional = _isServiceProfessional();
    final travelMode = booking.finalTravelMode;
    
    String title;
    String instruction;
    String explanation;
    
    if (isProfessional) {
      title = 'Customer Verification PIN';
      instruction = 'Ask the customer for this PIN when you arrive:';
      explanation = 'The customer will show you this PIN to verify job start.';
    } else {
      title = 'Verification PIN';
      instruction = 'Show this PIN to your service professional when you arrive:';
      explanation = 'The professional will need this PIN to start your job.';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      isProfessional ? 'Customer PIN' : 'Your PIN',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pin,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                explanation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  String _generateRandomPin() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final pin = (random % 9000 + 1000).toString();
    print('🔍 [PIN Generation] Generated PIN: $pin (from timestamp: $random)');
    return pin;
  }

  Future<void> _storePinForVerification(String bookingId, String pin) async {
    try {
      print('🔍 [PIN Storage] Storing PIN for booking: $bookingId');
      print('🔍 [PIN Storage] PIN to store: $pin');
      
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.updateBookingStatus(
        bookingId,
        BookingStatus.confirmed.name,
        additionalData: {
          'customerPin': pin,
        },
      );
      
      print('✅ [PIN Storage] PIN stored successfully');
    } catch (e) {
      print('❌ [PIN Storage] Error storing PIN: $e');
    }
  }

  Future<void> _handleMarkJobCompleted(Booking booking) async {
    try {
      // Check if balance payment is required BEFORE marking job as completed
      final paymentService = PaymentWorkflowService.instance;
      await paymentService.initialize();
      
      final isBalanceRequired = await paymentService.isBalancePaymentRequired(booking.id);
      
      if (isBalanceRequired) {
        // Show error message that balance must be paid first
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot complete job: Balance payment is still required. Please pay the remaining balance first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      // Only mark job as completed if no balance is required
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.markJobCompleted(booking.id);
      
      // Refresh the bookings to show updated status
      _loadBookings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAndShowBalancePayment(Booking booking) async {
    try {
      final paymentService = PaymentWorkflowService.instance;
      await paymentService.initialize();

      // Check if balance payment is required
      final isBalanceRequired = await paymentService.isBalancePaymentRequired(booking.id);
      
      if (isBalanceRequired) {
        // Get the invoice
        final invoice = await paymentService.getInvoiceByBookingId(booking.id);
        if (invoice != null && !invoice.isFullyPaid) {
          // Show balance payment dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => BalancePaymentDialog(
                invoice: invoice,
                onBalancePaid: (paymentMethod) async {
                  try {
                    await paymentService.processBalancePayment(
                      bookingId: booking.id,
                      paymentMethod: paymentMethod,
                      notes: 'Balance payment via ${paymentMethod.name}',
                    );
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Balance payment successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    // Refresh bookings to show updated payment status
                    _loadBookings();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ [MyBookings] Failed to check balance payment: $e');
    }
  }

  Future<void> _handleAcceptJobCompleted(Booking booking) async {
    try {
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.acceptJobAsCompleted(booking.id);
      
      // Refresh the bookings to show updated status
      _loadBookings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRateProfessional(Booking booking) async {
    try {
      final userState = context.read<UserState>();
      final reviewService = ReviewService();
      
      if (userState.userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if customer has already reviewed this booking
      final hasReviewed = await reviewService.hasCustomerReviewedBooking(
        booking.id,
        userState.userId!,
      );

      if (hasReviewed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already reviewed this professional'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show review dialog for customer to rate professional
      await ReviewSubmissionDialog.show(
        context,
        bookingId: booking.id,
        reviewerId: userState.userId!,
        reviewerName: userState.fullName ?? userState.email!.split('@')[0],
        reviewerPhotoUrl: userState.profilePhotoUrl,
        revieweeId: booking.professionalId,
        revieweeName: booking.professionalName,
        reviewType: ReviewType.customerToProfessional,
        onReviewSubmitted: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Review submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadBookings(); // Refresh to show updated data
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRateCustomer(Booking booking) async {
    try {
      final userState = context.read<UserState>();
      final reviewService = ReviewService();
      
      if (userState.userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if professional has already reviewed this booking
      final hasReviewed = await reviewService.hasProfessionalReviewedBooking(
        booking.id,
        userState.userId!,
      );

      if (hasReviewed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already reviewed this customer'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show review dialog for professional to rate customer
      await ReviewSubmissionDialog.show(
        context,
        bookingId: booking.id,
        reviewerId: userState.userId!,
        reviewerName: userState.fullName ?? userState.email!.split('@')[0],
        reviewerPhotoUrl: userState.profilePhotoUrl,
        revieweeId: booking.customerId,
        revieweeName: booking.customerName,
        reviewType: ReviewType.professionalToCustomer,
        onReviewSubmitted: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Review submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadBookings(); // Refresh to show updated data
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPaymentStatusWidget(Map<String, dynamic> booking) {
    final bookingId = booking['id'] as String?;
    if (bookingId == null) return const SizedBox.shrink();

    final payment = _payments[bookingId];
    final userState = context.read<UserState>();
    final isProfessional = userState.isServiceProfessional;

    return PaymentStatusWidget(
      payment: payment,
      onPayDepositPressed: payment != null ? () => _handlePayment(payment) : null,
      onPayBalancePressed: payment != null ? () => _handlePayment(payment) : null,
      onPayFullPressed: payment != null ? () => _handlePayment(payment) : null,
      onRequestDepositPressed: isProfessional && payment != null 
          ? () => _handleRequestDeposit(booking) 
          : null,
      isProfessional: isProfessional,
      showActions: true,
    );
  }

  Future<void> _handlePayment(Payment payment) async {
    try {
      // Determine if this is a deposit, balance, or full payment
      final isDepositPayment = payment.isDepositRequired && payment.depositPaid < payment.depositRequired;
      final isBalancePayment = payment.isDepositRequired && payment.remainingAmount > 0;
      final isFullPayment = !payment.isDepositRequired && payment.status == PaymentStatus.pending;
      
      // Create appropriate payment object for the dialog
      Payment paymentForDialog = payment;
      if (isDepositPayment) {
        // Create a deposit payment object with the deposit amount
        paymentForDialog = Payment(
          id: payment.id, // Keep same ID for tracking
          bookingId: payment.bookingId,
          customerId: payment.customerId,
          professionalId: payment.professionalId,
          amount: payment.depositRequired, // Show deposit amount, not remaining
          currency: payment.currency,
          type: PaymentType.deposit,
          depositPercentage: payment.depositPercentage,
          depositAmount: payment.depositRequired,
          totalAmount: payment.originalTotalAmount,
          status: PaymentStatus.pending,
          paymentMethod: null,
          transactionId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          paidAt: null,
          refundedAt: null,
          refundAmount: null,
          notes: 'Deposit payment',
        );
      } else if (isBalancePayment) {
        // Create a balance payment object with the remaining amount
        paymentForDialog = Payment(
          id: payment.id, // Keep same ID for tracking
          bookingId: payment.bookingId,
          customerId: payment.customerId,
          professionalId: payment.professionalId,
          amount: payment.remainingAmount, // Use remaining amount for balance
          currency: payment.currency,
          type: PaymentType.balance,
          depositPercentage: 0, // No deposit for balance payment
          depositAmount: null,
          totalAmount: payment.originalTotalAmount,
          status: PaymentStatus.pending,
          paymentMethod: null,
          transactionId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          paidAt: null,
          refundedAt: null,
          refundAmount: null,
          notes: 'Balance payment for remaining amount',
        );
      } else if (isFullPayment) {
        // Create a full payment object with the total amount
        paymentForDialog = Payment(
          id: payment.id, // Keep same ID for tracking
          bookingId: payment.bookingId,
          customerId: payment.customerId,
          professionalId: payment.professionalId,
          amount: payment.originalTotalAmount, // Show full amount
          currency: payment.currency,
          type: PaymentType.full,
          depositPercentage: 0, // No deposit for full payment
          depositAmount: null,
          totalAmount: payment.originalTotalAmount,
          status: PaymentStatus.pending,
          paymentMethod: null,
          transactionId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          paidAt: null,
          refundedAt: null,
          refundAmount: null,
          notes: 'Full payment',
        );
      }
      
      await showDialog(
        context: context,
        builder: (context) => MockPaymentDialog(
          payment: paymentForDialog,
          onPaymentProcessed: (paymentMethod) async {
            if (isDepositPayment) {
              await _processDepositPayment(payment, paymentMethod);
            } else if (isBalancePayment) {
              await _processBalancePayment(payment, paymentMethod);
            } else if (isFullPayment) {
              await _processFullPayment(payment, paymentMethod);
            } else {
              await _processPayment(payment, paymentMethod);
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening payment dialog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPayment(Payment payment, PaymentMethod paymentMethod) async {
    try {
      final success = _useMockPayments
          ? await _mockPaymentService.processMockPayment(
              paymentId: payment.id,
              paymentMethod: paymentMethod,
              notes: 'Mock payment processed via mobile app',
            )
          : await _paymentService.processMockPayment(
              paymentId: payment.id,
              paymentMethod: paymentMethod,
              notes: 'Mock payment processed via mobile app',
            );

      if (success) {
        // Reload payments to get updated status
        await _loadPayments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment processed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Payment processing failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processDepositPayment(Payment payment, PaymentMethod paymentMethod) async {
    try {
      final success = _useMockPayments
          ? await _mockPaymentService.processMockPayment(
              paymentId: payment.id,
              paymentMethod: paymentMethod,
              notes: 'Deposit payment processed via mobile app',
            )
          : await _paymentService.processMockPayment(
              paymentId: payment.id,
              paymentMethod: paymentMethod,
              notes: 'Deposit payment processed via mobile app',
            );

      if (success) {
        // Reload payments to get updated status
        await _loadPayments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deposit payment processed successfully! Balance payment required before job completion.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Deposit payment processing failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deposit payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processBalancePayment(Payment payment, PaymentMethod paymentMethod) async {
    try {
      // First create a balance payment record
      final postgresService = PostgresPaymentService.instance;
      await postgresService.initialize();
      
      final balancePayment = await postgresService.processBalancePayment(
        bookingId: payment.bookingId,
        paymentMethod: paymentMethod,
        notes: 'Balance payment processed via mobile app',
      );

      // Process the balance payment
      final success = _useMockPayments
          ? await _mockPaymentService.processMockPayment(
              paymentId: balancePayment.id,
              paymentMethod: paymentMethod,
              notes: 'Balance payment processed via mobile app',
            )
          : await _paymentService.processMockPayment(
              paymentId: balancePayment.id,
              paymentMethod: paymentMethod,
              notes: 'Balance payment processed via mobile app',
            );

      if (success) {
        // Reload payments to get updated status
        await _loadPayments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Balance payment processed successfully! Job can now be completed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Balance payment processing failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Balance payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processFullPayment(Payment payment, PaymentMethod paymentMethod) async {
    try {
      // Process the full payment using the existing payment record
      final success = _useMockPayments
          ? await _mockPaymentService.processMockPayment(
              paymentId: payment.id,
              paymentMethod: paymentMethod,
              notes: 'Full payment processed via mobile app',
            )
          : await _paymentService.processMockPayment(
              paymentId: payment.id,
              paymentMethod: paymentMethod,
              notes: 'Full payment processed via mobile app',
            );

      if (success) {
        // Reload payments to get updated status
        await _loadPayments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Full payment processed successfully! Job can now be completed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Full payment processing failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Full payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRequestDeposit(Map<String, dynamic> booking) async {
    try {
      final bookingId = booking['id'] as String?;
      final professionalId = context.read<UserState>().userId;
      // Try both price and agreedPrice fields
      final totalAmount = (booking['agreedPrice'] ?? booking['price'] ?? 0.0).toDouble();

      if (bookingId == null || professionalId == null) {
        throw Exception('Missing booking or user information');
      }

      if (totalAmount <= 0) {
        throw Exception('Invalid booking amount. Cannot request deposit.');
      }

      await showDialog(
        context: context,
        builder: (context) => DepositRequestDialog(
          bookingId: bookingId,
          professionalId: professionalId,
          totalAmount: totalAmount,
          onRequestDeposit: (depositPercentage, reason) async {
            await _requestDeposit(bookingId, professionalId, depositPercentage, reason);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting deposit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestDeposit(
    String bookingId,
    String professionalId,
    int depositPercentage,
    String reason,
  ) async {
    try {
      final success = _useMockPayments
          ? await _mockPaymentService.requestDeposit(
              bookingId: bookingId,
              professionalId: professionalId,
              depositPercentage: depositPercentage,
              reason: reason,
            )
          : await _paymentService.requestDeposit(
              bookingId: bookingId,
              professionalId: professionalId,
              depositPercentage: depositPercentage,
              reason: reason,
            );

      if (success) {
        // Reload payments to get updated deposit information
        await _loadPayments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deposit request sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to request deposit');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request deposit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPayments() async {
    try {
      final userState = context.read<UserState>();
      final userId = userState.userId;
      
      if (userId == null) return;

      final Map<String, Payment> payments = {};
      for (final booking in _bookings) {
        final bookingId = booking['id'] as String?;
        if (bookingId != null) {
          try {
            Payment? payment;
            if (_useMockPayments) {
              payment = await _mockPaymentService.getPaymentByBookingId(bookingId);
            } else {
              payment = await _paymentService.getPaymentByBookingId(bookingId);
            }
            
            if (payment != null) {
              payments[bookingId] = payment;
            }
          } catch (e) {
            print('⚠️ [MyBookings] Failed to load payment for booking $bookingId: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _payments = payments;
        });
      }
    } catch (e) {
      print('❌ [MyBookings] Error loading payments: $e');
    }
  }

  @override
  void dispose() {
    // Close PostgreSQL connection when screen is disposed
    _paymentService.close();
    super.dispose();
  }

}

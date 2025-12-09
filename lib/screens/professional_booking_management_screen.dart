import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_availability_models.dart';
import '../models/booking_models.dart';
import '../services/booking_availability_service.dart';
import '../services/firebase_firestore_service.dart';
import '../widgets/booking_calendar_widget.dart';
import '../widgets/booking_calendar_grid.dart';
import '../widgets/booking_card.dart';

class ProfessionalBookingManagementScreen extends StatefulWidget {
  final String professionalId;
  final String professionalName;

  const ProfessionalBookingManagementScreen({
    Key? key,
    required this.professionalId,
    required this.professionalName,
  }) : super(key: key);

  @override
  State<ProfessionalBookingManagementScreen> createState() => _ProfessionalBookingManagementScreenState();
}

class _ProfessionalBookingManagementScreenState extends State<ProfessionalBookingManagementScreen>
    with SingleTickerProviderStateMixin {
  final BookingAvailabilityService _bookingService = BookingAvailabilityService();
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  
  late TabController _tabController;
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  bool _isLoading = false;
  DateTime? _selectedDate;
  List<TimeSlot> _selectedDateSlots = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);
      
      final bookings = await _bookingService.getProfessionalBookings(
        professionalId: widget.professionalId,
        startDate: startOfMonth.subtract(const Duration(days: 30)),
        endDate: endOfMonth.add(const Duration(days: 30)),
      );
      
      // Fetch customer names from user profiles for bookings with placeholder names
      final updatedBookings = await Future.wait(
        bookings.map((booking) async {
          // If customerName is "Customer" or empty, fetch from user profile
          if (booking.customerName.isEmpty || 
              booking.customerName.toLowerCase() == 'customer') {
            try {
              final customerProfile = await _firestoreService.getUserProfile(booking.customerId);
              if (customerProfile != null) {
                final fullName = customerProfile['fullName'] ?? 
                               customerProfile['displayName'] ??
                               customerProfile['username'] ?? 
                               customerProfile['email']?.split('@')[0] ?? 
                               'Customer';
                
                // Update the booking with the actual customer name
                return booking.copyWith(customerName: fullName);
              }
            } catch (e) {
              debugPrint('⚠️ [ProfessionalBookingManagement] Error fetching customer name for ${booking.customerId}: $e');
            }
          }
          return booking;
        }),
      );
      
      setState(() {
        _upcomingBookings = updatedBookings.where((b) => 
          b.scheduledStartTime.isAfter(now) && 
          b.status != BookingStatus.cancelled
        ).toList();
        
        _pastBookings = updatedBookings.where((b) => 
          b.scheduledStartTime.isBefore(now) || 
          b.status == BookingStatus.cancelled
        ).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  Future<void> _setupAvailability() async {
    try {
      // Show availability setup dialog
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const AvailabilitySetupDialog(),
      );
      
      if (result != null) {
        await _bookingService.setupProfessionalAvailability(
          professionalId: widget.professionalId,
          weeklySchedule: result['schedule'],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability schedule updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up availability: $e')),
        );
      }
    }
  }

  void _onDateSelected(DateTime date, List<TimeSlot> slots) {
    setState(() {
      _selectedDate = date;
      _selectedDateSlots = slots;
    });
  }

  void _onSlotSelected(TimeSlot slot) {
    // Handle slot selection - could show booking details or allow editing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Slot Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${_formatTimeSlot(slot.startTime, slot.endTime)}'),
            Text('Status: ${slot.isAvailable ? 'Available' : 'Booked'}'),
            if (!slot.isAvailable && slot.bookingId != null)
              Text('Booking ID: ${slot.bookingId}'),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.professionalName}\'s Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
            Tab(text: 'Past', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _setupAvailability,
            icon: const Icon(Icons.settings),
            tooltip: 'Setup Availability',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildUpcomingBookingsTab(),
          _buildPastBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        if (_selectedDate != null) _buildSelectedDateInfo(),
        Expanded(
          child: BookingCalendarWidget(
            professionalId: widget.professionalId,
            onDateSelected: _onDateSelected,
            onSlotSelected: _onSlotSelected,
            showAvailableSlotsOnly: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateInfo() {
    final availableCount = _selectedDateSlots.where((s) => s.isAvailable).length;
    final bookedCount = _selectedDateSlots.where((s) => !s.isAvailable).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.calendar_today,
            label: 'Selected Date',
            value: _formatDate(_selectedDate!),
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.blue.shade200,
          ),
          _buildInfoItem(
            icon: Icons.access_time,
            label: 'Total Slots',
            value: '${_selectedDateSlots.length}',
            color: Colors.grey.shade700,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.blue.shade200,
          ),
          _buildInfoItem(
            icon: Icons.check_circle,
            label: 'Available',
            value: '$availableCount',
            color: Colors.green,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.blue.shade200,
          ),
          _buildInfoItem(
            icon: Icons.event_busy,
            label: 'Booked',
            value: '$bookedCount',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingBookingsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingBookings.isEmpty) {
      return const Center(
        child: Text('No upcoming bookings'),
      );
    }

    // Convert Booking models to CalendarBooking for the grid
    // Use a stable key based on booking IDs and times to help Flutter identify
    // when the grid should actually rebuild vs when it's just a reference change
    final calendarBookings = _upcomingBookings.map((booking) {
      return CalendarBooking(
        id: booking.id,
        start: booking.scheduledStartTime,
        end: booking.scheduledEndTime,
        title: booking.serviceTitle,
        customerName: booking.customerName,
        color: _getStatusColor(booking.status),
      );
    }).toList();

    // Calculate start date (first day of current month)
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);

    return Column(
      children: [
        // Instructions banner
        Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.blue.shade50,
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Long-press a booking to drag it to a new time slot. Tap a booking to view details.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Calendar grid - shows full month by default
        Expanded(
          child: BookingCalendarGrid(
            bookings: calendarBookings,
            startDate: startDate,
            numberOfDays: null, // null means show full month
            onBookingRescheduled: _handleBookingRescheduled,
            onBookingTap: _handleBookingTap,
            rowHeight: 60.0,
            columnWidth: 200.0,
            showGridLines: true,
            showMonthPaginator: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPastBookingsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pastBookings.isEmpty) {
      return const Center(
        child: Text('No past bookings'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastBookings.length,
      itemBuilder: (context, index) {
        final booking = _pastBookings[index];
        return _buildBookingCard(booking, isUpcoming: false);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, {required bool isUpcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.serviceTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${booking.customerName}'),
            Text('Date: ${_formatDate(booking.scheduledStartTime)}'),
            Text('Time: ${_formatTimeSlot(booking.scheduledStartTime, booking.scheduledEndTime)}'),
            Text('Price: \$${booking.agreedPrice.toStringAsFixed(2)}'),
            if (booking.location.isNotEmpty)
              Text('Location: ${booking.location}'),
            if (isUpcoming) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _updateBookingStatus(booking, BookingStatus.confirmed),
                    child: const Text('Confirm'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateBookingStatus(booking, BookingStatus.cancelled),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Handle booking rescheduling via drag & drop
  Future<void> _handleBookingRescheduled({
    required String bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    try {
      // Check for conflicts before updating
      final conflicts = await _bookingService.checkBookingConflicts(
        professionalId: widget.professionalId,
        startTime: newStartTime,
        endTime: newEndTime,
        excludeBookingId: bookingId,
      );

      if (conflicts.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot reschedule: ${conflicts.first.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // Revert the optimistic update in the grid by reloading
        await _loadBookings();
        return;
      }

      // Update booking in Firestore
      await _bookingsCollection.doc(bookingId).update({
        'scheduledStartTime': Timestamp.fromDate(newStartTime),
        'scheduledEndTime': Timestamp.fromDate(newEndTime),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local state silently without triggering setState
      // The grid already updated optimistically, so we just sync the parent's state
      // without causing a rebuild. We'll update the lists directly.
      final upcomingIndex = _upcomingBookings.indexWhere((b) => b.id == bookingId);
      if (upcomingIndex != -1) {
        final booking = _upcomingBookings[upcomingIndex];
        _upcomingBookings[upcomingIndex] = booking.copyWith(
          scheduledStartTime: newStartTime,
          scheduledEndTime: newEndTime,
          updatedAt: DateTime.now(),
        );
      }
      
      // Also update in past bookings if it exists there
      final pastIndex = _pastBookings.indexWhere((b) => b.id == bookingId);
      if (pastIndex != -1) {
        final booking = _pastBookings[pastIndex];
        _pastBookings[pastIndex] = booking.copyWith(
          scheduledStartTime: newStartTime,
          scheduledEndTime: newEndTime,
          updatedAt: DateTime.now(),
        );
      }
      
      // Note: We intentionally don't call setState() here to avoid rebuilding
      // The grid already updated optimistically, and didUpdateWidget will handle
      // syncing when the parent naturally rebuilds for other reasons

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking rescheduled to ${_formatDate(newStartTime)} at ${_formatTime(newStartTime)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // On error, reload to sync with backend
      await _loadBookings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle booking tap - show details dialog with actions
  void _handleBookingTap(CalendarBooking calendarBooking) {
    // Find the full booking details
    final booking = _upcomingBookings.firstWhere((b) => b.id == calendarBooking.id);
    _showBookingDetailsDialog(booking);
  }

  /// Show booking details dialog with actions
  void _showBookingDetailsDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.serviceTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Customer', booking.customerName),
              _buildDetailRow('Date', _formatDate(booking.scheduledStartTime)),
              _buildDetailRow('Time', _formatTimeSlot(booking.scheduledStartTime, booking.scheduledEndTime)),
              _buildDetailRow('Price', '\$${booking.agreedPrice.toStringAsFixed(2)}'),
              if (booking.location.isNotEmpty)
                _buildDetailRow('Location', booking.location),
              _buildDetailRow('Status', booking.status.name.toUpperCase()),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _buildDetailRow('Notes', booking.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateBookingStatus(booking, BookingStatus.confirmed);
            },
            child: const Text('Confirm'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateBookingStatus(booking, BookingStatus.cancelled);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(Booking booking, BookingStatus status) async {
    try {
      await _bookingService.cancelBooking(booking.id);
      await _loadBookings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking ${status.name} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking: $e')),
        );
      }
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.reviewed:
        return Colors.teal;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTimeSlot(DateTime start, DateTime end) {
    final startTime = _formatTime(start);
    final endTime = _formatTime(end);
    return '$startTime - $endTime';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }
}

class AvailabilitySetupDialog extends StatefulWidget {
  const AvailabilitySetupDialog({Key? key}) : super(key: key);

  @override
  State<AvailabilitySetupDialog> createState() => _AvailabilitySetupDialogState();
}

class _AvailabilitySetupDialogState extends State<AvailabilitySetupDialog> {
  final List<Map<String, dynamic>> _schedule = [];
  final List<String> _daysOfWeek = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
  }

  void _initializeSchedule() {
    for (int i = 0; i < 7; i++) {
      _schedule.add({
        'dayOfWeek': _daysOfWeek[i],
        'isAvailable': i < 5, // Monday to Friday available by default
        'startTime': const TimeOfDay(hour: 9, minute: 0),
        'endTime': const TimeOfDay(hour: 17, minute: 0),
        'slotDurationMinutes': 10,
        'breakBetweenSlotsMinutes': 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup Availability Schedule'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: _schedule.length,
          itemBuilder: (context, index) {
            final day = _schedule[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: day['isAvailable'],
                          onChanged: (value) {
                            setState(() {
                              day['isAvailable'] = value ?? false;
                            });
                          },
                        ),
                        Text(
                          day['dayOfWeek'].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (day['isAvailable']) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Start Time'),
                              subtitle: Text(_formatTimeOfDay(day['startTime'])),
                              onTap: () => _selectTime(context, index, 'startTime'),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('End Time'),
                              subtitle: Text(_formatTimeOfDay(day['endTime'])),
                              onTap: () => _selectTime(context, index, 'endTime'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {'schedule': _schedule}),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, int index, String timeType) async {
    final currentTime = _schedule[index][timeType] as TimeOfDay;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (selectedTime != null) {
      setState(() {
        _schedule[index][timeType] = selectedTime;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }
}

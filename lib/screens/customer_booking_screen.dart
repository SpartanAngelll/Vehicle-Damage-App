import 'package:flutter/material.dart';
import '../models/booking_availability_models.dart';
import '../models/service_professional.dart';
import '../services/booking_availability_service.dart';
import '../widgets/booking_calendar_widget.dart';
import '../widgets/profile_avatar.dart';

class CustomerBookingScreen extends StatefulWidget {
  final ServiceProfessional professional;
  final String customerId;
  final String customerName;
  final String serviceTitle;
  final String serviceDescription;
  final double agreedPrice;
  final String location;

  const CustomerBookingScreen({
    Key? key,
    required this.professional,
    required this.customerId,
    required this.customerName,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.agreedPrice,
    required this.location,
  }) : super(key: key);

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  final BookingAvailabilityService _bookingService = BookingAvailabilityService();
  
  TimeSlot? _selectedSlot;
  bool _isBooking = false;
  String? _notes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book with ${widget.professional.fullName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildProfessionalInfo(),
          Expanded(
            child: BookingCalendarWidget(
              professionalId: widget.professional.id,
              onDateSelected: _onDateSelected,
              onSlotSelected: _onSlotSelected,
              showAvailableSlotsOnly: true,
            ),
          ),
          if (_selectedSlot != null) _buildBookingDetails(),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: const Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                profilePhotoUrl: widget.professional.profilePhotoUrl,
                radius: 30,
                fallbackIcon: Icons.person,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.professional.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.professional.businessName != null)
                      Text(
                        widget.professional.businessName!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${widget.professional.averageRating.toStringAsFixed(1)}'),
                        const SizedBox(width: 8),
                        Text('(${widget.professional.totalReviews} reviews)'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Service: ${widget.serviceTitle}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text('Price: \$${widget.agreedPrice.toStringAsFixed(2)}'),
          Text('Location: ${widget.location}'),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Time Slot',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  _formatTimeSlot(_selectedSlot!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any special instructions or requirements...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => _notes = value,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isBooking
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Booking...'),
                      ],
                    )
                  : const Text(
                      'Confirm Booking',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDateSelected(DateTime date, List<TimeSlot> slots) {
    // Reset selected slot when date changes
    setState(() {
      _selectedSlot = null;
    });
  }

  void _onSlotSelected(TimeSlot slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final booking = await _bookingService.bookTimeSlot(
        professionalId: widget.professional.id,
        customerId: widget.customerId,
        customerName: widget.customerName,
        professionalName: widget.professional.fullName,
        startTime: _selectedSlot!.startTime,
        endTime: _selectedSlot!.endTime,
        serviceTitle: widget.serviceTitle,
        serviceDescription: widget.serviceDescription,
        agreedPrice: widget.agreedPrice,
        location: widget.location,
        notes: _notes,
      );

      if (mounted) {
        Navigator.pop(context, booking);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  String _formatTimeSlot(TimeSlot slot) {
    final startTime = _formatTime(slot.startTime);
    final endTime = _formatTime(slot.endTime);
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


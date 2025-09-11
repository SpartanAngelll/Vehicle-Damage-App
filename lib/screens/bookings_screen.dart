import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/booking_models.dart';
import '../models/user_state.dart';
import '../services/chat_service.dart';
import '../services/payment_workflow_service.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserState>(
        builder: (context, userState, child) {
          if (userState.userId == null) {
            return const Center(
              child: Text('Please log in to view your bookings'),
            );
          }

          return StreamBuilder<List<Booking>>(
            stream: ChatService().getUserBookingsStream(userState.userId!),
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

              final bookings = snapshot.data ?? [];

              if (bookings.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No bookings yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your bookings will appear here once created',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _buildBookingCard(context, booking, userState);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, UserState userState) {
    final isCustomer = booking.customerId == userState.userId;
    final otherPartyName = isCustomer ? booking.professionalName : booking.customerName;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(context, booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'With $otherPartyName',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(booking.status),
                        width: 1,
                      ),
                    ),
                    child: FutureBuilder<bool>(
                      future: _checkBalanceDue(booking.id),
                      builder: (context, snapshot) {
                        String statusText = booking.status.name.toUpperCase();
                        Color statusColor = _getStatusColor(booking.status);
                        
                        if (snapshot.hasData && snapshot.data == true) {
                          statusText = 'AWAITING FINAL PAYMENT';
                          statusColor = Colors.orange;
                        }
                        
                        return Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Booking details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Price',
                      '${booking.agreedPrice.toStringAsFixed(2)} JMD',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Date',
                      DateFormat('MMM dd, yyyy').format(booking.scheduledStartTime),
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Time',
                      '${DateFormat('HH:mm').format(booking.scheduledStartTime)} - ${DateFormat('HH:mm').format(booking.scheduledEndTime)}',
                      Icons.access_time,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Location',
                      booking.location,
                      Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Deliverables preview
              if (booking.deliverables.isNotEmpty) ...[
                Text(
                  'Deliverables:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.deliverables.take(2).join(', ') + 
                  (booking.deliverables.length > 2 ? '...' : ''),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons based on status
              _buildActionButtons(context, booking, userState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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

  Widget _buildActionButtons(BuildContext context, Booking booking, UserState userState) {
    switch (booking.status) {
      case BookingStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateBookingStatus(context, booking, BookingStatus.cancelled),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateBookingStatus(context, booking, BookingStatus.confirmed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ),
          ],
        );
      case BookingStatus.confirmed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateBookingStatus(context, booking, BookingStatus.inProgress),
                child: const Text('Start Job'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateBookingStatus(context, booking, BookingStatus.cancelled),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        );
      case BookingStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateBookingStatus(context, booking, BookingStatus.completed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark Complete'),
              ),
            ),
          ],
        );
      case BookingStatus.completed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Job Completed',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case BookingStatus.cancelled:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Booking Cancelled',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
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
    }
  }

  Future<bool> _checkBalanceDue(String bookingId) async {
    try {
      final paymentService = PaymentWorkflowService.instance;
      await paymentService.initialize();
      return await paymentService.isBalancePaymentRequired(bookingId);
    } catch (e) {
      return false;
    }
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Service', booking.serviceTitle),
                      _buildDetailSection('Description', booking.serviceDescription),
                      _buildDetailSection('Price', '${booking.agreedPrice.toStringAsFixed(2)} JMD'),
                      _buildDetailSection('Date', DateFormat('EEEE, MMMM dd, yyyy').format(booking.scheduledStartTime)),
                      _buildDetailSection('Time', '${DateFormat('HH:mm').format(booking.scheduledStartTime)} - ${DateFormat('HH:mm').format(booking.scheduledEndTime)}'),
                      _buildDetailSection('Location', booking.location),
                      _buildDetailSection('Status', booking.status.name.toUpperCase()),
                      if (booking.deliverables.isNotEmpty)
                        _buildListSection('Deliverables', booking.deliverables),
                      if (booking.importantPoints.isNotEmpty)
                        _buildListSection('Important Points', booking.importantPoints),
                      if (booking.notes != null && booking.notes!.isNotEmpty)
                        _buildDetailSection('Notes', booking.notes!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(BuildContext context, Booking booking, BookingStatus newStatus) async {
    try {
      // Check if trying to complete job with balance due
      if (newStatus == BookingStatus.completed) {
        final paymentService = PaymentWorkflowService.instance;
        await paymentService.initialize();
        
        final isBalanceRequired = await paymentService.isBalancePaymentRequired(booking.id);
        
        if (isBalanceRequired) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot complete job: Customer must pay the remaining balance first.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }
      
      await ChatService().updateBookingStatus(booking.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${newStatus.name} successfully'),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking: $e')),
        );
      }
    }
  }
}

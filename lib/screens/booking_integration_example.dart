import 'package:flutter/material.dart';
import '../models/service_professional.dart';
import '../services/chat_service.dart';
import '../services/booking_availability_service.dart';
import 'customer_booking_screen.dart';
import 'professional_booking_management_screen.dart';

/// Example screen showing how to integrate the booking system
class BookingIntegrationExample extends StatefulWidget {
  const BookingIntegrationExample({Key? key}) : super(key: key);

  @override
  State<BookingIntegrationExample> createState() => _BookingIntegrationExampleState();
}

class _BookingIntegrationExampleState extends State<BookingIntegrationExample> {
  final ChatService _chatService = ChatService();
  final BookingAvailabilityService _availabilityService = BookingAvailabilityService();
  
  List<ServiceProfessional> _professionals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    setState(() => _isLoading = true);
    
    try {
      // This would typically come from your existing service
      // For demonstration, we'll create a mock professional
      final mockProfessional = ServiceProfessional(
        id: 'demo_professional_1',
        userId: 'demo_professional_1',
        email: 'demo@example.com',
        fullName: 'John Smith',
        categoryIds: ['mechanics'],
        specializations: ['Auto Repair', 'Engine Diagnostics'],
        businessName: 'Smith Auto Repair',
        averageRating: 4.8,
        totalReviews: 150,
        isVerified: true,
        isAvailable: true,
      );
      
      setState(() {
        _professionals = [mockProfessional];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading professionals: $e')),
        );
      }
    }
  }

  Future<void> _setupProfessionalAvailability(ServiceProfessional professional) async {
    try {
      // Example weekly schedule
      final weeklySchedule = [
        {
          'dayOfWeek': 'monday',
          'isAvailable': true,
          'startTime': const TimeOfDay(hour: 9, minute: 0),
          'endTime': const TimeOfDay(hour: 17, minute: 0),
          'slotDurationMinutes': 10,
          'breakBetweenSlotsMinutes': 0,
        },
        {
          'dayOfWeek': 'tuesday',
          'isAvailable': true,
          'startTime': const TimeOfDay(hour: 9, minute: 0),
          'endTime': const TimeOfDay(hour: 17, minute: 0),
          'slotDurationMinutes': 10,
          'breakBetweenSlotsMinutes': 0,
        },
        {
          'dayOfWeek': 'wednesday',
          'isAvailable': true,
          'startTime': const TimeOfDay(hour: 9, minute: 0),
          'endTime': const TimeOfDay(hour: 17, minute: 0),
          'slotDurationMinutes': 10,
          'breakBetweenSlotsMinutes': 0,
        },
        {
          'dayOfWeek': 'thursday',
          'isAvailable': true,
          'startTime': const TimeOfDay(hour: 9, minute: 0),
          'endTime': const TimeOfDay(hour: 17, minute: 0),
          'slotDurationMinutes': 10,
          'breakBetweenSlotsMinutes': 0,
        },
        {
          'dayOfWeek': 'friday',
          'isAvailable': true,
          'startTime': const TimeOfDay(hour: 9, minute: 0),
          'endTime': const TimeOfDay(hour: 17, minute: 0),
          'slotDurationMinutes': 10,
          'breakBetweenSlotsMinutes': 0,
        },
        {
          'dayOfWeek': 'saturday',
          'isAvailable': true,
          'startTime': const TimeOfDay(hour: 10, minute: 0),
          'endTime': const TimeOfDay(hour: 15, minute: 0),
          'slotDurationMinutes': 10,
          'breakBetweenSlotsMinutes': 0,
        },
        {
          'dayOfWeek': 'sunday',
          'isAvailable': false,
          'startTime': const TimeOfDay(hour: 10, minute: 0),
          'endTime': const TimeOfDay(hour: 15, minute: 0),
          'slotDurationMinutes': 10,
          'breakBetweenSlotsMinutes': 0,
        },
      ];

      await _chatService.setupProfessionalAvailability(
        professionalId: professional.id,
        weeklySchedule: weeklySchedule,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability schedule set up successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCustomerBooking(ServiceProfessional professional) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerBookingScreen(
          professional: professional,
          customerId: 'demo_customer_1',
          customerName: 'Demo Customer',
          serviceTitle: 'Engine Diagnostic',
          serviceDescription: 'Complete engine diagnostic and repair',
          agreedPrice: 150.0,
          location: '123 Main St, City, State',
        ),
      ),
    );
  }

  void _navigateToProfessionalManagement(ServiceProfessional professional) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalBookingManagementScreen(
          professionalId: professional.id,
          professionalName: professional.fullName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking System Integration'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Booking System Integration Example',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This example demonstrates how to integrate the new booking system with availability tracking and calendar functionality.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ..._professionals.map((professional) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              child: Text(professional.fullName[0]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    professional.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (professional.businessName != null)
                                    Text(professional.businessName!),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${professional.averageRating.toStringAsFixed(1)}'),
                                      const SizedBox(width: 8),
                                      Text('(${professional.totalReviews} reviews)'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Actions:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _setupProfessionalAvailability(professional),
                              icon: const Icon(Icons.schedule),
                              label: const Text('Setup Availability'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToCustomerBooking(professional),
                              icon: const Icon(Icons.book_online),
                              label: const Text('Customer Booking'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToProfessionalManagement(professional),
                              icon: const Icon(Icons.manage_accounts),
                              label: const Text('Manage Bookings'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Features Implemented:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('✅ Time slot management with conflict detection'),
                        Text('✅ Calendar widget for displaying available slots'),
                        Text('✅ Professional booking management interface'),
                        Text('✅ Customer booking interface with slot selection'),
                        Text('✅ Database schema for availability tracking'),
                        Text('✅ Integration with existing chat service'),
                        Text('✅ Automatic time slot generation'),
                        Text('✅ Double booking prevention'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/booking_models.dart';
import '../models/chat_models.dart';
import '../services/firebase_firestore_service.dart';
import 'my_bookings_screen.dart';

class BookingSummaryScreen extends StatefulWidget {
  final JobSummary jobSummary;
  final ChatRoom chatRoom;
  final String bookingId;

  const BookingSummaryScreen({
    super.key,
    required this.jobSummary,
    required this.chatRoom,
    required this.bookingId,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  bool _isSaving = false;
  bool _isAddingToCalendar = false;
  String? _savedBookingId;

  @override
  void initState() {
    super.initState();
    _saveBookingToFirebase();
  }

  Future<void> _saveBookingToFirebase() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      // Check if booking already exists in Firebase
      final existingBooking = await _firestoreService.getBookingById(widget.bookingId);
      
      if (existingBooking != null) {
        // Booking already exists, just update the status
        final bookingStatus = await _determineBookingStatus();
        await _firestoreService.updateBookingStatus(widget.bookingId, bookingStatus);
        print('✅ [BookingSummary] Updated existing booking status: $bookingStatus');
      } else {
        // Determine the correct booking status
        final bookingStatus = await _determineBookingStatus();
        
        final bookingData = {
          'id': widget.bookingId,
          'chatRoomId': widget.chatRoom.id,
          'estimateId': widget.jobSummary.estimateId,
          'customerId': widget.jobSummary.customerId,
          'professionalId': widget.jobSummary.professionalId,
          'serviceName': widget.jobSummary.rawAnalysis?['service'] ?? 'Service Request',
          'serviceDescription': widget.jobSummary.conversationSummary,
          'date': widget.jobSummary.extractedStartTime?.toIso8601String(),
          'time': widget.jobSummary.extractedStartTime?.toIso8601String(),
          'endTime': widget.jobSummary.extractedEndTime?.toIso8601String(),
          'price': widget.jobSummary.extractedPrice,
          'currency': widget.jobSummary.rawAnalysis?['currency'] ?? 'JMD',
          'location': widget.jobSummary.extractedLocation ?? 'To be confirmed',
          'deliverables': widget.jobSummary.extractedDeliverables,
          'importantPoints': widget.jobSummary.extractedImportantPoints,
          'status': bookingStatus,
          'confidenceScore': widget.jobSummary.confidenceScore,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'rawAnalysis': widget.jobSummary.rawAnalysis,
          'finalTravelMode': widget.jobSummary.finalTravelMode?.name,
          'customerAddress': widget.jobSummary.customerAddress,
          'shopAddress': widget.jobSummary.shopAddress,
          'travelFee': widget.jobSummary.travelFee,
        };

      // Debug logging
      print('🔍 [BookingSummary] Saving booking data: $bookingData');
      print('🔍 [BookingSummary] Travel mode: ${widget.jobSummary.finalTravelMode?.name}');
      print('🔍 [BookingSummary] Customer address: ${widget.jobSummary.customerAddress}');
      print('🔍 [BookingSummary] Shop address: ${widget.jobSummary.shopAddress}');
      print('🔍 [BookingSummary] Travel fee: ${widget.jobSummary.travelFee}');
      
      await _firestoreService.saveBooking(bookingData);
      setState(() {
        _savedBookingId = widget.bookingId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      }
    } catch (e) {
      print('❌ [BookingSummary] Error saving booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Determine the correct booking status based on job completion and review status
  Future<String> _determineBookingStatus() async {
    try {
      // Check if the job has been completed
      final isJobCompleted = await _firestoreService.isJobCompleted(widget.bookingId);
      
      if (isJobCompleted) {
        // Check if the job has been reviewed (accepted as completed by customer)
        final isJobReviewed = await _firestoreService.isJobReviewed(widget.bookingId);
        
        if (isJobReviewed) {
          return 'reviewed'; // Purple status - job completed and reviewed
        } else {
          return 'completed'; // Green status - job completed but not yet reviewed
        }
      } else {
        return 'confirmed'; // Green status - job confirmed but not completed
      }
    } catch (e) {
      print('❌ [BookingSummary] Error determining booking status: $e');
      // Default to confirmed if there's an error
      return 'confirmed';
    }
  }

  Future<void> _addToCalendar(CalendarType calendarType) async {
    if (_isAddingToCalendar) return;

    setState(() {
      _isAddingToCalendar = true;
    });

    try {
      // Check current permission status first
      final currentStatus = await Permission.calendar.status;
      print('🔍 [BookingSummary] Current calendar permission status: $currentStatus');
      
      // Request calendar permission using permission_handler
      final permission = await Permission.calendar.request();
      print('🔍 [BookingSummary] Calendar permission request result: $permission');
      
      if (permission != PermissionStatus.granted) {
        print('❌ [BookingSummary] Calendar permissions denied: $permission');
        if (mounted) {
          String message = 'Calendar permissions are required to add events.';
          if (permission == PermissionStatus.permanentlyDenied) {
            message += ' Please enable in app settings.';
          } else if (permission == PermissionStatus.denied) {
            message += ' Please try again and grant permission when prompted.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: permission == PermissionStatus.permanentlyDenied
                  ? SnackBarAction(
                      label: 'Settings',
                      onPressed: () => openAppSettings(),
                    )
                  : null,
            ),
          );
        }
        return;
      }
      
      print('✅ [BookingSummary] Calendar permissions granted');
      
      final deviceCalendarPlugin = DeviceCalendarPlugin();

      // Get calendars
      final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        final calendars = calendarsResult.data!;
        
        // Find the appropriate calendar
        Calendar? targetCalendar;
        if (calendarType == CalendarType.google) {
          targetCalendar = calendars.firstWhere(
            (cal) => cal.name?.toLowerCase().contains('google') ?? false,
            orElse: () => calendars.first,
          );
        } else {
          targetCalendar = calendars.first;
        }

        if (targetCalendar != null) {
          // Create event
          final startTime = widget.jobSummary.extractedStartTime;
          final endTime = widget.jobSummary.extractedEndTime ?? 
                         startTime?.add(const Duration(hours: 1));
          
          if (startTime != null) {
            final event = Event(
              targetCalendar.id,
              title: widget.jobSummary.rawAnalysis?['service'] ?? 'Service Request',
              description: _buildEventDescription(),
              start: tz.TZDateTime.from(startTime, tz.UTC),
              end: tz.TZDateTime.from(endTime ?? startTime.add(const Duration(hours: 1)), tz.UTC),
              location: widget.jobSummary.extractedLocation ?? 'To be confirmed',
              allDay: false,
            );

            // Save event
            final createEventResult = await deviceCalendarPlugin.createOrUpdateEvent(event);
            if (createEventResult?.isSuccess == true) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to ${calendarType.name} calendar!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              throw Exception('Failed to create calendar event');
            }
          } else {
            throw Exception('Invalid start time for calendar event');
          }
        } else {
          throw Exception('No suitable calendar found');
        }
      } else {
        throw Exception('Failed to retrieve calendars');
      }
    } catch (e) {
      print('❌ [BookingSummary] Error adding to calendar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCalendar = false;
        });
      }
    }
  }

  Future<void> _exportToICal() async {
    try {
      final icalContent = _generateICalContent();
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: icalContent));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('iCal content copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [BookingSummary] Error exporting to iCal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export to iCal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildEventDescription() {
    final description = StringBuffer();
    description.writeln(widget.jobSummary.conversationSummary);
    description.writeln();
    description.writeln('Price: \$${widget.jobSummary.extractedPrice?.toStringAsFixed(2) ?? 'TBD'}');
    description.writeln();
    
    if (widget.jobSummary.extractedDeliverables.isNotEmpty) {
      description.writeln('Deliverables:');
      for (final deliverable in widget.jobSummary.extractedDeliverables) {
        description.writeln('• $deliverable');
      }
      description.writeln();
    }
    
    if (widget.jobSummary.extractedImportantPoints.isNotEmpty) {
      description.writeln('Important Points:');
      for (final point in widget.jobSummary.extractedImportantPoints) {
        description.writeln('• $point');
      }
    }
    
    return description.toString();
  }

  String _generateICalContent() {
    final startTime = widget.jobSummary.extractedStartTime;
    final endTime = widget.jobSummary.extractedEndTime ?? 
                   startTime?.add(const Duration(hours: 1));
    
    if (startTime == null) return '';
    
    final startUtc = startTime.toUtc();
    final endUtc = endTime?.toUtc() ?? startUtc.add(const Duration(hours: 1));
    
    return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Vehicle Damage App//Booking//EN
BEGIN:VEVENT
UID:${widget.bookingId}@vehicle-damage-app.com
DTSTART:${_formatDateTimeForICal(startUtc)}
DTEND:${_formatDateTimeForICal(endUtc)}
SUMMARY:${widget.jobSummary.rawAnalysis?['service'] ?? 'Service Request'}
DESCRIPTION:${_buildEventDescription().replaceAll('\n', '\\n')}
LOCATION:${widget.jobSummary.extractedLocation ?? 'To be confirmed'}
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR''';
  }

  String _formatDateTimeForICal(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}'
           '${dateTime.month.toString().padLeft(2, '0')}'
           '${dateTime.day.toString().padLeft(2, '0')}T'
           '${dateTime.hour.toString().padLeft(2, '0')}'
           '${dateTime.minute.toString().padLeft(2, '0')}'
           '${dateTime.second.toString().padLeft(2, '0')}Z';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_savedBookingId != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _showShareOptions,
              tooltip: 'Share Booking',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                final isDark = theme.brightness == Brightness.dark;
                final successColor = isDark 
                    ? colorScheme.secondary 
                    : colorScheme.secondary;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: successColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: successColor,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Booking Confirmed!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: successColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your service has been successfully booked',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Booking Details
            _buildSection(
              'Service Details',
              Icons.work,
              [
                _buildDetailRow('Service', widget.jobSummary.rawAnalysis?['service'] ?? 'Service Request'),
                _buildDetailRow('Description', widget.jobSummary.conversationSummary),
                _buildDetailRow('Date & Time', _formatDateTime(widget.jobSummary.extractedStartTime)),
                if (widget.jobSummary.extractedEndTime != null)
                  _buildDetailRow('End Time', _formatDateTime(widget.jobSummary.extractedEndTime)),
                _buildDetailRow('Location', widget.jobSummary.extractedLocation ?? 'To be confirmed'),
                _buildDetailRow('Price', '\$${widget.jobSummary.extractedPrice?.toStringAsFixed(2) ?? 'TBD'}'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Deliverables
            if (widget.jobSummary.extractedDeliverables.isNotEmpty)
              _buildSection(
                'Deliverables',
                Icons.checklist,
                widget.jobSummary.extractedDeliverables.map((item) => 
                  _buildDetailRow('•', item, isBullet: true)
                ).toList(),
              ),
            
            if (widget.jobSummary.extractedDeliverables.isNotEmpty)
              const SizedBox(height: 20),
            
            // Important Points
            if (widget.jobSummary.extractedImportantPoints.isNotEmpty)
              _buildSection(
                'Important Points',
                Icons.info,
                widget.jobSummary.extractedImportantPoints.map((item) => 
                  _buildDetailRow('•', item, isBullet: true)
                ).toList(),
              ),
            
            if (widget.jobSummary.extractedImportantPoints.isNotEmpty)
              const SizedBox(height: 20),
            
            // Calendar Integration
            _buildSection(
              'Add to Calendar',
              Icons.calendar_today,
              [
                _buildCalendarButton(
                  'Google Calendar',
                  Icons.calendar_view_day,
                  Colors.blue,
                  () => _addToCalendar(CalendarType.google),
                ),
                _buildCalendarButton(
                  'Device Calendar',
                  Icons.calendar_month,
                  Colors.green,
                  () => _addToCalendar(CalendarType.local),
                ),
                _buildCalendarButton(
                  'Export iCal',
                  Icons.download,
                  Colors.orange,
                  _exportToICal,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // My Bookings Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToMyBookings,
                icon: const Icon(Icons.list_alt),
                label: const Text('View My Bookings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status Indicators
            if (_isSaving)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Saving booking...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_isAddingToCalendar)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Adding to calendar...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainerHigh 
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBullet = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBullet)
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            )
          else
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          label: Text(title),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Booking Details'),
              onTap: () {
                Navigator.pop(context);
                _copyBookingDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Share as iCal'),
              onTap: () {
                Navigator.pop(context);
                _exportToICal();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyBookingDetails() {
    final details = '''
Service: ${widget.jobSummary.rawAnalysis?['service'] ?? 'Service Request'}
Date & Time: ${_formatDateTime(widget.jobSummary.extractedStartTime)}
Location: ${widget.jobSummary.extractedLocation ?? 'To be confirmed'}
Price: \$${widget.jobSummary.extractedPrice?.toStringAsFixed(2) ?? 'TBD'}

Description:
${widget.jobSummary.conversationSummary}

${widget.jobSummary.extractedDeliverables.isNotEmpty ? 'Deliverables:\n${widget.jobSummary.extractedDeliverables.map((d) => '• $d').join('\n')}\n' : ''}
${widget.jobSummary.extractedImportantPoints.isNotEmpty ? 'Important Points:\n${widget.jobSummary.extractedImportantPoints.map((p) => '• $p').join('\n')}' : ''}
''';
    
    Clipboard.setData(ClipboardData(text: details));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking details copied to clipboard!')),
    );
  }

  void _navigateToMyBookings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyBookingsScreen(),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'TBD';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

enum CalendarType {
  google,
  local,
}

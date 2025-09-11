import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_models.dart';
import '../models/booking_models.dart';
import '../models/service.dart';
import '../models/invoice_models.dart';
import '../widgets/travel_mode_selector.dart';
import '../widgets/deposit_payment_dialog.dart';
import '../services/payment_workflow_service.dart';

class BookingConfirmationDialog extends StatefulWidget {
  final JobSummary jobSummary;
  final ChatRoom chatRoom;

  const BookingConfirmationDialog({
    Key? key,
    required this.jobSummary,
    required this.chatRoom,
  }) : super(key: key);

  @override
  State<BookingConfirmationDialog> createState() => _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog> {
  late double _agreedPrice;
  late DateTime _startTime;
  late DateTime _endTime;
  late String _location;
  late List<String> _deliverables;
  late List<String> _importantPoints;
  
  // Travel mode selection
  TravelMode? _selectedTravelMode;
  String? _customerAddress;
  double? _travelFee;
  Service? _service;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    _agreedPrice = widget.jobSummary.extractedPrice;
    _startTime = widget.jobSummary.extractedStartTime ?? 
        DateTime.now().add(const Duration(days: 1));
    _endTime = widget.jobSummary.extractedEndTime ?? 
        _startTime.add(const Duration(hours: 2));
    _location = widget.jobSummary.extractedLocation ?? '';
    _deliverables = List.from(widget.jobSummary.extractedDeliverables);
    _importantPoints = List.from(widget.jobSummary.extractedImportantPoints);
    
    // Create a mock service for travel mode selection
    _service = Service(
      id: 'mock-service',
      name: widget.jobSummary.rawAnalysis?['service'] ?? 'Service Request',
      description: widget.jobSummary.conversationSummary,
      categoryId: 'general',
      professionalId: widget.jobSummary.professionalId,
      basePrice: _agreedPrice,
      defaultTravel: TravelMode.customerTravels,
      proTravelsAvailable: true,
      travelFee: 25.0,
      travelRadiusKm: 50.0,
      shopAddress: '123 Main Street',
      shopCity: 'Kingston',
      shopState: 'Kingston',
      shopPostalCode: 'JM12345',
    );
    
    _selectedTravelMode = _service!.defaultTravel;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Confidence Score
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getConfidenceColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getConfidenceColor()),
              ),
              child: Row(
                children: [
                  Icon(
                    _getConfidenceIcon(),
                    color: _getConfidenceColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence: ${(widget.jobSummary.confidenceScore * 100).toInt()}%',
                    style: TextStyle(
                      color: _getConfidenceColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Conversation Summary
                    _buildSection(
                      'Conversation Summary',
                      Icons.chat,
                      widget.jobSummary.conversationSummary,
                    ),
                    const SizedBox(height: 24),
                    
                    // Price
                    _buildEditableSection(
                      'Agreed Price',
                      Icons.attach_money,
                      '${_agreedPrice.toStringAsFixed(2)} JMD',
                      () => _editPrice(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Schedule
                    _buildEditableSection(
                      'Start Time',
                      Icons.schedule,
                      DateFormat('MMM dd, yyyy - HH:mm').format(_startTime),
                      () => _editStartTime(),
                    ),
                    const SizedBox(height: 16),
                    _buildEditableSection(
                      'End Time',
                      Icons.schedule,
                      DateFormat('MMM dd, yyyy - HH:mm').format(_endTime),
                      () => _editEndTime(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Location
                    _buildEditableSection(
                      'Location',
                      Icons.location_on,
                      _location.isEmpty ? 'Not specified' : _location,
                      () => _editLocation(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Travel Mode Selection
                    if (_service != null) ...[
                      TravelModeSelector(
                        key: const ValueKey('travel_mode_selector'),
                        service: _service!,
                        selectedMode: _selectedTravelMode,
                        onModeChanged: (mode, address, fee) {
                          setState(() {
                            _selectedTravelMode = mode;
                            _customerAddress = address;
                            _travelFee = fee;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Deliverables
                    _buildListSection(
                      'Deliverables',
                      Icons.checklist,
                      _deliverables,
                      () => _editDeliverables(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Important Points
                    _buildListSection(
                      'Important Points',
                      Icons.info,
                      _importantPoints,
                      () => _editImportantPoints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm Booking'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableSection(String title, IconData icon, String content, VoidCallback onEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              tooltip: 'Edit',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, IconData icon, List<String> items, VoidCallback onEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              tooltip: 'Edit',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: items.isEmpty
              ? const Text(
                  'No items specified',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )).toList(),
                ),
        ),
      ],
    );
  }

  Color _getConfidenceColor() {
    final score = widget.jobSummary.confidenceScore;
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getConfidenceIcon() {
    final score = widget.jobSummary.confidenceScore;
    if (score >= 0.8) return Icons.check_circle;
    if (score >= 0.6) return Icons.warning;
    return Icons.error;
  }

  void _editPrice() {
    showDialog(
      context: context,
      builder: (context) => _EditPriceDialog(
        initialPrice: _agreedPrice,
        onSave: (price) {
          setState(() {
            _agreedPrice = price;
          });
        },
      ),
    );
  }

  void _editStartTime() {
    showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_startTime),
        ).then((time) {
          if (time != null) {
            setState(() {
              _startTime = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }
        });
      }
    });
  }

  void _editEndTime() {
    showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_endTime),
        ).then((time) {
          if (time != null) {
            setState(() {
              _endTime = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }
        });
      }
    });
  }

  void _editLocation() {
    showDialog(
      context: context,
      builder: (context) => _EditTextDialog(
        title: 'Edit Location',
        initialValue: _location,
        onSave: (value) {
          setState(() {
            _location = value;
          });
        },
      ),
    );
  }

  void _editDeliverables() {
    showDialog(
      context: context,
      builder: (context) => _EditListDialog(
        title: 'Edit Deliverables',
        initialItems: _deliverables,
        onSave: (items) {
          setState(() {
            _deliverables = items;
          });
        },
      ),
    );
  }

  void _editImportantPoints() {
    showDialog(
      context: context,
      builder: (context) => _EditListDialog(
        title: 'Edit Important Points',
        initialItems: _importantPoints,
        onSave: (items) {
          setState(() {
            _importantPoints = items;
          });
        },
      ),
    );
  }

  void _confirmBooking() async {
    // Create updated job summary with edited values
    final updatedSummary = JobSummary(
      id: widget.jobSummary.id,
      chatRoomId: widget.jobSummary.chatRoomId,
      estimateId: widget.jobSummary.estimateId,
      customerId: widget.jobSummary.customerId,
      professionalId: widget.jobSummary.professionalId,
      originalEstimate: widget.jobSummary.originalEstimate,
      conversationSummary: widget.jobSummary.conversationSummary,
      extractedPrice: _agreedPrice,
      extractedStartTime: _startTime,
      extractedEndTime: _endTime,
      extractedLocation: _location,
      extractedDeliverables: _deliverables,
      extractedImportantPoints: _importantPoints,
      confidenceScore: widget.jobSummary.confidenceScore,
      createdAt: widget.jobSummary.createdAt,
      rawAnalysis: widget.jobSummary.rawAnalysis,
      finalTravelMode: _selectedTravelMode,
      customerAddress: _customerAddress,
      shopAddress: _service?.fullShopAddress,
      travelFee: _travelFee,
    );

    // Close the dialog first
    Navigator.of(context).pop(updatedSummary);

    // Check if deposit is required and show payment dialog
    await _checkAndShowDepositPayment(updatedSummary);
  }

  Future<void> _checkAndShowDepositPayment(JobSummary jobSummary) async {
    try {
      // Initialize payment workflow service
      final paymentService = PaymentWorkflowService.instance;
      await paymentService.initialize();

      // Create invoice in PostgreSQL
      final invoice = await paymentService.createInvoiceFromBooking(
        bookingId: jobSummary.id,
        customerId: jobSummary.customerId,
        professionalId: jobSummary.professionalId,
        totalAmount: jobSummary.extractedPrice,
        depositPercentage: 0, // For now, no deposit required by default
        currency: 'JMD',
        notes: 'Invoice created for booking confirmation',
      );

      // Check if deposit is required
      if (invoice.isDepositRequired && !invoice.isDepositPaid) {
        // Show deposit payment dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => DepositPaymentDialog(
              invoice: invoice,
              onDepositPaid: (paymentMethod) async {
                try {
                  await paymentService.processDepositPayment(
                    bookingId: jobSummary.id,
                    paymentMethod: paymentMethod,
                    notes: 'Deposit payment via ${paymentMethod.name}',
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deposit payment successful!'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              },
            ),
          );
        }
      } else {
        // No deposit required, show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking confirmed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [BookingConfirmation] Failed to create invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EditPriceDialog extends StatefulWidget {
  final double initialPrice;
  final Function(double) onSave;

  const _EditPriceDialog({
    required this.initialPrice,
    required this.onSave,
  });

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Price'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Price',
          prefixText: '\$',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final price = double.tryParse(_controller.text) ?? 0.0;
            widget.onSave(price);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _EditTextDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final Function(String) onSave;

  const _EditTextDialog({
    required this.title,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<_EditTextDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Value',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _EditListDialog extends StatefulWidget {
  final String title;
  final List<String> initialItems;
  final Function(List<String>) onSave;

  const _EditListDialog({
    required this.title,
    required this.initialItems,
    required this.onSave,
  });

  @override
  State<_EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<_EditListDialog> {
  late List<String> _items;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Add item',
                    ),
                    onSubmitted: _addItem,
                  ),
                ),
                IconButton(
                  onPressed: () => _addItem(_controller.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_items[index]),
                    trailing: IconButton(
                      onPressed: () => _removeItem(index),
                      icon: const Icon(Icons.remove),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_items);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addItem(String text) {
    if (text.trim().isNotEmpty) {
      setState(() {
        _items.add(text.trim());
        _controller.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }
}

import 'package:flutter/material.dart';
import '../models/booking_availability_models.dart';
import '../services/booking_availability_service.dart';

class BookingCalendarWidget extends StatefulWidget {
  final String professionalId;
  final Function(DateTime, List<TimeSlot>)? onDateSelected;
  final Function(TimeSlot)? onSlotSelected;
  final bool showAvailableSlotsOnly;
  final DateTime? initialDate;

  const BookingCalendarWidget({
    Key? key,
    required this.professionalId,
    this.onDateSelected,
    this.onSlotSelected,
    this.showAvailableSlotsOnly = true,
    this.initialDate,
  }) : super(key: key);

  @override
  State<BookingCalendarWidget> createState() => _BookingCalendarWidgetState();
}

class _BookingCalendarWidgetState extends State<BookingCalendarWidget> {
  final BookingAvailabilityService _bookingService = BookingAvailabilityService();
  
  DateTime _currentMonth = DateTime.now();
  List<CalendarDay> _calendarDays = [];
  List<TimeSlot> _selectedDateSlots = [];
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialDate ?? DateTime.now();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);
    
    try {
      final calendarDays = await _bookingService.getCalendarDataForMonth(
        professionalId: widget.professionalId,
        month: _currentMonth,
      );
      
      setState(() {
        _calendarDays = calendarDays;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calendar: $e')),
        );
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadCalendarData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadCalendarData();
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedDateSlots = []; // Clear previous slots while loading
    });
    
    // Try to find the day in the calendar data
    final day = _calendarDays.firstWhere(
      (d) => d.date.year == date.year && d.date.month == date.month && d.date.day == date.day,
      orElse: () => CalendarDay(
        date: date,
        availableSlots: [],
        bookedSlots: [],
      ),
    );
    
    // If the day has slots, use them
    if (day.allSlots.isNotEmpty) {
      setState(() {
        _selectedDateSlots = widget.showAvailableSlotsOnly ? day.availableSlots : day.allSlots;
      });
      widget.onDateSelected?.call(date, _selectedDateSlots);
      return;
    }
    
    // If no slots exist in calendar data, fetch/generate them on-the-fly
    try {
      List<TimeSlot> slots;
      
      if (widget.showAvailableSlotsOnly) {
        // For customer view, only show available slots
        slots = await _bookingService.getAvailableSlotsForDate(
          professionalId: widget.professionalId,
          date: date,
        );
      } else {
        // For professional view, show all slots (available + booked)
        slots = await _bookingService.generateSlotsForDate(
          professionalId: widget.professionalId,
          date: date,
        );
      }
      
      setState(() {
        _selectedDateSlots = slots;
      });
      
      widget.onDateSelected?.call(date, _selectedDateSlots);
    } catch (e) {
      print('Error loading slots for date: $e');
      // If generation fails, show empty slots
      setState(() {
        _selectedDateSlots = [];
      });
      widget.onDateSelected?.call(date, _selectedDateSlots);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(),
        _buildCalendarGrid(),
        if (_selectedDate != null) _buildTimeSlotsList(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          _buildCalendarDays(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    // Convert weekday (1=Monday, 7=Sunday) to column index (0=Monday, 6=Sunday)
    final firstWeekday = firstDayOfMonth.weekday; // 1-7
    final firstDayColumn = (firstWeekday - 1) % 7; // 0-6
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate the number of rows needed
    final totalCells = firstDayColumn + daysInMonth;
    final rows = (totalCells / 7).ceil();
    
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final dayIndex = rowIndex * 7 + colIndex;
            final dayNumber = dayIndex - firstDayColumn + 1;
            
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 50));
            }
            
            final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
            final calendarDay = _calendarDays.firstWhere(
              (d) => d.date.year == date.year && d.date.month == date.month && d.date.day == date.day,
              orElse: () => CalendarDay(
                date: date,
                availableSlots: [],
                bookedSlots: [],
              ),
            );
            
            return Expanded(
              child: _buildDayCell(calendarDay),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(CalendarDay day) {
    final isSelected = _selectedDate != null &&
        day.date.year == _selectedDate!.year &&
        day.date.month == _selectedDate!.month &&
        day.date.day == _selectedDate!.day;
    
    final isToday = day.isToday;
    final isPast = day.isPast;
    final hasSlots = day.hasAvailableSlots;
    
    return GestureDetector(
      onTap: isPast ? null : () => _selectDate(day.date),
      child: Container(
        height: 50,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getDayColor(day, isSelected, isToday, isPast),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: _getDayTextColor(day, isSelected, isToday, isPast),
              ),
            ),
            if (hasSlots && !isPast)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getDayColor(CalendarDay day, bool isSelected, bool isToday, bool isPast) {
    if (isSelected) return Colors.blue.withOpacity(0.2);
    if (isToday) return Colors.blue.withOpacity(0.1);
    if (isPast) return Colors.grey.withOpacity(0.1);
    if (day.isBlocked) return Colors.red.withOpacity(0.1);
    return Colors.transparent;
  }

  Color _getDayTextColor(CalendarDay day, bool isSelected, bool isToday, bool isPast) {
    if (isSelected) return Colors.blue;
    if (isToday) return Colors.blue;
    if (isPast) return Colors.grey;
    if (day.isBlocked) return Colors.red;
    // Use theme-aware color for better visibility on web
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  Widget _buildTimeSlotsList() {
    if (_selectedDateSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.showAvailableSlotsOnly 
              ? 'No available time slots for this date'
              : 'No time slots configured for this date. Please set up your availability schedule.',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final availableCount = _selectedDateSlots.where((s) => s.isAvailable).length;
    final bookedCount = _selectedDateSlots.where((s) => !s.isAvailable).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.showAvailableSlotsOnly
                ? 'Available Time Slots - ${_formatDate(_selectedDate!)}'
                : 'Time Slots - ${_formatDate(_selectedDate!)} (${availableCount} available, ${bookedCount} booked)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedDateSlots.map((slot) => _buildTimeSlotChip(slot)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip(TimeSlot slot) {
    final isAvailable = slot.isAvailable;
    
    return GestureDetector(
      onTap: isAvailable ? () => widget.onSlotSelected?.call(slot) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatTimeSlot(slot),
          style: TextStyle(
            color: isAvailable ? Colors.white : Colors.grey.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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


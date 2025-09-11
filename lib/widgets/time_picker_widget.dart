import 'package:flutter/material.dart';

class TimePickerWidget extends StatefulWidget {
  final int initialDays;
  final int initialHours;
  final int initialMinutes;
  final Function(int days, int hours, int minutes) onTimeChanged;
  final double height;

  const TimePickerWidget({
    Key? key,
    this.initialDays = 0,
    this.initialHours = 0,
    this.initialMinutes = 0,
    required this.onTimeChanged,
    this.height = 200,
  }) : super(key: key);

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late FixedExtentScrollController _daysController;
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;

  int _selectedDays = 0;
  int _selectedHours = 0;
  int _selectedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
    _selectedHours = widget.initialHours;
    _selectedMinutes = widget.initialMinutes;
    
    _daysController = FixedExtentScrollController(initialItem: _selectedDays);
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(initialItem: _selectedMinutes);
  }

  @override
  void dispose() {
    _daysController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _onTimeChanged() {
    widget.onTimeChanged(_selectedDays, _selectedHours, _selectedMinutes);
  }

  Widget _buildPickerColumn({
    required String label,
    required FixedExtentScrollController controller,
    required int maxValue,
    required Function(int) onChanged,
    required int selectedValue,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[600]!, width: 1),
              ),
              child: ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 50,
                perspective: 0.005,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    onChanged(index);
                    _onTimeChanged();
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index > maxValue) return null;
                    
                    final isSelected = index == selectedValue;
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: isSelected ? 24 : 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.white60,
                        ),
                      ),
                    );
                  },
                  childCount: maxValue + 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildPickerColumn(
            label: 'Days',
            controller: _daysController,
            maxValue: 30, // Max 30 days
            onChanged: (value) => _selectedDays = value,
            selectedValue: _selectedDays,
          ),
          const SizedBox(width: 16),
          _buildPickerColumn(
            label: 'Hours',
            controller: _hoursController,
            maxValue: 23, // Max 23 hours
            onChanged: (value) => _selectedHours = value,
            selectedValue: _selectedHours,
          ),
          const SizedBox(width: 16),
          _buildPickerColumn(
            label: 'Min',
            controller: _minutesController,
            maxValue: 59, // Max 59 minutes
            onChanged: (value) => _selectedMinutes = value,
            selectedValue: _selectedMinutes,
          ),
        ],
      ),
    );
  }
}

// Helper class to convert time to total minutes for storage
class TimeHelper {
  static int toTotalMinutes(int days, int hours, int minutes) {
    return (days * 24 * 60) + (hours * 60) + minutes;
  }

  static Map<String, int> fromTotalMinutes(int totalMinutes) {
    final days = totalMinutes ~/ (24 * 60);
    final remainingMinutes = totalMinutes % (24 * 60);
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    
    return {
      'days': days,
      'hours': hours,
      'minutes': minutes,
    };
  }

  static String toDisplayString(int days, int hours, int minutes) {
    final parts = <String>[];
    
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    
    if (parts.isEmpty) return '0m';
    return parts.join(' ');
  }

  static String minutesToDisplayString(int totalMinutes) {
    // Handle both old format (stored as days) and new format (stored as minutes)
    final actualMinutes = totalMinutes > 30 ? totalMinutes : (totalMinutes * 24 * 60);
    
    print('🔍 [TimeHelper] Input: $totalMinutes, Actual minutes: $actualMinutes');
    
    final days = actualMinutes ~/ (24 * 60);
    final remainingMinutes = actualMinutes % (24 * 60);
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    
    print('🔍 [TimeHelper] Breakdown: days=$days, hours=$hours, minutes=$minutes');
    
    final result = toDisplayString(days, hours, minutes);
    print('🔍 [TimeHelper] Final result: $result');
    return result;
  }
}

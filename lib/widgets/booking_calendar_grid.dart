import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_card.dart';
import '../utils/time_utils.dart';

/// Callback when a booking is rescheduled via drag & drop.
typedef OnBookingRescheduled = void Function({
  required String bookingId,
  required DateTime newStartTime,
  required DateTime newEndTime,
});

/// Callback when a booking card is tapped.
typedef OnBookingTap = void Function(CalendarBooking booking);

/// Main calendar grid widget that displays bookings in a timeline format.
/// 
/// Features:
/// - X-axis: Sequential dates (Mon, Tue, Wed...)
/// - Y-axis: 24 hours in 30-minute increments (48 rows)
/// - Draggable booking cards
/// - Scrollable in both directions
class BookingCalendarGrid extends StatefulWidget {
  /// List of bookings to display
  final List<CalendarBooking> bookings;

  /// Start date for the calendar (first column)
  /// If null, defaults to the first day of the current month
  final DateTime? startDate;

  /// Number of days to display (default: null, which means show full month)
  /// If null, displays all days in the selected month
  final int? numberOfDays;

  /// Whether to show month paginator (default: true)
  final bool showMonthPaginator;

  /// Callback when a booking is rescheduled
  final OnBookingRescheduled? onBookingRescheduled;

  /// Callback when a booking is tapped
  final OnBookingTap? onBookingTap;

  /// Height of each time slot row in pixels (default: 60)
  final double rowHeight;

  /// Width of each date column in pixels (default: 200)
  final double columnWidth;

  /// Whether to show grid lines (default: true)
  final bool showGridLines;

  /// Color of grid lines (default: Colors.grey.shade400)
  final Color? gridLineColor;

  const BookingCalendarGrid({
    super.key,
    required this.bookings,
    this.startDate,
    this.numberOfDays,
    this.onBookingRescheduled,
    this.onBookingTap,
    this.rowHeight = 60.0,
    this.columnWidth = 200.0,
    this.showGridLines = true,
    this.gridLineColor,
    this.showMonthPaginator = true,
  });

  @override
  State<BookingCalendarGrid> createState() => _BookingCalendarGridState();
}

class _BookingCalendarGridState extends State<BookingCalendarGrid> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _headerHorizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _timeLabelsScrollController = ScrollController();

  // Track dragging state
  String? _draggingBookingId;
  int? _dragColumnIndex;
  int? _dragRowIndex;
  
  // Prevent infinite sync loops
  bool _isSyncing = false;
  
  // Track pan gesture for grid dragging
  Offset? _panStartOffset;
  double? _panStartHorizontalOffset;
  double? _panStartVerticalOffset;

  // Auto-scroll during drag
  Timer? _autoScrollTimer;
  Offset? _currentDragPosition;
  final GlobalKey _gridKey = GlobalKey();

  // Track current month being displayed
  late DateTime _currentMonth;
  
  // Internal bookings list for optimistic updates
  late List<CalendarBooking> _bookings;

  @override
  void initState() {
    super.initState();
    // Initialize to first day of current month or provided startDate
    final initialDate = widget.startDate ?? DateTime.now();
    _currentMonth = DateTime(initialDate.year, initialDate.month, 1);
    
    // Initialize internal bookings list
    _bookings = List.from(widget.bookings);
    
    // Sync header when grid scrolls horizontally
    _horizontalScrollController.addListener(_syncHeaderFromGrid);
    // Sync grid when header scrolls horizontally
    _headerHorizontalScrollController.addListener(_syncGridFromHeader);
  }

  @override
  void didUpdateWidget(BookingCalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update month if startDate changed
    if (oldWidget.startDate != widget.startDate && widget.startDate != null) {
      _currentMonth = DateTime(widget.startDate!.year, widget.startDate!.month, 1);
    }
    
    // Only update bookings if the list reference changed or contents are different
    // This prevents unnecessary updates during drag operations
    if (oldWidget.bookings != widget.bookings) {
      // Create maps for efficient lookup
      final oldMap = {for (var b in oldWidget.bookings) b.id: b};
      final newMap = {for (var b in widget.bookings) b.id: b};
      
      // Check if there are actual meaningful differences
      bool hasChanges = false;
      
      // Check if any bookings were added or removed
      if (oldMap.length != newMap.length) {
        hasChanges = true;
      } else {
        // Check if any existing bookings changed
        for (final oldB in oldWidget.bookings) {
          final newB = newMap[oldB.id];
          if (newB == null) {
            // Booking was removed
            hasChanges = true;
            break;
          }
          // Check if booking times or details changed
          if (newB.start != oldB.start || 
              newB.end != oldB.end ||
              newB.title != oldB.title ||
              newB.customerName != oldB.customerName ||
              newB.color != oldB.color) {
            hasChanges = true;
            break;
          }
        }
        
        // Check if any new bookings were added
        if (!hasChanges) {
          for (final newB in widget.bookings) {
            if (!oldMap.containsKey(newB.id)) {
              hasChanges = true;
              break;
            }
          }
        }
      }
      
      // Only update internal list if there are actual changes
      if (hasChanges) {
        _bookings = List.from(widget.bookings);
      }
    }
  }

  /// Get the number of days to display
  int get _numberOfDays {
    if (widget.numberOfDays != null) {
      return widget.numberOfDays!;
    }
    // Calculate days in current month
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    return lastDayOfMonth.day;
  }

  /// Get the start date for the calendar
  DateTime get _startDate {
    if (widget.startDate != null && widget.numberOfDays != null) {
      return widget.startDate!;
    }
    // Return first day of current month
    return DateTime(_currentMonth.year, _currentMonth.month, 1);
  }

  /// Navigate to previous month
  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    // Reset scroll position
    _horizontalScrollController.jumpTo(0);
  }

  /// Navigate to next month
  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    // Reset scroll position
    _horizontalScrollController.jumpTo(0);
  }

  /// Navigate to current month
  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
    });
    // Reset scroll position
    _horizontalScrollController.jumpTo(0);
  }

  /// Get month/year display text
  String get _monthYearText {
    return DateFormat('MMMM yyyy').format(_currentMonth);
  }

  /// Check if current month is displayed
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_syncHeaderFromGrid);
    _headerHorizontalScrollController.removeListener(_syncGridFromHeader);
    _autoScrollTimer?.cancel();
    _horizontalScrollController.dispose();
    _headerHorizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _timeLabelsScrollController.dispose();
    super.dispose();
  }

  /// Start auto-scrolling timer during drag
  void _startAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    // Use a faster update interval for more responsive scrolling
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_draggingBookingId == null) {
        timer.cancel();
        _autoScrollTimer = null;
        return;
      }
      // Use the latest drag position if available
      if (_currentDragPosition != null) {
        _performAutoScroll(_currentDragPosition!);
      }
    });
  }

  /// Stop auto-scrolling timer
  void _stopAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _currentDragPosition = null;
  }

  /// Perform auto-scroll based on drag position proximity to edges
  void _performAutoScroll(Offset globalPosition) {
    if (!_horizontalScrollController.hasClients && !_verticalScrollController.hasClients) {
      return;
    }

    // Get the RenderBox for coordinate conversion
    final RenderBox? renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    // Convert global position to local coordinates relative to the grid
    Offset localPosition;
    try {
      localPosition = renderBox.globalToLocal(globalPosition);
    } catch (e) {
      // If conversion fails, skip this update
      return;
    }
    
    final viewportSize = renderBox.size;
    
    // Define edge zones (100 pixels from edges for easier activation)
    const edgeZone = 100.0;
    final scrollSpeed = 25.0; // pixels per update (faster scrolling)

    // Check if position is within the viewport bounds (with some tolerance)
    final isInViewport = localPosition.dx >= -50 && localPosition.dx <= viewportSize.width + 50 &&
                        localPosition.dy >= -50 && localPosition.dy <= viewportSize.height + 50;
    
    if (!isInViewport) {
      // Position is too far outside viewport, don't scroll
      return;
    }

    // Check horizontal scrolling
    if (_horizontalScrollController.hasClients && 
        _horizontalScrollController.position.maxScrollExtent > 0) {
      final canScrollLeft = _horizontalScrollController.offset > 0;
      final canScrollRight = _horizontalScrollController.offset < _horizontalScrollController.position.maxScrollExtent;
      
      if (localPosition.dx < edgeZone && canScrollLeft) {
        // Near left edge - scroll left
        final newOffset = (_horizontalScrollController.offset - scrollSpeed)
            .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
        _horizontalScrollController.jumpTo(newOffset);
      } else if (localPosition.dx > viewportSize.width - edgeZone && canScrollRight) {
        // Near right edge - scroll right
        final newOffset = (_horizontalScrollController.offset + scrollSpeed)
            .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
        _horizontalScrollController.jumpTo(newOffset);
      }
    }

    // Check vertical scrolling
    if (_verticalScrollController.hasClients && 
        _verticalScrollController.position.maxScrollExtent > 0) {
      final canScrollUp = _verticalScrollController.offset > 0;
      final canScrollDown = _verticalScrollController.offset < _verticalScrollController.position.maxScrollExtent;
      
      if (localPosition.dy < edgeZone && canScrollUp) {
        // Near top edge - scroll up
        final newOffset = (_verticalScrollController.offset - scrollSpeed)
            .clamp(0.0, _verticalScrollController.position.maxScrollExtent);
        _verticalScrollController.jumpTo(newOffset);
      } else if (localPosition.dy > viewportSize.height - edgeZone && canScrollDown) {
        // Near bottom edge - scroll down
        final newOffset = (_verticalScrollController.offset + scrollSpeed)
            .clamp(0.0, _verticalScrollController.position.maxScrollExtent);
        _verticalScrollController.jumpTo(newOffset);
      }
    }
  }

  /// Sync header scroll from grid scroll
  void _syncHeaderFromGrid() {
    if (_isSyncing) return;
    if (!_headerHorizontalScrollController.hasClients || !_horizontalScrollController.hasClients) return;
    
    final gridOffset = _horizontalScrollController.offset;
    final headerOffset = _headerHorizontalScrollController.offset;
    
    if ((headerOffset - gridOffset).abs() > 1.0) {
      _isSyncing = true;
      _headerHorizontalScrollController.jumpTo(gridOffset);
      _isSyncing = false;
    }
  }

  /// Sync grid scroll from header scroll
  void _syncGridFromHeader() {
    if (_isSyncing) return;
    if (!_horizontalScrollController.hasClients || !_headerHorizontalScrollController.hasClients) return;
    
    final headerOffset = _headerHorizontalScrollController.offset;
    final gridOffset = _horizontalScrollController.offset;
    
    if ((gridOffset - headerOffset).abs() > 1.0) {
      _isSyncing = true;
      _horizontalScrollController.jumpTo(headerOffset);
      _isSyncing = false;
    }
  }

  /// Sync time labels scroll when grid scrolls
  void _syncTimeLabelsScroll() {
    if (_isSyncing) return;
    if (!_timeLabelsScrollController.hasClients || !_verticalScrollController.hasClients) return;
    
    final gridOffset = _verticalScrollController.offset;
    final labelsOffset = _timeLabelsScrollController.offset;
    
    if ((labelsOffset - gridOffset).abs() > 1.0) {
      _isSyncing = true;
      _timeLabelsScrollController.jumpTo(gridOffset);
      _isSyncing = false;
    }
  }

  /// Sync grid scroll when time labels scroll
  void _syncGridScroll() {
    if (_isSyncing) return;
    if (!_verticalScrollController.hasClients || !_timeLabelsScrollController.hasClients) return;
    
    final labelsOffset = _timeLabelsScrollController.offset;
    final gridOffset = _verticalScrollController.offset;
    
    if ((gridOffset - labelsOffset).abs() > 1.0) {
      _isSyncing = true;
      _verticalScrollController.jumpTo(labelsOffset);
      _isSyncing = false;
    }
  }

  /// Gets the date range for the calendar
  List<DateTime> get _dateRange {
    return TimeUtils.generateDateRange(_startDate, _numberOfDays);
  }

  /// Gets bookings for a specific date
  List<CalendarBooking> _getBookingsForDate(DateTime date) {
    return _bookings.where((booking) {
      final bookingDate = TimeUtils.startOfDay(booking.start);
      final targetDate = TimeUtils.startOfDay(date);
      return bookingDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  /// Calculates the position of a booking card
  _BookingPosition _calculateBookingPosition(CalendarBooking booking, DateTime date) {
    final columnIndex = TimeUtils.dateToColumnIndex(date, _startDate);
    final rowIndex = TimeUtils.timeToRowIndex(booking.start);
    final slotSpan = TimeUtils.calculateSlotSpan(booking.start, booking.end);
    final height = slotSpan * widget.rowHeight;

    return _BookingPosition(
      columnIndex: columnIndex,
      rowIndex: rowIndex,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = widget.columnWidth * _numberOfDays;
        final totalHeight = TimeUtils.slotsPerDay * widget.rowHeight;

        return Column(
          children: [
            // Month paginator
            if (widget.showMonthPaginator && widget.numberOfDays == null) _buildMonthPaginator(),
            // Header row with date labels
            _buildHeaderRow(),
            // Main scrollable grid
            Expanded(
              child: Row(
                children: [
                  // Time labels column (fixed)
                  _buildTimeLabelsColumn(),
                  // Scrollable grid area with vertical scrollbar
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalScrollController,
                      thumbVisibility: true,
                      child: _buildScrollableGrid(
                        totalWidth: totalWidth,
                        totalHeight: totalHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Horizontal scrollbar at the bottom
            // Using a separate controller that syncs with the main one to avoid conflicts
            Container(
              height: 16.0,
              margin: const EdgeInsets.only(left: 80.0), // Match time labels column width
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate scrollbar thumb position based on grid scroll
                  final maxScroll = totalWidth - constraints.maxWidth;
                  final currentScroll = _horizontalScrollController.hasClients
                      ? _horizontalScrollController.offset
                      : 0.0;
                  final thumbWidth = maxScroll > 0
                      ? (constraints.maxWidth * constraints.maxWidth / totalWidth).clamp(20.0, constraints.maxWidth)
                      : constraints.maxWidth;
                  final thumbPosition = maxScroll > 0
                      ? (currentScroll / maxScroll * (constraints.maxWidth - thumbWidth)).clamp(0.0, constraints.maxWidth - thumbWidth)
                      : 0.0;

                  return Stack(
                    children: [
                      // Scrollbar track
                      Container(
                        width: constraints.maxWidth,
                        height: 16.0,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      // Scrollbar thumb
                      if (maxScroll > 0)
                        Positioned(
                          left: thumbPosition,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              if (_horizontalScrollController.hasClients) {
                                final delta = details.delta.dx;
                                final scrollDelta = (delta / constraints.maxWidth) * maxScroll;
                                final newOffset = (_horizontalScrollController.offset + scrollDelta)
                                    .clamp(0.0, maxScroll);
                                _horizontalScrollController.jumpTo(newOffset);
                              }
                            },
                            child: Container(
                              width: thumbWidth,
                              height: 12.0,
                              margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade600,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the month paginator
  Widget _buildMonthPaginator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous month button
          IconButton(
            onPressed: _goToPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Today button
          Flexible(
            child: TextButton(
              onPressed: _goToCurrentMonth,
              style: TextButton.styleFrom(
                backgroundColor: _isCurrentMonth ? Colors.grey.shade200 : Colors.transparent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              child: const Text(
                'Today',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Month/Year display - flexible to prevent overflow
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _monthYearText,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Next month button
          IconButton(
            onPressed: _goToNextMonth,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header row with date labels
  Widget _buildHeaderRow() {
    return Container(
      height: 50.0,
      color: Colors.grey.shade100,
      child: Row(
        children: [
          // Empty space for time labels column
          SizedBox(width: 80.0),
          // Date headers - scrollable horizontally (synchronized with grid)
          Expanded(
            child: SingleChildScrollView(
              controller: _headerHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(), // Match grid physics
              child: Row(
                children: List.generate(_numberOfDays, (index) {
                  final date = _dateRange[index];
                  final isToday = TimeUtils.startOfDay(date).isAtSameMomentAs(
                    TimeUtils.startOfDay(DateTime.now()),
                  );

                  return Container(
                    width: widget.columnWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: widget.gridLineColor ?? Colors.grey.shade300,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TimeUtils.formatDateHeader(date),
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.blue : Colors.black87,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 2.0),
                              width: 6.0,
                              height: 6.0,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the time labels column (synchronized with grid scrolling)
  Widget _buildTimeLabelsColumn() {
    return Container(
      width: 80.0,
      color: Colors.grey.shade50,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification && !_isSyncing) {
            _syncGridScroll();
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _timeLabelsScrollController,
          child: Column(
            children: List.generate(TimeUtils.slotsPerDay, (index) {
              final time = TimeUtils.rowIndexToTime(index, DateTime(2022, 1, 1));
              final showLabel = index % 2 == 0; // Show every hour

              return Container(
                height: widget.rowHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.gridLineColor ?? Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                ),
                child: showLabel
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                        child: Text(
                          TimeUtils.formatTime(time),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.0,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Builds the scrollable grid with booking cards
  Widget _buildScrollableGrid({
    required double totalWidth,
    required double totalHeight,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification && !_isSyncing) {
          _syncTimeLabelsScroll();
        }
        return false;
      },
      child: DragTarget<BookingDragData>(
        key: _gridKey,
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
          // Handle drop - this is handled by individual cells
        },
        onMove: (details) {
          // Track drag position for auto-scroll
          // Convert local offset to global position for consistent coordinate system
          if (_draggingBookingId != null) {
            final RenderBox? renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              // Convert local offset to global position
              _currentDragPosition = renderBox.localToGlobal(details.offset);
              if (_autoScrollTimer == null) {
                _startAutoScrollTimer();
              }
            }
          }
        },
        onLeave: (data) {
          _stopAutoScrollTimer();
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
        onPanStart: (details) {
          // Only start pan if not dragging a booking card
          if (_draggingBookingId == null) {
            _panStartOffset = details.localPosition;
            _panStartHorizontalOffset = _horizontalScrollController.hasClients
                ? _horizontalScrollController.offset
                : 0.0;
            _panStartVerticalOffset = _verticalScrollController.hasClients
                ? _verticalScrollController.offset
                : 0.0;
          }
        },
        onPanUpdate: (details) {
          // Only pan if not dragging a booking card
          if (_draggingBookingId == null && _panStartOffset != null) {
            final delta = details.localPosition - _panStartOffset!;
            
            // Update horizontal scroll (header will sync via listener)
            if (_horizontalScrollController.hasClients) {
              final newHorizontalOffset = (_panStartHorizontalOffset ?? 0.0) - delta.dx;
              _horizontalScrollController.jumpTo(
                newHorizontalOffset.clamp(
                  0.0,
                  _horizontalScrollController.position.maxScrollExtent,
                ),
              );
            }
            // Also update header scroll controller
            if (_headerHorizontalScrollController.hasClients) {
              final newHorizontalOffset = (_panStartHorizontalOffset ?? 0.0) - delta.dx;
              _headerHorizontalScrollController.jumpTo(
                newHorizontalOffset.clamp(
                  0.0,
                  _headerHorizontalScrollController.position.maxScrollExtent,
                ),
              );
            }
            
            // Update vertical scroll
            if (_verticalScrollController.hasClients) {
              final newVerticalOffset = (_panStartVerticalOffset ?? 0.0) - delta.dy;
              _verticalScrollController.jumpTo(
                newVerticalOffset.clamp(
                  0.0,
                  _verticalScrollController.position.maxScrollExtent,
                ),
              );
            }
          }
        },
        onPanEnd: (details) {
          _panStartOffset = null;
          _panStartHorizontalOffset = null;
          _panStartVerticalOffset = null;
        },
        onPanCancel: () {
          _panStartOffset = null;
          _panStartHorizontalOffset = null;
          _panStartVerticalOffset = null;
        },
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(), // Match header physics
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: Stack(
                children: [
                  // Grid background
                  if (widget.showGridLines) _buildGridLines(),
                  // Drag target cells (invisible overlay for drop zones)
                  ..._buildDragTargetCells(),
                  // Booking cards
                  ..._buildBookingCards(),
                ],
              ),
            ),
          ),
        ),
          );
        },
      ),
    );
  }

  /// Builds the grid lines
  Widget _buildGridLines() {
    final gridColor = widget.gridLineColor ?? Colors.grey.shade400;

    return Positioned.fill(
      child: CustomPaint(
        painter: _GridPainter(
          columnCount: _numberOfDays,
          rowCount: TimeUtils.slotsPerDay,
          columnWidth: widget.columnWidth,
          rowHeight: widget.rowHeight,
          gridColor: gridColor,
        ),
      ),
    );
  }

  /// Builds all booking cards positioned in the grid
  List<Widget> _buildBookingCards() {
    final cards = <Widget>[];

    for (final date in _dateRange) {
      final bookings = _getBookingsForDate(date);

      for (final booking in bookings) {
        final position = _calculateBookingPosition(booking, date);
        final isDragging = _draggingBookingId == booking.id;

        // Skip rendering if this is the dragging booking (it's shown as feedback)
        if (isDragging && _dragColumnIndex != null && _dragRowIndex != null) {
          // Show at drag position - align with grid lines
          cards.add(
            Positioned(
              left: _dragColumnIndex! * widget.columnWidth + 1.0,
              top: _dragRowIndex! * widget.rowHeight + 1.0,
              width: widget.columnWidth - 2.0,
              height: position.height - 2.0,
              child: BookingCard(
                booking: booking,
                isDragging: true,
                width: widget.columnWidth - 2.0,
                height: position.height - 2.0,
                onTap: () => widget.onBookingTap?.call(booking),
              ),
            ),
          );
        } else if (!isDragging) {
          // Show at original position - align with grid lines
          cards.add(
            Positioned(
              left: position.columnIndex * widget.columnWidth + 1.0,
              top: position.rowIndex * widget.rowHeight + 1.0,
              width: widget.columnWidth - 2.0,
              height: position.height - 2.0,
              child: _buildDraggableBookingCard(booking, position),
            ),
          );
        }
      }
    }

    return cards;
  }

  /// Builds a draggable booking card
  Widget _buildDraggableBookingCard(
    CalendarBooking booking,
    _BookingPosition position,
  ) {
    return LongPressDraggable<BookingDragData>(
      data: BookingDragData(
        booking: booking,
        originalColumnIndex: position.columnIndex,
        originalRowIndex: position.rowIndex,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: BookingCard(
          booking: booking,
          isDragging: true,
          width: widget.columnWidth - 4.0,
          height: position.height - 2.0,
        ),
      ),
      onDragStarted: () {
        setState(() {
          _draggingBookingId = booking.id;
        });
        // Start auto-scroll timer
        _startAutoScrollTimer();
      },
      onDragUpdate: (details) {
        // Update drag position for auto-scroll (global coordinates)
        _currentDragPosition = details.globalPosition;
        // Ensure timer is running
        if (_autoScrollTimer == null) {
          _startAutoScrollTimer();
        }
      },
      onDragEnd: (details) {
        setState(() {
          _draggingBookingId = null;
          _dragColumnIndex = null;
          _dragRowIndex = null;
        });
        // Stop auto-scroll timer
        _stopAutoScrollTimer();
      },
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: BookingCard(
          booking: booking,
          width: widget.columnWidth - 4.0,
          height: position.height - 2.0,
          onTap: () => widget.onBookingTap?.call(booking),
        ),
      ),
      child: BookingCard(
        booking: booking,
        width: widget.columnWidth - 2.0,
        height: position.height - 2.0,
        onTap: () => widget.onBookingTap?.call(booking),
      ),
    );
  }

  /// Builds invisible drag target cells for each grid cell
  List<Widget> _buildDragTargetCells() {
    final cells = <Widget>[];

    for (int col = 0; col < _numberOfDays; col++) {
      for (int row = 0; row < TimeUtils.slotsPerDay; row++) {
        cells.add(
          Positioned(
            left: col * widget.columnWidth,
            top: row * widget.rowHeight,
            width: widget.columnWidth,
            height: widget.rowHeight,
            child: DragTarget<BookingDragData>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                _handleDropOnCell(details.data, col, row);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;
                return Container(
                  color: isHovered
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.transparent,
                );
              },
            ),
          ),
        );
      }
    }

    return cells;
  }

  /// Handles drop on a grid cell
  void _handleDropOnCell(
    BookingDragData dragData,
    int columnIndex,
    int rowIndex,
  ) {
    final newDate = TimeUtils.columnIndexToDate(columnIndex, _startDate);
    final newStartTime = TimeUtils.rowIndexToTime(rowIndex, newDate);
    final duration = dragData.booking.end.difference(dragData.booking.start);
    final newEndTime = newStartTime.add(duration);

    // Snap to nearest slots
    final snappedStart = TimeUtils.snapToSlot(newStartTime);
    final snappedEnd = TimeUtils.snapToSlotUp(newEndTime);

    // Optimistically update the internal bookings list immediately
    // This provides instant UI feedback without waiting for parent rebuild
    final bookingIndex = _bookings.indexWhere((b) => b.id == dragData.booking.id);
    if (bookingIndex != -1) {
      final updatedBooking = CalendarBooking(
        id: dragData.booking.id,
        start: snappedStart,
        end: snappedEnd,
        title: dragData.booking.title,
        customerName: dragData.booking.customerName,
        color: dragData.booking.color,
      );
      
      setState(() {
        _bookings[bookingIndex] = updatedBooking;
        _draggingBookingId = null;
        _dragColumnIndex = null;
        _dragRowIndex = null;
      });
    } else {
      // If booking not found, just clear drag state
      setState(() {
        _draggingBookingId = null;
        _dragColumnIndex = null;
        _dragRowIndex = null;
      });
    }

    // Notify parent callback (for backend update) - this won't cause a rebuild
    // The parent can update the backend, and when it reloads, didUpdateWidget
    // will sync any changes if needed
    widget.onBookingRescheduled?.call(
      bookingId: dragData.booking.id,
      newStartTime: snappedStart,
      newEndTime: snappedEnd,
    );
  }
}

/// Internal class to track booking position in the grid
class _BookingPosition {
  final int columnIndex;
  final int rowIndex;
  final double height;

  _BookingPosition({
    required this.columnIndex,
    required this.rowIndex,
    required this.height,
  });
}

/// Custom painter for grid lines
class _GridPainter extends CustomPainter {
  final int columnCount;
  final int rowCount;
  final double columnWidth;
  final double rowHeight;
  final Color gridColor;

  _GridPainter({
    required this.columnCount,
    required this.rowCount,
    required this.columnWidth,
    required this.rowHeight,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use a slightly thicker line for better visibility
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical lines (columns) - including borders
    for (int i = 0; i <= columnCount; i++) {
      final x = i * columnWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines (rows) - including borders
    for (int i = 0; i <= rowCount; i++) {
      final y = i * rowHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.columnCount != columnCount ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.columnWidth != columnWidth ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.gridColor != gridColor;
  }
}


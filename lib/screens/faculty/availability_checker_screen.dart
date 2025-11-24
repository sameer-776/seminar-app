import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:intl/intl.dart';

class AvailabilityCheckerScreen extends StatefulWidget {
  final SeminarHall hall;
  const AvailabilityCheckerScreen({super.key, required this.hall});

  @override
  State<AvailabilityCheckerScreen> createState() =>
      _AvailabilityCheckerScreenState();
}

class _AvailabilityCheckerScreenState extends State<AvailabilityCheckerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  final int _openingHour = 8; // 8:00 AM
  final int _closingHour = 18; // 6:00 PM (18:00)
  String? _validationError;

  // --- (Helper functions: _getEventsForDay, _parseTime - Unchanged) ---
  List<Booking> _getEventsForDay(DateTime day, List<Booking> allBookings) {
    return allBookings
        .where((booking) =>
            booking.hall == widget.hall.name &&
            isSameDay(DateTime.parse(booking.date), day) &&
            (booking.status == 'Approved' || booking.status == 'Pending'))
        .toList();
  }

  Duration _parseTime(String time) {
    try {
      final parts = time.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return Duration(hours: hours, minutes: minutes);
    } catch (e) {
      return Duration.zero;
    }
  }

  // --- (Helper functions: _generate...TimeSlots - Unchanged) ---
  List<TimeOfDay> _generateStartTimeSlots() {
    List<TimeOfDay> slots = [];
    for (int hour = _openingHour; hour < _closingHour; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
    }
    return slots;
  }

  List<TimeOfDay> _generateEndTimeSlots(TimeOfDay startTime) {
    List<TimeOfDay> slots = [];
    for (int hour = startTime.hour + 1; hour <= _closingHour; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
    }
    return slots;
  }

  // --- (Helper function: _isSlotRangeValid - Unchanged) ---
  bool _isSlotRangeValid() {
    if (_selectedDay == null || _selectedStartTime == null || _selectedEndTime == null) {
      setState(() => _validationError = 'Please select a start and end time.');
      return false;
    }
    
    final allBookings = context.read<AppState>().bookings;
    final todaysBookings = _getEventsForDay(_selectedDay!, allBookings);

    final proposedStart = _selectedDay!
        .add(Duration(hours: _selectedStartTime!.hour, minutes: _selectedStartTime!.minute));
    final proposedEnd = _selectedDay!
        .add(Duration(hours: _selectedEndTime!.hour, minutes: _selectedEndTime!.minute));

    for (final booking in todaysBookings) {
      final existingStart =
          DateTime.parse(booking.date).add(_parseTime(booking.startTime));
      final existingEnd =
          DateTime.parse(booking.date).add(_parseTime(booking.endTime));

      if (proposedStart.isBefore(existingEnd) &&
          proposedEnd.isAfter(existingStart)) {
        setState(() => _validationError = 'This time range conflicts with an existing booking.');
        return false;
      }
    }
    
    setState(() => _validationError = null);
    return true;
  }

  // --- (Time Formatters - Unchanged) ---
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String _formatStartTimeLabel(TimeOfDay time) {
    final startHour = time.hour.toString().padLeft(2, '0');
    final endHour = (time.hour + 1).toString().padLeft(2, '0');
    return '$startHour:00 - $endHour:00';
  }

  // --- (onConfirmAndRequest - Unchanged) ---
  void _onConfirmAndRequest() {
    if (_isSlotRangeValid()) {
      final hallId = widget.hall.id;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      final startTimeStr = '${_selectedStartTime!.hour}:${_selectedStartTime!.minute}';
      final endTimeStr = '${_selectedEndTime!.hour}:${_selectedEndTime!.minute}';

      final path = '/booking/form'
          '?hallId=$hallId'
          '&date=$dateStr'
          '&startTime=$startTimeStr'
          '&endTime=$endTimeStr';
          
      context.push(path);
    }
  }

  // --- ✅ 1. 'withOpacity' FIXED HERE ---
  /// Returns the correct background color for a day based on bookings
  Color _getDayColor(DateTime day, List<Booking> allBookings) {
    final events = _getEventsForDay(day, allBookings);
    
    // (0.8 * 255).round() = 204
    if (events.length > 2) {
      return Colors.red.shade400.withAlpha(204); // Heavily Booked
    }
    if (events.isNotEmpty) {
      return Colors.orange.shade400.withAlpha(204); // Partially Booked
    }
    return Colors.green.shade400.withAlpha(204); // Available
  }

  /// Builds the small legend item
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Builds the custom cell for the calendar
  Widget _buildDayCell({
    required DateTime day,
    required Color backgroundColor,
    required Color textColor,
    BoxDecoration? decoration,
  }) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: decoration ?? BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBookings = context.watch<AppState>().bookings;
    final theme = Theme.of(context);

    // Generate time slots
    final startTimeSlots = _generateStartTimeSlots();
    final endTimeSlots = _selectedStartTime != null 
                         ? _generateEndTimeSlots(_selectedStartTime!) 
                         : <TimeOfDay>[];

    return Scaffold(
      appBar: AppBar(
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, size: 14),
          label: const Text('Change Hall'),
        ),
        leadingWidth: 120,
        title: Text(widget.hall.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Check Availability for ${widget.hall.name}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: TableCalendar<Booking>(
                firstDay: DateTime.now().subtract(const Duration(days: 1)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (selectedDay.isBefore(DateUtils.dateOnly(DateTime.now()))) {
                    return;
                  }
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedStartTime = null; 
                    _selectedEndTime = null;
                    _validationError = null;
                  });
                },
                enabledDayPredicate: (day) {
                  return !day.isBefore(DateUtils.dateOnly(DateTime.now()));
                },
                eventLoader: (day) => _getEventsForDay(day, allBookings),
                
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final color = _getDayColor(day, allBookings);
                    return _buildDayCell(
                      day: day,
                      backgroundColor: color,
                      textColor: Colors.white,
                    );
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    return _buildDayCell(
                      day: day,
                      // ✅ 'withOpacity' FIXED HERE
                      backgroundColor: Colors.grey.shade800.withAlpha(128), // ~0.5
                      textColor: Colors.grey.shade400,
                    );
                  },
                  disabledBuilder: (context, day, focusedDay) {
                    return _buildDayCell(
                      day: day,
                      // ✅ 'withOpacity' FIXED HERE
                      backgroundColor: Colors.grey.shade900.withAlpha(128), // ~0.5
                      textColor: Colors.grey.shade700,
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final color = _getDayColor(day, allBookings);
                    return _buildDayCell(
                      day: day,
                      backgroundColor: color,
                      textColor: Colors.white,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 2.0,
                        ),
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final color = _getDayColor(day, allBookings);
                    return _buildDayCell(
                      day: day,
                      backgroundColor: color,
                      textColor: Colors.white,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            // ✅ 'withOpacity' FIXED HERE
                            color: theme.primaryColor.withAlpha(128), // ~0.5
                            blurRadius: 5,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // --- ✅ 2. 'withOpacity' FIXED HERE ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(Colors.green.shade400.withAlpha(204), 'Available'),
                  _buildLegendItem(Colors.orange.shade400.withAlpha(204), 'Partially Booked'),
                  _buildLegendItem(Colors.red.shade400.withAlpha(204), 'Heavily Booked'),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // --- TIME SELECTION ---
            if (_selectedDay != null) ...[
              Text('2. Select a Time Range', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<TimeOfDay>(
                initialValue: _selectedStartTime,
                hint: const Text('Select start time'),
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(),
                ),
                items: startTimeSlots.map((time) {
                  return DropdownMenuItem<TimeOfDay>(
                    value: time,
                    child: Text(_formatStartTimeLabel(time)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStartTime = value;
                    _selectedEndTime = null;
                    _validationError = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<TimeOfDay>(
                initialValue: _selectedEndTime,
                hint: const Text('Select end time'),
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  border: OutlineInputBorder(),
                ),
                disabledHint: _selectedStartTime == null ? const Text('Select a start time first') : null,
                items: _selectedStartTime == null ? [] : endTimeSlots.map((time) {
                  return DropdownMenuItem<TimeOfDay>(
                    value: time,
                    child: Text(_formatTime(time)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEndTime = value;
                    _validationError = null;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _selectedDay == null || _selectedStartTime == null || _selectedEndTime == null
                  ? null
                  : _onConfirmAndRequest,
                child: const Text('Confirm & Request'),
              ),

              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _validationError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
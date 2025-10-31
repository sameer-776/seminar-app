// lib/screens/faculty/availability_checker_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:intl/intl.dart'; // ✅ ADD THIS IMPORT FOR DATE FORMATTING

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

  /// Gets a list of bookings for a specific day and hall.
  List<Booking> _getEventsForDay(DateTime day, List<Booking> allBookings) {
    return allBookings
        .where((booking) =>
            booking.hall == widget.hall.name &&
            isSameDay(DateTime.parse(booking.date), day) &&
            (booking.status == 'Approved' || booking.status == 'Pending'))
        .toList();
  }

  /// Helper function to parse "HH:mm" strings into a Duration.
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

  /// Generates a list of hourly TimeOfDay objects for the Start Time dropdown.
  List<TimeOfDay> _generateStartTimeSlots() {
    List<TimeOfDay> slots = [];
    for (int hour = _openingHour; hour < _closingHour; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
    }
    return slots;
  }

  /// Generates a list of hourly TimeOfDay objects for the End Time dropdown.
  List<TimeOfDay> _generateEndTimeSlots(TimeOfDay startTime) {
    List<TimeOfDay> slots = [];
    for (int hour = startTime.hour + 1; hour <= _closingHour; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
    }
    return slots;
  }

  /// Checks if the selected time range is valid and has no conflicts.
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

    // Check for conflicts
    for (final booking in todaysBookings) {
      final existingStart =
          DateTime.parse(booking.date).add(_parseTime(booking.startTime));
      final existingEnd =
          DateTime.parse(booking.date).add(_parseTime(booking.endTime));

      if (proposedStart.isBefore(existingEnd) &&
          proposedEnd.isAfter(existingStart)) {
        setState(() => _validationError = 'This time range conflicts with an existing booking.');
        return false; // Conflict found
      }
    }
    
    setState(() => _validationError = null);
    return true; // No conflicts
  }

  /// Formats the time for the dropdown labels, e.g., "11:00"
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Formats the end time label as shown in your screenshot, e.g., "10:00 - 11:00"
  String _formatEndTimeLabel(TimeOfDay time) {
    final endHour = time.hour.toString().padLeft(2, '0');
    final startHour = (time.hour - 1).toString().padLeft(2, '0');
    return '$startHour:00 - $endHour:00';
  }

  // ✅ ==========================================================
  // ✅ THIS IS THE FIX. We now use query parameters instead of 'extra'.
  // ✅ ==========================================================
  void _onConfirmAndRequest() {
    if (_isSlotRangeValid()) {
      // 1. Format all data into strings
      final hallId = widget.hall.id;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      
      // Format time as HH:mm
      final startTimeStr = '${_selectedStartTime!.hour}:${_selectedStartTime!.minute}';
      final endTimeStr = '${_selectedEndTime!.hour}:${_selectedEndTime!.minute}';

      // 2. Build the URL with query parameters
      final path = '/booking/form'
          '?hallId=$hallId'
          '&date=$dateStr'
          '&startTime=$startTimeStr'
          '&endTime=$endTimeStr';
          
      // 3. Push the new path. This is stable and survives hot restarts.
      context.push(path);
    }
  }
  // ✅ ==========================================================
  // ✅ END OF FIX
  // ✅ ==========================================================


  @override
  Widget build(BuildContext context) {
    final allBookings = context.watch<AppState>().bookings;

    // Generate time slots for the dropdowns
    final startTimeSlots = _generateStartTimeSlots();
    final endTimeSlots = _selectedStartTime != null 
                         ? _generateEndTimeSlots(_selectedStartTime!) 
                         : <TimeOfDay>[];

    return Scaffold(
      appBar: AppBar(title: Text('Select Date for ${widget.hall.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CALENDAR VIEW ---
            Text('1. Select a Date', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
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
              ),
            ),
            const SizedBox(height: 24),

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
                    child: Text(_formatTime(time)),
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
                    child: Text(_formatEndTimeLabel(time)),
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
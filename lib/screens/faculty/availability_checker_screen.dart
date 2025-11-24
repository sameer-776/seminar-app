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
  
  Booking? _conflictingBooking; // To store the blocking booking

  final int _openingHour = 8; 
  final int _closingHour = 18; 
  String? _validationError;

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

  // ✅ NEW: Real-time conflict check
  void _checkConflicts() {
    if (_selectedDay == null || _selectedStartTime == null || _selectedEndTime == null) {
      setState(() {
        _conflictingBooking = null;
        _validationError = null;
      });
      return;
    }

    final appState = context.read<AppState>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final startTimeStr = _formatTime(_selectedStartTime!);
    final endTimeStr = _formatTime(_selectedEndTime!);

    // Get the actual booking object if there is a conflict
    final conflict = appState.getConflictingBooking(
        widget.hall.name, dateStr, startTimeStr, endTimeStr);

    setState(() {
      _conflictingBooking = conflict;
      if (conflict != null) {
        _validationError = null; // Conflict takes precedence
      }
    });
  }

  void _onConfirmAndRequest() {
    // Double check
    if (_conflictingBooking != null) return;

    if (_selectedDay != null && _selectedStartTime != null && _selectedEndTime != null) {
      final hallId = widget.hall.id;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      final startTimeStr = _formatTime(_selectedStartTime!);
      final endTimeStr = _formatTime(_selectedEndTime!);

      final path = '/booking/form'
          '?hallId=$hallId'
          '&date=$dateStr'
          '&startTime=$startTimeStr'
          '&endTime=$endTimeStr';
          
      context.push(path);
    }
  }

  Color _getDayColor(DateTime day, List<Booking> allBookings) {
    final events = _getEventsForDay(day, allBookings);
    if (events.length > 2) {
      return Colors.red.shade400.withAlpha(204); 
    }
    if (events.isNotEmpty) {
      return Colors.orange.shade400.withAlpha(204); 
    }
    return Colors.green.shade400.withAlpha(204); 
  }

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
            // ✅ HALL BLOCKED WARNING
            if (!widget.hall.isAvailable)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "This hall is currently blocked by the Admin for maintenance or other reasons.",
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

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
                    _conflictingBooking = null; // Reset conflict
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
                      backgroundColor: Colors.grey.shade800.withAlpha(128),
                      textColor: Colors.grey.shade400,
                    );
                  },
                  disabledBuilder: (context, day, focusedDay) {
                    return _buildDayCell(
                      day: day,
                      backgroundColor: Colors.grey.shade900.withAlpha(128),
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
                            color: theme.primaryColor.withAlpha(128),
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
                    _conflictingBooking = null;
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
                  });
                  // ✅ Trigger check immediately on selection
                  _checkConflicts();
                },
              ),
              const SizedBox(height: 24),
              
              // ✅ CONFLICT WARNING BOX
              if (_conflictingBooking != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Time Conflict!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // Show who booked it and when
                        "This slot is already booked:\nFrom: ${_conflictingBooking!.startTime} To: ${_conflictingBooking!.endTime}",
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      if (_conflictingBooking!.requestedBy.isNotEmpty)
                         Text(
                          "By: ${_conflictingBooking!.requestedBy}",
                          style: const TextStyle(color: Colors.black87, fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  // Disable if hall is blocked OR double booked
                  backgroundColor: (widget.hall.isAvailable && _conflictingBooking == null && _selectedEndTime != null) 
                      ? null 
                      : Colors.grey,
                ),
                onPressed: (widget.hall.isAvailable && _conflictingBooking == null && _selectedEndTime != null)
                  ? _onConfirmAndRequest
                  : null,
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
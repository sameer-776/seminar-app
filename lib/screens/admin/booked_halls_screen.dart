import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart'; // <-- 1. ADD THIS IMPORT

class BookedHallsScreen extends StatefulWidget {
  const BookedHallsScreen({super.key});

  @override
  State<BookedHallsScreen> createState() => _BookedHallsScreenState();
}

class _BookedHallsScreenState extends State<BookedHallsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Booking>> _events = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final approvedBookings =
        appState.bookings.where((b) => b.status == 'Approved').toList();

    _events = groupBy(approvedBookings, (Booking booking) {
      return DateTime.parse(booking.date).toUtc();
    });
  }
  List<Booking> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day).toUtc()] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Security check
    if (appState.currentUser?.role != 'admin') {
      return const Scaffold(body: Center(child: Text('Access Denied.')));
    }

    final eventsForSelectedDay = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked Halls Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'All Requests History',
            onPressed: () {
              context.go('/admin/history');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Booking>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(),
          ),
          Expanded(
            child: eventsForSelectedDay.isEmpty
                ? const Center(child: Text('No approved bookings for this day.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: eventsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final event = eventsForSelectedDay[index];
                      return Card(
                        child: ListTile(
                          title: Text(event.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${event.hall}\nTime: ${event.startTime} - ${event.endTime}'),
                          leading: const Icon(Icons.event_available),
                          // --- 2. ADD THESE LINES ---
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigate to the review screen
                            context.go('/admin/review/${event.id}');
                          },
                          // --- END OF CHANGES ---
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
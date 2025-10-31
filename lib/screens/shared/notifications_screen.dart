import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seminar_booking_app/providers/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // When this screen is opened, mark all notifications as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().markNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use 'watch' to get the list and rebuild when it changes
    final notifications = context.watch<AppState>().notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You have no notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                
                // --- CORRECTED ---
                // Use the non-nullable fields directly from your model
                final title = notification.title;
                final body = notification.body;
                final timestamp = notification.timestamp;
                final bool hasBookingId = notification.bookingId != null &&
                    notification.bookingId!.isNotEmpty;
                // --- END CORRECTED ---

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    // A faded icon for read, a bright one for unread
                    leading: Icon(
                      notification.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: notification.isRead
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                            notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(body),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMd().add_jm().format(timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    // Allow tapping to go to the booking
                    onTap: hasBookingId
                        ? () {
                            context
                                .go('/booking/details/${notification.bookingId}');
                          }
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
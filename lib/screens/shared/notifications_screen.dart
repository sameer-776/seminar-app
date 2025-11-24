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

  // --- ✅ NEW: Helper to determine color and icon based on content ---
  Map<String, dynamic> _getNotificationStyle(String title, String body) {
    final String combined = '$title $body'.toLowerCase();

    if (combined.contains('approved')) {
      return {
        'color': Colors.green.shade700,
        'bgColor': Colors.green.shade50,
        'icon': Icons.check_circle_outline,
      };
    } else if (combined.contains('rejected') || combined.contains('cancelled')) {
      return {
        'color': Colors.red.shade700,
        'bgColor': Colors.red.shade50,
        'icon': Icons.cancel_outlined,
      };
    } else if (combined.contains('re-allocated') || combined.contains('reallocated')) {
      return {
        'color': Colors.blue.shade700,
        'bgColor': Colors.blue.shade50,
        'icon': Icons.swap_horiz_outlined,
      };
    } else if (combined.contains('new request') || combined.contains('submitted')) {
      return {
        'color': Colors.orange.shade800,
        'bgColor': Colors.orange.shade50,
        'icon': Icons.assignment_outlined,
      };
    }
    // Default style
    return {
      'color': Colors.grey.shade800,
      'bgColor': Colors.white,
      'icon': Icons.notifications_outlined,
    };
  }
  // --- END NEW ---

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                
                final title = notification.title;
                final body = notification.body;
                final timestamp = notification.timestamp;
                final bool hasBookingId = notification.bookingId != null &&
                    notification.bookingId!.isNotEmpty;

                // Get style based on text
                final style = _getNotificationStyle(title, body);

                return Card(
                  elevation: 0, // Flat style for cleaner colored look
                  color: style['bgColor'], // Light background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: style['color'].withOpacity(0.2)),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: style['color'].withOpacity(0.1),
                      child: Icon(
                        style['icon'],
                        color: style['color'],
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: style['color'], // Colored title
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(body, style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat.yMMMd().add_jm().format(timestamp),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    // Show arrow if clickable
                    trailing: hasBookingId ? Icon(Icons.chevron_right, color: style['color']) : null,
                    onTap: hasBookingId
                        ? () {
                            context.push('/booking/details/${notification.bookingId}');
                          }
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
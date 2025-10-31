import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:collection/collection.dart';
import 'package:seminar_booking_app/models/notification.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';

// Converted to a StatefulWidget to handle the pop-up logic
class FacultyHomeScreen extends StatefulWidget {
  const FacultyHomeScreen({super.key});

  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  // This ensures we only try to show the dialog once, after the build.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeNotification(context);
    });
  }

  /// Checks for the most recent unread notification and shows it as a pop-up.
  void _showWelcomeNotification(BuildContext context) {
    final appState = context.read<AppState>();
    
    // Find the newest unread notification.
    final mostRecentUnread = appState.notifications
        .firstWhereOrNull((n) => !n.isRead);

    if (mostRecentUnread != null) {
      // If we found one, show the dialog
      _showWelcomeNotificationDialog(context, mostRecentUnread);
    }
  }

  /// Displays the actual pop-up dialog for a notification.
  void _showWelcomeNotificationDialog(
      BuildContext context, AppNotification notification) {
    final firestoreService = context.read<FirestoreService>();
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      barrierDismissible: false, // User must interact
      builder: (dialogContext) {
        
        final title = notification.title;
        final body = notification.body;
        final hasBookingId =
            notification.bookingId != null && notification.bookingId!.isNotEmpty;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(body),
          actions: [
            TextButton(
              child: const Text('Dismiss'),
              onPressed: () {
                // Mark this *one* notification as read and close the dialog
                firestoreService.markNotificationsAsRead([notification.id]);
                Navigator.of(dialogContext).pop();
              },
            ),
            if (hasBookingId)
              ElevatedButton(
                child: const Text('View Details'),
                onPressed: () {
                  // Mark as read, close dialog, and navigate
                  firestoreService.markNotificationsAsRead([notification.id]);
                  Navigator.of(dialogContext).pop();
                  // Use the bookingId to navigate
                  router.go('/booking/details/${notification.bookingId}');
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final myBookings = appState.bookings
        .where((b) => b.requesterId == currentUser.uid)
        .toList();
    final pendingCount = myBookings.where((b) => b.status == 'Pending').length;
    final approvedCount =
        myBookings.where((b) => b.status == 'Approved').length;
    final rejectedCount =
        myBookings.where((b) => b.status == 'Rejected').length;

    return Scaffold(
      // --- APPBAR REMOVED ---
      // This screen will now use the AppShell's AppBar,
      // which has the consistent theme toggle.
      // --- END REMOVED ---
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- ADDED: PAGE TITLE ---
            // Since the AppBar is gone, we add a title here.
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Welcome, ${currentUser.name.split(' ').first}',
                style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            // --- END ADDED ---

            // (The rest of your body content is unchanged)
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create New Booking'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.go('/booking'),
            ),
            const SizedBox(height: 24),
            Text('My Requests Summary',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(context, 'Pending', pendingCount,
                        Colors.orange.shade700),
                    _buildStatChip(context, 'Approved', approvedCount,
                        Colors.green.shade700),
                    _buildStatChip(context, 'Rejected', rejectedCount,
                        Colors.red.shade700),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildUpcomingEvents(context, myBookings),
            const SizedBox(height: 24),
            _buildRecentActivity(context, myBookings),
          ],
        ),
      ),
    );
  }
  
  // (All helper widgets _buildStatChip, _buildUpcomingEvents, etc. are unchanged)
  // ...
  // --- Helper Widgets for Dashboard Sections ---

  Widget _buildStatChip(
      BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color,
          child: Text(
            count.toString(),
            style: const TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildUpcomingEvents(
      BuildContext context, List<dynamic> allMyBookings) {
    final theme = Theme.of(context);
    final today = DateUtils.dateOnly(DateTime.now());

    final upcoming = allMyBookings
        .where((b) =>
            b.status == 'Approved' && !DateTime.parse(b.date).isBefore(today))
        .toList();

    upcoming.sort((a, b) {
      int dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.startTime.compareTo(b.startTime);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Events',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.event_busy_outlined),
              title: Text('No upcoming events'),
              subtitle: Text('Your approved bookings will appear here.'),
            ),
          )
        else
          ...upcoming.take(4).map((booking) {
            final formattedDate =
                DateFormat.yMMMMd().format(DateTime.parse(booking.date));
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_available_outlined,
                    color: Colors.green),
                title: Text(booking.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${booking.hall}\n$formattedDate at ${booking.startTime}'),
                isThreeLine: true,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, List<dynamic> allMyBookings) {
    final theme = Theme.of(context);
    
    final recent = allMyBookings.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.history_toggle_off_outlined),
              title: Text('No recent activity'),
              subtitle: Text('Your booking requests will appear here.'),
            ),
          )
        else
          ...recent.take(4).map((booking) {
            return Card(
              child: ListTile(
                leading: _getStatusIcon(booking.status, theme),
                title: Text(booking.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: ${booking.status}'),
                trailing:
                    Text(DateFormat.yMd().format(DateTime.parse(booking.date))),
              ),
            );
          }),
      ],
    );
  }

  Widget _getStatusIcon(String status, ThemeData theme) {
    switch (status) {
      case 'Approved':
        return Icon(Icons.check_circle_outline, color: Colors.green.shade600);
      case 'Rejected':
        return Icon(Icons.cancel_outlined, color: Colors.red.shade600);
      case 'Cancelled':
        return Icon(Icons.do_not_disturb_on_outlined,
            color: Colors.grey.shade600);
      case 'Pending':
      default:
        return Icon(Icons.hourglass_top_outlined,
            color: Colors.orange.shade600);
    }
  }
}
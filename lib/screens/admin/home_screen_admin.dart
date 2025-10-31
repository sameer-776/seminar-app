import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/providers/app_state.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  /// Helper widget for the top stat cards (clickable)
  Widget _buildStatCard(
      BuildContext context, {
        required String title,
        required String count,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensures InkWell ripple is rounded
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget for section titles
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Helper widget for the "All Caught Up" empty state
  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 50,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Security check
    if (appState.currentUser?.role != 'admin') {
      return const Scaffold(body: Center(child: Text('Access Denied.')));
    }

    // --- 1. Data Calculation ---
    final allBookings = appState.bookings;
    final now = DateTime.now();

    final pendingBookings =
    allBookings.where((b) => b.status == 'Pending').toList();
    pendingBookings
        .sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    final totalHalls = appState.halls.length;

    final approvedBookings = allBookings.where((b) => b.status == 'Approved');
    
    // --- ✅ MODIFIED: Calculate "Approved This Month" ---
    final totalApprovedThisMonth = approvedBookings.where((b) {
      final bookingDate = DateTime.parse(b.date);
      return bookingDate.year == now.year && bookingDate.month == now.month;
    }).length;
    // --- END MODIFIED ---

    final bookingsToday = approvedBookings.where((b) {
      final bookingDate = DateTime.parse(b.date);
      return DateUtils.isSameDay(bookingDate, now);
    }).toList();

    return Scaffold(
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Admin Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // --- 2. Stats Grid Section ---
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: (1 / 1),
            children: [
              _buildStatCard(
                context,
                title: 'Pending Requests',
                count: pendingBookings.length.toString(),
                icon: Icons.pending_actions_rounded,
                color: Colors.orange.shade700,
                onTap: () {
                  context.go('/admin/history');
                },
              ),
              _buildStatCard(
                context,
                title: 'Happening Today',
                count: bookingsToday.length.toString(),
                icon: Icons.event_available_rounded,
                color: Colors.green.shade700,
                onTap: () {
                  context.go('/admin/bookings');
                },
              ),
              _buildStatCard(
                context,
                title: 'Total Halls',
                count: totalHalls.toString(),
                icon: Icons.meeting_room_rounded,
                color: Colors.blue.shade700,
                onTap: () {
                  context.go('/admin/halls');
                },
              ),
              // --- ✅ MODIFIED: Stat Card Updated ---
              _buildStatCard(
                context,
                title: 'Approved This Month',
                count: totalApprovedThisMonth.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: Colors.purple.shade700,
                onTap: () {
                  // Still goes to history, where user can filter
                  context.go('/admin/history'); 
                },
              ),
              // --- END MODIFIED ---
            ],
          ),

          // --- 3. "Happening Today" Section ---
          _buildSectionTitle(context, "Happening Today"),
          bookingsToday.isEmpty
              ? _buildEmptyState(
            context,
            'No Bookings Today',
            'No seminars are scheduled for today.',
          )
              : Card(
            child: Column(
              children: [
                ...bookingsToday.map((booking) {
                  return ListTile(
                    leading: const Icon(Icons.event_note_rounded),
                    title: Text(booking.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${booking.hall} (${booking.startTime} - ${booking.endTime})'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.go('/admin/review/${booking.id}');
                    },
                  );
                }),
                // "View Full Schedule" Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      context.go('/admin/bookings');
                    },
                    child: const Text('View Full Schedule'),
                  ),
                ),
              ],
            ),
          ),

          // --- 4. "Pending Requests" Section ---
          _buildSectionTitle(context, 'Pending Requests'),
          pendingBookings.isEmpty
              ? _buildEmptyState(
            context,
            'All Caught Up!',
            'No new requests to review.',
          )
              : Card(
            child: Column(
              children: pendingBookings.map((booking) {
                return ListTile(
                  leading: const Icon(Icons.hourglass_top_rounded),
                  title: Text(
                    booking.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'By: ${booking.requestedBy} for ${booking.hall}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.go('/admin/review/${booking.id}');
                  },
                );

              }).toList(),
            ),
          ),

          // --- 5. Quick Action Buttons ---
          const SizedBox(height: 24),
          
          // --- ✅ ADDED: View Full Analytics Button ---
          ElevatedButton.icon(
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View Full Analytics'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              context.go('/admin/analytics');
            },
          ),
          // --- END ADDED ---

          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.history_rounded),
            label: const Text('View Full Booking History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              context.go('/admin/history');
            },
          ),
        ],
      ),
    );
  }
}
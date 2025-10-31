import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  // --- Status Chip Builder (Unchanged) ---
  Widget _getStatusChip(String status) {
    Color chipColor;
    String chipText = status;

    switch (status) {
      case 'Approved':
        chipColor = Colors.green;
        break;
      case 'Pending':
        chipColor = Colors.orange;
        break;
      case 'Rejected':
        chipColor = Colors.red;
        break;
      case 'Cancelled':
        chipColor = Colors.grey[600]!;
        break;
      default:
        chipColor = Colors.black;
        chipText = 'Unknown';
    }

    return Chip(
      label: Text(
        chipText,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // --- Cancel Confirmation Dialog (Unchanged) ---
  void _showCancelConfirmationDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking request?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No, Keep It'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
              onPressed: () async {
                await context.read<FirestoreService>().cancelBooking(booking.id);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking has been cancelled.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  // --- UPDATED BOOKING CARD WIDGET ---
  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final theme = Theme.of(context);
    // Format the date and time
    final formattedDate = DateFormat.yMMMMd().format(DateTime.parse(booking.date));
    final timeRange = '${booking.startTime} - ${booking.endTime}';
    
    // --- ✅ NEW CANCELLATION LOGIC ---
    bool canCancel;
    if (booking.status == 'Pending') {
      // 1. Can ALWAYS cancel a 'Pending' request
      canCancel = true;
    } else if (booking.status == 'Approved') {
      // 2. For 'Approved', check the 24-hour rule
      try {
        // Parse the combined date and start time
        final bookingDateTime = DateTime.parse('${booking.date} ${booking.startTime}');
        // Find the cutoff time (24 hours before the event)
        final cutoffDateTime = bookingDateTime.subtract(const Duration(hours: 24));
        // Check if "now" is after the cutoff time
        final bool isTooLate = DateTime.now().isAfter(cutoffDateTime);
        canCancel = !isTooLate; // Can cancel if it is NOT too late
      } catch (e) {
        // Failsafe in case of bad date/time format
        canCancel = false;
      }
    } else {
      // 3. Cannot cancel 'Rejected' or 'Cancelled'
      canCancel = false;
    }
    // --- END OF NEW LOGIC ---

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/booking/details/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _getStatusChip(booking.status),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 2: Hall and Time
              _buildInfoRow(
                context,
                icon: Icons.business_outlined,
                text: booking.hall,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.calendar_today_outlined,
                text: formattedDate,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.access_time_outlined,
                text: timeRange,
              ),

              // Row 3: Cancel Button (if applicable)
              if (canCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel Request'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _showCancelConfirmationDialog(context, booking),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for icon rows ---
  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().currentUser;
    final firestoreService = context.read<FirestoreService>();

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your bookings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking Requests'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: firestoreService.getUserBookings(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "You haven't made any booking requests yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final myBookings = snapshot.data!;
          // Sort by date (newest first)
          myBookings.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: myBookings.length,
            itemBuilder: (context, index) {
              final booking = myBookings[index];
              // --- USE THE NEW CARD ---
              return _buildBookingCard(context, booking);
            },
          );
        },
      ),
    );
  }
}
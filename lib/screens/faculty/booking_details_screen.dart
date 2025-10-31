import 'package:flutter/material.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat.yMMMMd().format(DateTime.parse(booking.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            _buildDetailCard(context, 'Event Details', [
              _buildDetailRow(context, 'Title', booking.title),
              _buildDetailRow(context, 'Purpose', booking.purpose),
              _buildDetailRow(
                  context, 'Attendees', booking.expectedAttendees.toString()),
              if (booking.additionalRequirements.isNotEmpty)
                _buildDetailRow(
                    context, 'Requirements', booking.additionalRequirements),
            ]),
            const SizedBox(height: 16),
            _buildDetailCard(context, 'Schedule & Hall', [
              _buildDetailRow(context, 'Hall', booking.hall),
              _buildDetailRow(context, 'Date', formattedDate),
              _buildDetailRow(
                  context, 'Time', '${booking.startTime} - ${booking.endTime}'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    IconData icon;
    Color color;
    String title = 'Status: ${booking.status}';
    String? subtitle;

    switch (booking.status) {
      case 'Approved':
        icon = Icons.check_circle;
        color = Colors.green;
        subtitle = 'Your booking is confirmed.';
        break;
      case 'Rejected':
        icon = Icons.cancel;
        color = Colors.red;
        subtitle = 'Reason: ${booking.rejectionReason ?? "Not provided."}';
        break;
      case 'Cancelled':
        icon = Icons.do_not_disturb_on;
        color = Colors.grey;
        subtitle = 'You have cancelled this booking.';
        break;
      default: // Pending
        icon = Icons.hourglass_top;
        color = Colors.orange;
        subtitle = 'Awaiting review from the administration.';
    }

    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildDetailCard(
      BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/widgets/admin/reallocate_dialog.dart';
import 'package:intl/intl.dart';

class ReviewBookingScreen extends StatelessWidget {
  final Booking booking;
  const ReviewBookingScreen({super.key, required this.booking});

  void _showRejectionDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reason for Rejection'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g., Conflicting VIP event',
            ),
            validator: (value) =>
            value!.trim().isEmpty ? 'A reason is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await context.read<AppState>().reviewBooking(
                  bookingId: booking.id,
                  newStatus: 'Rejected',
                  rejectionReason: reasonController.text.trim(),
                );

                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking has been rejected.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  await Future.delayed(const Duration(milliseconds: 800));
                  GoRouter.of(context).go('/admin/home');
                }
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _showReallocateDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final allBookings = appState.bookings;
    final allHalls = appState.halls;

    final conflictingStart =
    DateTime.parse('${booking.date} ${booking.startTime}');
    final conflictingEnd =
    DateTime.parse('${booking.date} ${booking.endTime}');

    final availableHalls = allHalls.where((hall) {
      if (hall.name == booking.hall || !hall.isAvailable) {
        return false;
      }
      final hasOverlap = allBookings.any((b) {
        if (b.hall != hall.name ||
            (b.status != 'Approved' && b.status != 'Pending')) {
          return false;
        }
        final existingStart = DateTime.parse('${b.date} ${b.startTime}');
        final existingEnd = DateTime.parse('${b.date} ${b.endTime}');
        return conflictingStart.isBefore(existingEnd) &&
            conflictingEnd.isAfter(existingStart);
      });
      return !hasOverlap;
    }).toList();

    final hallData = availableHalls.map((hall) {
      return {'name': hall.name, 'capacity': hall.capacity};
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        if (availableHalls.isEmpty) {
          return AlertDialog(
            title: const Text('No Available Halls'),
            content: const Text(
                'No other halls are available during this time slot.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        }

        return ReallocateDialog(
          halls: hallData,
          selectedHall: null,
          onReallocate: (String newHallName) async {
            try {
               // The updated reviewBooking will throw if there is a conflict in the NEW hall
               await appState.reviewBooking(
                bookingId: booking.id,
                newStatus: 'Approved',
                newHall: newHallName,
              );

              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hall has been reallocated to $newHallName.'),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 800));
                context.go('/admin/home');
              }
            } catch (e) {
               // Catch conflict error from reallocation
               if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
               if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Reallocation Failed"),
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
                      ],
                    ),
                  );
               }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat.yMMMMd().format(DateTime.parse(booking.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Review Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            _buildDetailCard(context, 'Requester Information', [
              _buildDetailRow(context, 'Name', booking.requestedBy),
              _buildDetailRow(context, 'Department', booking.department),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz_outlined),
                label: const Text('Re-allocate'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => _showReallocateDialog(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _showRejectionDialog(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    // ✅ UPDATED APPROVE BUTTON LOGIC
                    onPressed: () async {
                      try {
                        await context
                            .read<AppState>()
                            .reviewBooking(bookingId: booking.id, newStatus: 'Approved');

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking has been approved.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await Future.delayed(const Duration(milliseconds: 800));
                          context.go('/admin/home');
                        }
                      } catch (e) {
                        // ❌ Conflict or Error Caught Here
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Conflict Detected"),
                              content: Text(e.toString().replaceAll("Exception: ", "")),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
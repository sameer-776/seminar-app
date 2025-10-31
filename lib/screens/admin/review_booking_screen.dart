import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/widgets/admin/reallocate_dialog.dart';
import 'package:intl/intl.dart';

class ReviewBookingScreen extends StatefulWidget {
  final Booking booking;
  const ReviewBookingScreen({super.key, required this.booking});

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  bool _isLoading = false;

  /// Shows a dialog forcing the admin to enter a rejection reason.
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
            onPressed: _isLoading
                ? null
                : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      try {
                        await context.read<AppState>().reviewBooking(
                              bookingId: widget.booking.id, 
                              newStatus: 'Rejected',
                              rejectionReason: reasonController.text.trim(),
                            );

                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking has been rejected.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          await Future.delayed(
                              const Duration(milliseconds: 800));
                          context.go('/admin/home');
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    }
                  },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  /// Finds available halls and shows the new ReallocateDialog
  void _showReallocateDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final allBookings = appState.bookings;
    final allHalls = appState.halls;

    final conflictingStart =
        DateTime.parse('${widget.booking.date} ${widget.booking.startTime}');
    final conflictingEnd =
        DateTime.parse('${widget.booking.date} ${widget.booking.endTime}');

    final availableHalls = allHalls.where((hall) {
      // --- ✅ START OF FIX ---
      // We no longer skip the hall the booking is already in.
      // We only skip halls that are manually set to "unavailable".
      if (!hall.isAvailable) {
        return false;
      }
      
      final hasOverlap = allBookings.any((b) {
        // 1. We skip the booking we are currently moving.
        if (b.id == widget.booking.id) {
          return false;
        }

        // 2. We skip any booking that isn't for this hall
        //    OR is in a 'Cancelled' or 'Rejected' state.
        if (b.hall != hall.name ||
            (b.status != 'Approved' && b.status != 'Pending')) {
          return false;
        }
        
        // 3. We do the time check for all remaining relevant bookings.
        final existingStart = DateTime.parse('${b.date} ${b.startTime}');
        final existingEnd = DateTime.parse('${b.date} ${b.endTime}');
        
        return conflictingStart.isBefore(existingEnd) &&
            conflictingEnd.isAfter(existingStart);
      });
      // --- ✅ END OF FIX ---
      
      return !hasOverlap;
    }).toList();

    final hallData = availableHalls.map((hall) {
      return {'name': hall.name, 'capacity': hall.capacity};
    }).toList();

    // --- 2. Show the new dialog ---
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
          selectedHall: null, // Nothing is pre-selected
          onReallocate: (String newHallName) async {
            setState(() => _isLoading = true);
            try {
              await appState.reviewBooking(
                bookingId: widget.booking.id,
                newStatus: 'Approved',
                newHall: newHallName,
              );

              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hall has been reallocated to $newHallName.'),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 800));
                context.go('/admin/home');
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
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
        DateFormat.yMMMMd().format(DateTime.parse(widget.booking.date));
        
    final bool isTerminalStatus = widget.booking.status == 'Rejected' ||
        widget.booking.status == 'Cancelled';
        
    final bool isApproved = widget.booking.status == 'Approved';

    return Scaffold(
      appBar: AppBar(title: const Text('Review Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(context, 'Event Details', [
              _buildDetailRow(context, 'Title', widget.booking.title),
              _buildDetailRow(context, 'Purpose', widget.booking.purpose),
              _buildDetailRow(context, 'Attendees',
                  widget.booking.expectedAttendees.toString()),
              if (widget.booking.additionalRequirements.isNotEmpty)
                _buildDetailRow(context, 'Requirements',
                    widget.booking.additionalRequirements),
            ]),
            const SizedBox(height: 16),
            _buildDetailCard(context, 'Schedule & Hall', [
              _buildDetailRow(context, 'Hall', widget.booking.hall),
              _buildDetailRow(context, 'Date', formattedDate),
              _buildDetailRow(
                  context, 'Time', '${widget.booking.startTime} - ${widget.booking.endTime}'),
            ]),
            const SizedBox(height: 16),
            _buildDetailCard(context, 'Requester Information', [
              _buildDetailRow(context, 'Name', widget.booking.requestedBy),
              _buildDetailRow(context, 'Department', widget.booking.department),
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
                onPressed: _isLoading || isTerminalStatus
                    ? null
                    : () => _showReallocateDialog(context),
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
                    onPressed: _isLoading || isTerminalStatus
                        ? null
                        : () => _showRejectionDialog(context),
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
                    onPressed: _isLoading || isTerminalStatus || isApproved
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await context.read<AppState>().reviewBooking(
                                  bookingId: widget.booking.id,
                                  newStatus: 'Approved');

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking has been approved.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                await Future.delayed(
                                    const Duration(milliseconds: 800));
                                context.go('/admin/home');
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
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
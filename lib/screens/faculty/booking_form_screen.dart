import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
import 'package:seminar_booking_app/providers/app_state.dart';

class BookingFormScreen extends StatefulWidget {
  final SeminarHall hall;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime; 

  const BookingFormScreen({
    super.key,
    required this.hall,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _attendeesController = TextEditingController();
  final _requirementsController = TextEditingController();
  bool _isLoading = false;
  
  Booking? _conflictingBooking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialConflict();
    });
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _checkInitialConflict() {
    final appState = context.read<AppState>();
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.date);
    final formattedStart = _formatTime(widget.startTime);
    final formattedEnd = _formatTime(widget.endTime);

    final conflict = appState.getConflictingBooking(
      widget.hall.name, 
      formattedDate, 
      formattedStart, 
      formattedEnd
    );

    if (conflict != null) {
      setState(() {
        _conflictingBooking = conflict;
      });
    }
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final appState = context.read<AppState>();
      final currentUser = appState.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in.')));
        setState(() => _isLoading = false);
        return;
      }
      
      final formattedStartTime = _formatTime(widget.startTime);
      final formattedEndTime = _formatTime(widget.endTime);

      final newBooking = Booking(
        id: '', 
        title: _titleController.text.trim(),
        purpose: _purposeController.text.trim(),
        hall: widget.hall.name,
        date: DateFormat('yyyy-MM-dd').format(widget.date),
        startTime: formattedStartTime,
        endTime: formattedEndTime,
        status: 'Pending',
        requestedBy: currentUser.name,
        requesterId: currentUser.uid,
        department: currentUser.department,
        expectedAttendees: int.parse(_attendeesController.text),
        additionalRequirements: _requirementsController.text.trim(),
        rejectionReason: null,
      );

      try {
        // 1. Submit the booking
        // The Cloud Function (onBookingCreate) will automatically:
        // - Send notifications to all admins
        // - Send device push notifications to all admins
        await appState.submitBooking(newBooking);

        if (mounted) {
          context.go('/booking/confirmation');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll("Exception: ", "")),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
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
                        "This hall is already booked from ${_conflictingBooking!.startTime} to ${_conflictingBooking!.endTime}.",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Please go back and choose a different time.",
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              _buildSummaryCard(),
              const SizedBox(height: 24),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'This field is required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _purposeController, decoration: const InputDecoration(labelText: 'Purpose of Event', border: OutlineInputBorder()), maxLines: 3, validator: (v) => v!.isEmpty ? 'This field is required' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _attendeesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Expected Attendees (Max: ${widget.hall.capacity})', border: const OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'This field is required';
                  final count = int.tryParse(v);
                  if (count == null) return 'Please enter a valid number';
                  if (count <= 0) return 'Attendees must be greater than zero';
                  if (count > widget.hall.capacity) return 'Number of attendees exceeds hall capacity';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _requirementsController, decoration: const InputDecoration(labelText: 'Additional Requirements (Optional)', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: (_isLoading || _conflictingBooking != null) ? null : _submitRequest,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final formattedDate = DateFormat.yMMMMd().format(widget.date);
    final formattedStartTime = _formatTime(widget.startTime);
    final formattedEndTime = _formatTime(widget.endTime);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(icon: Icons.business_outlined, text: widget.hall.name),
            const SizedBox(height: 8),
            _buildSummaryRow(icon: Icons.calendar_today_outlined, text: formattedDate),
            const SizedBox(height: 8),
            _buildSummaryRow(icon: Icons.access_time_outlined, text: 'Time: $formattedStartTime - $formattedEndTime'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }
}
import 'package:flutter/material.dart';

class ReallocateDialog extends StatefulWidget {
  final List<Map<String, dynamic>> halls;
  final String? selectedHall;
  final Future<void> Function(String hallName) onReallocate;

  const ReallocateDialog({
    super.key,
    required this.halls,
    required this.selectedHall,
    required this.onReallocate,
  });

  @override
  State<ReallocateDialog> createState() => _ReallocateDialogState();
}

class _ReallocateDialogState extends State<ReallocateDialog> {
  String? _selectedHall;

  @override
  void initState() {
    super.initState();
    _selectedHall = widget.selectedHall;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1E1E2C),
      title: const Text(
        'Re-allocate Booking',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.halls.map((hall) {
          return RadioListTile<String>(
            value: hall['name'],
            groupValue: _selectedHall,
            onChanged: (value) {
              setState(() => _selectedHall = value);
            },
            title: Text(
              hall['name'],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Capacity: ${hall['capacity']}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            activeColor: const Color(0xFF6C63FF),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          ),
          onPressed: () async {
            if (_selectedHall != null) {
              // --- Store context-dependent objects BEFORE the await ---
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              try {
                await widget.onReallocate(_selectedHall!);

                // --- Check if the widget is still mounted AFTER the await ---
                if (!mounted) return;

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Hall has been reallocated successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );

                // Use the stored navigator to pop
                navigator.pop();
              } catch (e) {
                // --- Check if mounted here too ---
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a hall first.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          child: const Text(
            'Re-allocate & Approve',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
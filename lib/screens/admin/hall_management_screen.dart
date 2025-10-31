import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';
import 'package:seminar_booking_app/widgets/admin/add_hall_dialog.dart';
import 'package:seminar_booking_app/widgets/admin/edit_hall_dialog.dart';

class HallManagementScreen extends StatelessWidget {
  const HallManagementScreen({super.key});

  void _showDeleteConfirmationDialog(
    BuildContext context, FirestoreService firestoreService, SeminarHall hall) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently delete ${hall.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Hall'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              
              try {
                await firestoreService.deleteHall(hall.id);

                if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Hall ${hall.name} deleted successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting hall: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  /// --- END NEW ---

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final firestoreService = context.read<FirestoreService>();

    // Security check
    if (appState.currentUser?.role != 'admin') {
      return const Scaffold(
        body: Center(child: Text('Access Denied.')),
      );
    }

    final halls = appState.halls;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Halls & Facilities'),
      ),
      body: halls.isEmpty
          ? const Center(child: Text('No halls found in the database.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: halls.length,
              itemBuilder: (context, index) {
                final hall = halls[index];
                return Card(
                  child: SwitchListTile(
                    title: Text(hall.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      hall.isAvailable ? 'Booking Active' : 'Booking Paused',
                      style: TextStyle(
                        color: hall.isAvailable
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                    value: hall.isAvailable,
                    onChanged: (bool value) {
                      firestoreService.updateHallAvailability(hall.id, value);
                    },
                    
                    /// --- MODIFIED ---
                    /// Changed to a Row to hold two buttons
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit Hall Details',
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return EditHallDialog(hall: hall);
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: Colors.red.shade700),
                          tooltip: 'Delete Hall',
                          onPressed: () {
                            _showDeleteConfirmationDialog(
                                context, firestoreService, hall);
                          },
                        ),
                      ],
                    ),
                    /// --- END MODIFIED ---
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const AddHallDialog();
            },
          );
        },
        tooltip: 'Add New Hall',
        child: const Icon(Icons.add),
      ),
    );
  }
}
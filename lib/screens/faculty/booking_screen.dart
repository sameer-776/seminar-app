import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/providers/app_state.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final availableHalls = appState.halls; // We show ALL halls, but indicate if blocked inside

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1: Select a Hall'),
        centerTitle: false,
      ),
      body: availableHalls.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "There are currently no seminar halls listed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: availableHalls.length,
              itemBuilder: (context, index) {
                final hall = availableHalls[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    // ✅ FIX: Use push to keep navigation history
                    onTap: () {
                      context.push('/booking/availability/${hall.id}');
                    },
                    
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- IMAGE SECTION ---
                        SizedBox(
                          height: 150,
                          child: hall.imageUrl.isNotEmpty
                              ? Image.network(
                                  hall.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    return progress == null
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          color: Colors.grey, size: 40),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(Icons.business_outlined,
                                        color: Colors.grey, size: 40),
                                  ),
                                ),
                        ),

                        // --- DETAILS SECTION ---
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    hall.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  // ✅ Visual indicator if blocked
                                  if (!hall.isAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200)
                                      ),
                                      child: Text("BLOCKED", style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                                    )
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (hall.description.isNotEmpty)
                                Text(
                                  hall.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    avatar: const Icon(Icons.people_outline,
                                        size: 18),
                                    label: Text('Capacity: ${hall.capacity}'),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  const Row(
                                    children: [
                                      Text(
                                        'Select',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
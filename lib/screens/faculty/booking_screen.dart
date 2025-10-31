import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/providers/app_state.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final availableHalls =
        appState.halls.where((hall) => hall.isAvailable).toList();

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
                  "There are currently no seminar halls available for booking. Please check back later.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0), // Added padding
              itemCount: availableHalls.length,
              itemBuilder: (context, index) {
                final hall = availableHalls[index];

                // --- NEW VISUAL CARD ---
                return Card(
                  clipBehavior: Clip.antiAlias, // Clips the image to the card's shape
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    // Makes the whole card tappable
                    
                    // --- UPDATED ONTAP ---
                    onTap: () {
                      // Navigate using the Hall ID in the path
                      context.go('/booking/availability/${hall.id}');
                    },
                    // --- END UPDATED ONTAP ---
                    
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- IMAGE SECTION ---
                        SizedBox(
                          height: 150, // Give the image a fixed height
                          child: hall.imageUrl.isNotEmpty
                              ? Image.network(
                                  hall.imageUrl,
                                  fit: BoxFit.cover,
                                  // Loading and error builders for better UX
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
                                  // Placeholder if no image
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
                              Text(
                                hall.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              // Show description if it exists
                              if (hall.description.isNotEmpty)
                                Text(
                                  hall.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 12),
                              // --- CAPACITY & PROCEED ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Capacity Chip
                                  Chip(
                                    avatar: const Icon(Icons.people_outline,
                                        size: 18),
                                    label: Text('Capacity: ${hall.capacity}'),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  // "Select" text with icon
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
                // --- END OF NEW CARD ---
              },
            ),
    );
  }
}
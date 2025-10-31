// lib/screens/shared/facilities_screen.dart

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart'; // Import model

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  String? _selectedHallId;

  IconData getIconForFacility(String facilityName) {
    final lower = facilityName.toLowerCase();
    if (lower.contains('wi-fi')) return Icons.wifi_outlined;
    if (lower.contains('air conditioning')) return MdiIcons.fan;
    if (lower.contains('projector')) return Icons.videocam_outlined;
    if (lower.contains('podium')) return MdiIcons.podium;
    if (lower.contains('microphone')) return Icons.mic_none_outlined;
    if (lower.contains('conferencing')) return Icons.video_call_outlined;
    if (lower.contains('whiteboard')) return Icons.edit_note_outlined;
    if (lower.contains('computer')) return Icons.computer_outlined;
    if (lower.contains('wheelchair')) return Icons.accessible_rounded;
    if (lower.contains('sound system')) return Icons.volume_up_outlined;
    return Icons.check_box_outline_blank;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final halls = appState.halls;
    final theme = Theme.of(context);

    if (halls.isEmpty && !appState.isLoading) {
      return const Center(child: Text("No facilities to display."));
    }
    if (halls.isEmpty && appState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Safely set the initial selected hall
    if (_selectedHallId == null || !halls.any((h) => h.id == _selectedHallId)) {
      _selectedHallId = halls.first.id;
    }

    // Find the selected hall
    final SeminarHall selectedHall = halls.firstWhere((h) => h.id == _selectedHallId);

    return Scaffold(
      appBar: AppBar(title: const Text('Our Facilities')),
      body: ListView( // Changed to ListView
        padding: const EdgeInsets.all(16.0),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedHallId, // Use value instead of initialValue
            onChanged: (value) => setState(() => _selectedHallId = value!),
            items: halls.map((hall) => DropdownMenuItem(value: hall.id, child: Text(hall.name))).toList(),
            decoration: const InputDecoration(
              labelText: 'Select a Hall',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- ✅ NEW UI: IMAGE CARD ---
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedHall.imageUrl.isNotEmpty)
                  Image.network(
                    selectedHall.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.broken_image, size: 40)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedHall.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capacity: ${selectedHall.capacity}',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (selectedHall.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          selectedHall.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Amenities',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // --- ✅ NEW UI: LISTVIEW FOR AMENITIES ---
          if (selectedHall.facilities.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No listed amenities for this hall.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedHall.facilities.length,
              itemBuilder: (context, index) {
                final facility = selectedHall.facilities[index];
                return Card(
                  child: ListTile(
                    leading: Icon(getIconForFacility(facility), color: theme.colorScheme.primary),
                    title: Text(facility, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
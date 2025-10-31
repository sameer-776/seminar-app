import 'dart:io'; // <-- ADDED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';
import 'package:seminar_booking_app/services/storage_service.dart'; // <-- ADDED

// (kAvailableFacilities map is unchanged)
const Map<String, IconData> kAvailableFacilities = {
  'Projector': Icons.videocam_rounded,
  'Wi-Fi': Icons.wifi_rounded,
  'Air Conditioning': Icons.ac_unit_rounded,
  'Sound System': Icons.volume_up_rounded,
  'Microphone': Icons.mic_rounded,
  'Whiteboard': Icons.edit_note_rounded,
  'Computer': Icons.computer_rounded,
  'Wheelchair Access': Icons.accessible_rounded,
};

class AddHallDialog extends StatefulWidget {
  const AddHallDialog({super.key});

  @override
  State<AddHallDialog> createState() => _AddHallDialogState();
}

class _AddHallDialogState extends State<AddHallDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // --- UPDATED ---
  File? _imageFile; // To store the selected image file
  // --- END UPDATED ---

  final Set<String> _selectedFacilities = {};
  bool _isLoading = false;

  // --- ADDED ---
  final StorageService _storageService = StorageService();
  // --- END ADDED ---

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- ADDED ---
  /// Picks an image from the gallery
  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() => _imageFile = file);
    }
  }
  // --- END ADDED ---

  /// Handles the form submission
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) { // --- ADDED validation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image for the hall.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() => _isLoading = true);

      final firestoreService = context.read<FirestoreService>();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      String? newHallId;
      String? imageUrl;

      try {
        // We need to create the hall document *first* to get its ID
        final hallDoc = await firestoreService.createHallDocument(
          name: _nameController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
          facilities: _selectedFacilities.toList(),
          description: _descriptionController.text.trim(),
        );
        newHallId = hallDoc.id;

        // Now, upload the image using the new hall's ID as the name
        imageUrl = await _storageService.uploadHallImage(_imageFile!, newHallId);

        // Finally, update the hall document with the new image URL
        await firestoreService.updateHallImageUrl(newHallId, imageUrl);

        messenger.showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} added successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error adding hall: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // --- ADDED: Cleanup ---
        // If the upload failed after the doc was created, delete the doc
        if (newHallId != null && imageUrl == null) {
          await firestoreService.deleteHall(newHallId);
        }
        // --- END ADDED ---
        
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Hall'),
      content: _isLoading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ADDED: Image Picker ---
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 150,
                            width: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _imageFile == null
                                ? const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: FloatingActionButton.small(
                              onPressed: _pickImage,
                              tooltip: 'Pick Image',
                              child: const Icon(Icons.edit),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // --- END ADDED ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Hall Name',
                        hintText: 'e.g., Main Auditorium',
                        icon: Icon(Icons.meeting_room_outlined),
                      ),
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        hintText: 'e.g., 150',
                        icon: Icon(Icons.people_outline),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return 'Please enter capacity';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Includes projector and AV system.',
                        icon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 2,
                    ),
                    // --- "Image URL" TextFormField REMOVED ---
                    const SizedBox(height: 24),
                    Text(
                      'Select Facilities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 16),
                    
                    // (Facility Chips are unchanged)
                    Wrap(
                      spacing: 8.0, 
                      runSpacing: 4.0, 
                      children: kAvailableFacilities.entries.map((entry) {
                        // ... (rest of chip code is unchanged)
                        final facilityName = entry.key;
                        final facilityIcon = entry.value;
                        final isSelected =
                            _selectedFacilities.contains(facilityName);

                        return FilterChip(
                          label: Text(facilityName),
                          avatar: Icon(
                            facilityIcon,
                            size: 18,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedFacilities.add(facilityName);
                              } else {
                                _selectedFacilities.remove(facilityName);
                              }
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Hall'),
        ),
      ],
    );
  }
}
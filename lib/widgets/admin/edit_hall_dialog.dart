import 'dart:io'; // <-- ADDED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
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

class EditHallDialog extends StatefulWidget {
  final SeminarHall hall;
  const EditHallDialog({super.key, required this.hall});

  @override
  State<EditHallDialog> createState() => _EditHallDialogState();
}

class _EditHallDialogState extends State<EditHallDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _descriptionController;

  // --- UPDATED ---
  File? _imageFile; // Stores the *new* image file, if selected
  String? _existingImageUrl; // Stores the *current* image URL
  // --- END UPDATED ---

  late Set<String> _selectedFacilities;
  bool _isLoading = false;

  // --- ADDED ---
  final StorageService _storageService = StorageService();
  // --- END ADDED ---

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hall.name);
    _capacityController =
        TextEditingController(text: widget.hall.capacity.toString());
    _descriptionController =
        TextEditingController(text: widget.hall.description);
    
    // --- UPDATED ---
    _existingImageUrl = widget.hall.imageUrl; // Store the current URL
    // --- END UPDATED ---
        
    _selectedFacilities = widget.hall.facilities.toSet();
  }

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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final firestoreService = context.read<FirestoreService>();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      String newImageUrl = _existingImageUrl ?? '';

      try {
        // Check if a new image was selected
        if (_imageFile != null) {
          // 1. Upload the new image
          newImageUrl = await _storageService.uploadHallImage(
            _imageFile!,
            widget.hall.id, // Use existing hall ID
          );
          
          // 2. Delete the old image (if it exists)
          if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
            await _storageService.deleteImage(_existingImageUrl!);
          }
        }

        // 3. Update the hall document in Firestore
        await firestoreService.updateHall(
          hallId: widget.hall.id,
          name: _nameController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
          facilities: _selectedFacilities.toList(),
          description: _descriptionController.text.trim(),
          imageUrl: newImageUrl, // Pass the new or existing URL
        );

        if (mounted) {
          navigator.pop(); // Close the dialog on success
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Hall updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error updating hall: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
      title: const Text('Edit Seminar Hall'),
      content: _isLoading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _imageFile != null
                                  ? Image.file( // Show new file
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : (_existingImageUrl != null &&
                                          _existingImageUrl!.isNotEmpty)
                                      ? Image.network( // Show existing URL
                                          _existingImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              const Icon(Icons.broken_image,
                                                  color: Colors.grey, size: 50),
                                        )
                                      : const Center( // Show placeholder
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: FloatingActionButton.small(
                              onPressed: _pickImage,
                              tooltip: 'Change Image',
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
                      decoration: const InputDecoration(labelText: 'Hall Name'),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Capacity is required';
                        if (int.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- UPDATED ---
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Includes projector and AV system.',
                      ),
                      maxLines: 2,
                    ),
                    // --- "Image URL" TextFormField REMOVED ---
                    // --- END UPDATED ---

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
                          checkmarkColor:
                              Theme.of(context).colorScheme.onPrimary,
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
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
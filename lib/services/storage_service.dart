import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the user's gallery.
  /// Returns a File object, or null if the user cancels.
  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress image slightly
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String> uploadHallImage(File imageFile, String hallId) async {
    try {
      // Create a unique file name to prevent overwrites
      final String fileExtension = p.extension(imageFile.path);
      final String fileName = '$hallId$fileExtension';
      
      // Define the path in Firebase Storage
      final Reference ref = _storage.ref('hall_images/$fileName');

      // Upload the file
      final UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      // Handle errors
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // --- ✅ THIS FUNCTION IS NOW FIXED ---
  /// Deletes an image from Firebase Storage.
  Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return; // Nothing to delete
    
    // We removed the try...catch block.
    // We WANT the error to be thrown so the UI (the dialog)
    // can catch it and show the user that the deletion failed.
    
    // If the image URL is not a valid gs:// or https:// URL,
    // this line will throw an exception, which is what we want.
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      // If the object doesn't exist, we can safely ignore the error.
      // Otherwise, we re-throw it so the UI can catch it.
      if (e.code == 'object-not-found') {
        print('Image not found, skipping delete.');
      } else {
        print('Error deleting image: $e');
        rethrow;
      }
    } catch (e) {
      // Catch any other potential errors and re-throw them.
      print('Unexpected error deleting image: $e');
      rethrow;
    }
  }
  // --- END OF FIX ---
}
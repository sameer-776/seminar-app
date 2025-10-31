import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single seminar hall in the university.
/// This class is immutable and designed to work directly with Firestore.
class SeminarHall {
  final String id; // The document ID from Firestore
  final String name;
  final int capacity;
  final List<String> facilities;
  final bool isAvailable; // Admin-controlled booking status
  
  // --- ADDED ---
  final String imageUrl;    // URL for the hall's image
  final String description; // A short description
  // --- END ADDED ---

  SeminarHall({
    required this.id,
    required this.name,
    required this.capacity,
    required this.facilities,
    required this.isAvailable,
    // --- ADDED ---
    required this.imageUrl,
    required this.description,
    // --- END ADDED ---
  });

  /// Factory constructor to create a SeminarHall instance from a Firestore document.
  /// It provides default values for fields that might be missing in the database
  /// to prevent runtime errors.
  factory SeminarHall.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return SeminarHall(
      id: snapshot.id,
      name: data['name'] ?? 'Unnamed Hall',
      capacity: data['capacity'] ?? 0,
      facilities: List<String>.from(data['facilities'] ?? []),
      isAvailable: data['isAvailable'] ?? true, // Defaults to true if not set
      
      // --- ADDED ---
      // We default to an empty string. The UI will have to handle this.
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      // --- END ADDED ---
    );
  }
}
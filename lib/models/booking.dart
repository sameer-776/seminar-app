import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single booking request in the application.
/// This class is immutable and contains all the details related to an event booking,
/// with methods to easily convert to and from Firestore documents.
class Booking {
  final String id; // The document ID from Firestore
  final String title;
  final String purpose;
  final String hall;
  final String date; // Stored in "YYYY-MM-DD" format
  final String startTime; // Stored in "HH:MM" 24-hour format
  final String endTime; // Stored in "HH:MM" 24-hour format
  final String status; // e.g., "Pending", "Approved", "Rejected", "Cancelled"
  final String requestedBy; // User's display name
  final String requesterId; // User's unique ID (UID)
  final String department;
  final int expectedAttendees;
  final String additionalRequirements;
  final String? rejectionReason; // Optional reason if the booking is rejected

  Booking({
    required this.id,
    required this.title,
    required this.purpose,
    required this.hall,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.requestedBy,
    required this.requesterId,
    required this.department,
    required this.expectedAttendees,
    required this.additionalRequirements,
    this.rejectionReason,
  });

  /// Factory constructor to create a Booking instance from a Firestore document.
  /// Provides default values for all fields to ensure the app doesn't crash
  /// if a field is missing from the database.
  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return Booking(
      id: snapshot.id,
      title: data['title'] ?? 'Untitled Event',
      purpose: data['purpose'] ??'',
      hall: data['hall'] ?? 'N/A',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      status: data['status'] ?? 'Pending',
      requestedBy: data['requestedBy'] ?? 'Unknown User',
      requesterId: data['requesterId'] ?? '',
      department: data['department'] ?? 'N/A',
      expectedAttendees: data['expectedAttendees'] ?? 0,
      additionalRequirements: data['additionalRequirements'] ?? '',
      rejectionReason: data['rejectionReason'],
    );
  }

  /// Converts the Booking instance into a Map that can be written to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'purpose': purpose,
      'hall': hall,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'requestedBy': requestedBy,
      'requesterId': requesterId,
      'department': department,
      'expectedAttendees': expectedAttendees,
      'additionalRequirements': additionalRequirements,
      'rejectionReason': rejectionReason,
    };
  }
}
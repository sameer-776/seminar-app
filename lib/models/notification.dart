import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an in-app notification for a user.
/// This class is immutable and designed to be created when a cloud function
/// or an in-app action triggers a notification event.
@immutable
class AppNotification {
  final String id; // The document ID from Firestore
  final String userId; // The UID of the user who should receive this notification
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? bookingId;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.bookingId, 
  });

  /// Factory constructor to create an AppNotification from a Firestore document.
  factory AppNotification.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return AppNotification(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'No Title',
      body: data['body'] ?? 'No Content',
      // Convert Firestore Timestamp to DateTime
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      // --- ADDED ---
      // This will be null if the 'bookingId' field doesn't exist
      bookingId: data['bookingId'], 
      // --- END ADDED ---
    );
  }

  /// Converts the AppNotification instance into a Map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'bookingId': bookingId, // --- ADDED ---
    };
  }

  /// Creates a copy of the instance with updated values.
  AppNotification copyWith({bool? isRead, String? bookingId}) { // --- UPDATED ---
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId ?? this.bookingId, // --- UPDATED ---
    );
  }
}
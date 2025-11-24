// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// Note: We are NOT importing cloud_functions here, as we are on the free plan.
import 'package:seminar_booking_app/models/user.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:seminar_booking_app/models/notification.dart';
import 'package:seminar_booking_app/services/storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER METHODS ---
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String department,
    required String employeeId,
    String role = 'Faculty',
    String? photoUrl,
  }) {
    return _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'department': department,
      'employeeId': employeeId,
      'role': role,
      'fcmTokens': [],
      'photoUrl': photoUrl,
    });
  }

  Future<User?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? User.fromFirestore(doc) : null;
  }

  Stream<List<User>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  Future<void> saveUserToken(String userId, String token) {
    return _db.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    // We allow name, department, and employeeId to be updated.
    data.remove('email');
    data.remove('role');
    return _db.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) {
    // This only deletes the Firestore document, not the Auth user.
    return _db.collection('users').doc(uid).delete();
  }

  
  // --- HALL METHODS ---
  Stream<List<SeminarHall>> getSeminarHalls() {
    return _db.collection('seminarHalls').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SeminarHall.fromFirestore(doc)).toList());
  }

  Future<void> updateHallAvailability(String hallId, bool isAvailable) {
    return _db
        .collection('seminarHalls')
        .doc(hallId)
        .update({'isAvailable': isAvailable});
  }

  Future<DocumentReference> createHallDocument({
    required String name,
    required int capacity,
    required List<String> facilities,
    required String description,
  }) {
    return _db.collection('seminarHalls').add({
      'name': name,
      'capacity': capacity,
      'facilities': facilities,
      'description': description,
      'isAvailable': true,
      'imageUrl': '',
    });
  }

  Future<void> updateHallImageUrl(String hallId, String imageUrl) {
    return _db
        .collection('seminarHalls')
        .doc(hallId)
        .update({'imageUrl': imageUrl});
  }

  Future<void> updateHall({
    required String hallId,
    required String name,
    required int capacity,
    required List<String> facilities,
    required String description,
    required String imageUrl,
  }) {
    return _db.collection('seminarHalls').doc(hallId).update({
      'name': name,
      'capacity': capacity,
      'facilities': facilities,
      'description': description,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteHall(String hallId) async {
    try {
      final doc = await _db.collection('seminarHalls').doc(hallId).get();
      if (!doc.exists) return;
      
      final imageUrl = doc.data()?['imageUrl'] as String?;
    
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final storageService = StorageService(); 
        await storageService.deleteImage(imageUrl);
      }
    
      await _db.collection('seminarHalls').doc(hallId).delete();
      
    } catch (e) {
      print('Error deleting hall: $e');
      rethrow;
    }
  }
  
  // --- BOOKING METHODS ---
  Stream<List<Booking>> getAllBookings() {
    return _db.collection('bookings').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Stream<List<Booking>> getUserBookings(String uid) {
    return _db
        .collection('bookings')
        .where('requesterId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Future<void> addBooking(Booking booking) {
    return _db.collection('bookings').add(booking.toJson());
  }

  /// ✅ NEW: Adds a booking and returns the document ID
  Future<String> addBookingAndGetRef(Booking booking) async {
    final docRef = await _db.collection('bookings').add(booking.toJson());
    return docRef.id;
  }

  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) {
    return _db.collection('bookings').doc(bookingId).update(data);
  }

  Future<void> cancelBooking(String bookingId) {
    return _db
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'Cancelled'});
  }
  
  // --- NOTIFICATION METHODS ---
  
  /// ✅ NEW: Gets all admin UIDs from the users collection
  Future<List<String>> getAllAdminUIDs() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting admin UIDs: $e');
      return [];
    }
  }
  
  Stream<List<AppNotification>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  Future<void> markNotificationsAsRead(List<String> notificationIds) async {
    final batch = _db.batch();
    for (final id in notificationIds) {
      final docRef = _db.collection('notifications').doc(id);
      batch.update(docRef, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? bookingId,
  }) {
    return _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'bookingId': bookingId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- ROLE MANAGEMENT ---
  Future<String?> changeUserRole({
    required String uid,
    required String newRole,
  }) async {
    // This is a simple database write, allowed by our Firestore rules.
    // No Cloud Function is needed.
    try {
      await _db.collection('users').doc(uid).update({'role': newRole});
      return null; // Success
    } catch (e) {
      print("Error changing user role: $e");
      return e.toString(); // Return the error
    }
  }
}
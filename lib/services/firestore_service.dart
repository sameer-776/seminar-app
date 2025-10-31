import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:seminar_booking_app/models/user.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:seminar_booking_app/models/notification.dart';
import 'package:seminar_booking_app/services/storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ✅ FIX: Added photoUrl parameter ---
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String department,
    required String employeeId,
    String role = 'Faculty',
    String? photoUrl, // Added this
  }) {
    return _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'department': department,
      'employeeId': employeeId,
      'role': role,
      'fcmTokens': [],
      'photoUrl': photoUrl, // Added this
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
    data.remove('email');
    data.remove('role');
    return _db.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) {
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

  // --- ROLE MANAGEMENT ---
  Future<String?> changeUserRole({
    required String uid,
    required String newRole,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('changeUserRole');
      await callable.call(<String, dynamic>{
        'uid': uid,
        'newRole': newRole,
      });
      await _db.collection('users').doc(uid).update({'role': newRole});
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected client-side error occurred.";
    }
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seminar_booking_app/services/auth_service.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';
import 'package:seminar_booking_app/models/user.dart';
import 'package:seminar_booking_app/models/seminar_hall.dart';
import 'package:seminar_booking_app/models/booking.dart';
import 'package:seminar_booking_app/models/notification.dart';
import 'package:collection/collection.dart';

class AppState with ChangeNotifier {
  final AuthService authService;
  final FirestoreService firestoreService;

  User? _currentUser;
  bool _isLoading = true;
  bool _isDarkMode = true;
  List<SeminarHall> _halls = [];
  List<Booking> _bookings = [];
  List<AppNotification> _notifications = [];
  List<User> _allUsers = [];

  late StreamSubscription<User?> _authSubscription;
  StreamSubscription<List<SeminarHall>>? _hallsSubscription;
  StreamSubscription<List<Booking>>? _bookingsSubscription;
  StreamSubscription<List<User>>? _allUsersSubscription;
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;

  // Public Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isDarkMode => _isDarkMode;
  List<SeminarHall> get halls => _halls;
  List<Booking> get bookings => _bookings;
  List<AppNotification> get notifications => _notifications;
  List<User> get allUsers => _allUsers;

  int get unreadNotificationCount {
    if (_currentUser == null) return 0;
    return _notifications
        .where((n) => n.userId == _currentUser!.uid && !n.isRead)
        .length;
  }

  AppState({required this.authService, required this.firestoreService}) {
    _authSubscription = authService.user.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _currentUser = user;
    _isLoading = false; 

    _hallsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _allUsersSubscription?.cancel();
    _notificationsSubscription?.cancel();

    if (user != null) {
      _hallsSubscription = firestoreService.getSeminarHalls().listen((halls) {
        _halls = halls;
        notifyListeners();
      });
      _notificationsSubscription =
          firestoreService.getNotifications(user.uid).listen((notifications) {
        _notifications = notifications;
        notifyListeners();
      });

      if (user.role == 'admin') {
        _bookingsSubscription =
            firestoreService.getAllBookings().listen((bookings) {
          _bookings = bookings;
          notifyListeners();
        });
        _allUsersSubscription = firestoreService.getAllUsers().listen((users) {
          _allUsers = users;
          notifyListeners();
        });
      } else {
        _bookingsSubscription =
            firestoreService.getUserBookings(user.uid).listen((bookings) {
          _bookings = bookings;
          notifyListeners();
        });
        _allUsers = [];
      }
    } else {
      _halls = [];
      _bookings = [];
      _allUsers = [];
      _notifications = [];
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await authService.signInWithEmailAndPassword(email, password);
      if (user == null) {
        _isLoading = false;
        notifyListeners();
      }
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<User?> googleLogin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await authService.signInWithGoogle();
      if (user == null) {
        _isLoading = false;
        notifyListeners();
      }
      return user;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow; 
    }
  }

  Future<void> logout() async {
    await authService.signOut();
  }

  Future<void> updateUserProfile({
    required String name,
    required String department,
    required String employeeId,
  }) async {
    if (_currentUser == null) return;
    
    final updateData = {
      'name': name,
      'department': department,
      'employeeId': employeeId,
    };
    
    await firestoreService.updateUserProfile(_currentUser!.uid, updateData);

    // Manually update local state
    _currentUser = User(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      role: _currentUser!.role,
      fcmTokens: _currentUser!.fcmTokens,
      photoUrl: _currentUser!.photoUrl,
      name: name,
      department: department,
      employeeId: employeeId,
    );
    
    notifyListeners();
  }

  Future<String?> updateUserRole(String uid, String newRole) async {
    final error = await firestoreService.changeUserRole(uid: uid, newRole: newRole);
    if (error == null) {
      final userIndex = _allUsers.indexWhere((u) => u.uid == uid);
      if (userIndex != -1) {
        _allUsers[userIndex] = User(
          uid: _allUsers[userIndex].uid,
          name: _allUsers[userIndex].name,
          email: _allUsers[userIndex].email,
          department: _allUsers[userIndex].department,
          employeeId: _allUsers[userIndex].employeeId,
          fcmTokens: _allUsers[userIndex].fcmTokens,
          photoUrl: _allUsers[userIndex].photoUrl,
          role: newRole,
        );
        notifyListeners();
      }
    }
    return error;
  }

  // --- ✅ NEW: Helper to find WHO is blocking the slot ---
  Booking? getConflictingBooking(String hallName, String date, String startTime, String endTime, {String? excludeBookingId}) {
    try {
      final requestStart = DateTime.parse('$date $startTime');
      final requestEnd = DateTime.parse('$date $endTime');

      // Filter for relevant "Approved" bookings
      final relevantBookings = _bookings.where((b) {
        // Exclude current booking if editing/reviewing
        if (excludeBookingId != null && b.id == excludeBookingId) return false;
        
        return b.hall == hallName &&
               b.date == date &&
               b.status == 'Approved'; // Only check against CONFIRMED bookings
      }).toList();

      for (var existing in relevantBookings) {
        final existingStart = DateTime.parse('${existing.date} ${existing.startTime}');
        final existingEnd = DateTime.parse('${existing.date} ${existing.endTime}');

        // Check overlap: (StartA < EndB) and (EndA > StartB)
        if (requestStart.isBefore(existingEnd) && requestEnd.isAfter(existingStart)) {
          return existing; // Return the specific booking that blocks us
        }
      }
    } catch (e) {
      print("Error checking conflict: $e");
    }
    return null; // No conflict found
  }

  // Helper that just returns true/false
  bool checkBookingConflict(String hallName, String date, String startTime, String endTime, {String? excludeBookingId}) {
    return getConflictingBooking(hallName, date, startTime, endTime, excludeBookingId: excludeBookingId) != null;
  }

  // ✅ UPDATED: Checks conflict before submitting
  Future<void> submitBooking(Booking booking) async {
    // Check for conflicts against existing Approved bookings
    if (checkBookingConflict(booking.hall, booking.date, booking.startTime, booking.endTime)) {
      throw Exception("This time slot is already booked! Please choose another time.");
    }
    
    // 1. Create the booking document
    final bookingDocRef = await firestoreService.addBookingAndGetRef(booking);
    
    // 2. ✅ NEW: Create notifications for all admins
    try {
      final adminUIDs = await firestoreService.getAllAdminUIDs();
      if (adminUIDs.isNotEmpty) {
        for (final adminUID in adminUIDs) {
          await firestoreService.createNotification(
            userId: adminUID,
            title: 'New Booking Request',
            body: '${booking.requestedBy} has requested ${booking.hall} for ${booking.date}.',
            bookingId: bookingDocRef,
          );
        }
      }
    } catch (e) {
      print('Error creating admin notifications: $e');
      // Don't rethrow - booking was successfully created, just notification failed
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await firestoreService.cancelBooking(bookingId);
  }

  // ✅ UPDATED: Checks conflict before Approving
  Future<void> reviewBooking({
    required String bookingId,
    required String newStatus,
    String? rejectionReason,
    String? newHall,
  }) async {
    final updateData = <String, dynamic>{
      'status': newStatus,
    };
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    if (newHall != null) {
      updateData['hall'] = newHall;
    }

    // 1. If Approving, check for conflicts
    if (newStatus == 'Approved') {
      final booking = _bookings.firstWhere((b) => b.id == bookingId);
      // Use the new hall if re-allocating, otherwise the original hall
      final targetHall = newHall ?? booking.hall; 
      
      if (checkBookingConflict(targetHall, booking.date, booking.startTime, booking.endTime, excludeBookingId: bookingId)) {
         throw Exception("Cannot approve! This overlaps with another APPROVED event.");
      }
    }
    
    // 2. Update in Firestore
    await firestoreService.updateBooking(bookingId, updateData);

    // 3. Manually create notification
    if (newStatus == 'Approved' || newStatus == 'Rejected') {
      final booking = _bookings.firstWhereOrNull((b) => b.id == bookingId);
      if (booking != null) {
        final title = "Booking $newStatus!";
        String body = "Your request for '${booking.title}' has been ${newStatus.toLowerCase()}.";
        if(newStatus == 'Approved' && newHall != null) {
          body += " It has been re-allocated to $newHall.";
        }
        await firestoreService.createNotification(
          userId: booking.requesterId,
          title: title,
          body: body,
          bookingId: bookingId,
        );
      }
    }
  }

  void markNotificationsAsRead() {
    if (_currentUser == null) return;
    final unreadIds =
        _notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isNotEmpty) {
      firestoreService.markNotificationsAsRead(unreadIds);
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _hallsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _allUsersSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
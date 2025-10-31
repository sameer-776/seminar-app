import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // Request permission from the user (required for iOS).
    await _fcm.requestPermission();

    // Handle incoming messages while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
      }
    });
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      return null;
    }
  }

  // This should be called right after a user logs in.
  Future<void> saveTokenToDatabase(String userId) async {
    String? token = await getToken();
    if (token != null) {
      await _firestoreService.saveUserToken(userId, token);
    }

    // Also listen for token refreshes and save the new one.
    _fcm.onTokenRefresh.listen((newToken) {
      if (userId.isNotEmpty) {
        _firestoreService.saveUserToken(userId, newToken);
      }
    });
  }
}
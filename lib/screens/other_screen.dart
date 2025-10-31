import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart' as core;
import 'package:seminar_booking_app/models/user.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// A stream that listens for authentication state changes and provides the
  /// corresponding user profile from Firestore.
  Stream<User?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      // When a user is logged in, fetch their profile from Firestore
      return await _firestoreService.getUser(firebaseUser.uid);
    });
  }

  /// Handles self-registration for Faculty users.
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String department,
    required String employeeId,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        return "An unknown error occurred.";
      }
      // This calls the updated createUser method with the default 'Faculty' role.
      await _firestoreService.createUser(
        uid: credential.user!.uid,
        name: name,
        email: email,
        department: department,
        employeeId: employeeId,
      );
      return null; // Return null on success
    } on auth.FirebaseAuthException catch (e) {
      return e.message; // Return the specific Firebase error message on failure
    }
  }

  /// Admin-only function to create a new user without signing out the admin.
  Future<String?> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String department,
    required String employeeId,
    required String role,
  }) async {
    const tempAppName = 'tempAdminAppCreation';
    core.FirebaseApp? tempApp;

    try {
      // Initialize a temporary, secondary Firebase App instance. This allows
      // us to create a user without affecting the currently logged-in admin.
      tempApp = await core.Firebase.initializeApp(
        name: tempAppName,
        options: core.Firebase.app().options, // Use options from the default app
      );
      
      // Get the auth instance associated with the temporary app.
      final tempAuth = auth.FirebaseAuth.instanceFor(app: tempApp);

      // Create the new user in Firebase Authentication.
      final credential = await tempAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (credential.user == null) {
        throw Exception("User creation failed in temporary Firebase app.");
      }

      // Create the user document in Firestore with the specified role.
      await _firestoreService.createUser(
        uid: credential.user!.uid,
        name: name,
        email: email,
        department: department,
        employeeId: employeeId,
        role: role, // Pass the role provided by the admin
      );

      return null; // Success
    } on auth.FirebaseAuthException catch (e) {
      return e.message; // Return specific auth error
    } catch (e) {
      print("Admin user creation error: $e");
      return "An unexpected error occurred.";
    } finally {
      // IMPORTANT: Always delete the temporary app instance to clean up resources.
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  /// Handles user sign-in.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) return null;
      return await _firestoreService.getUser(credential.user!.uid);
    } catch (e) {
      return null;
    }
  }

  /// Sends a password reset email to the specified address.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } on auth.FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }
}
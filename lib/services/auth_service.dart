// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart' as core;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seminar_booking_app/models/user.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';
// ❌ Removed cloud_functions import

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return await _firestoreService.getUser(firebaseUser.uid);
    });
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      if (!googleUser.email.endsWith('@poornima.edu.in')) {
        await _googleSignIn.signOut();
        throw auth.FirebaseAuthException(
          code: 'invalid-email-domain',
          message: 'Only @poornima.edu.in emails are allowed.',
        );
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final auth.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return null;
      }
      User? appUser = await _firestoreService.getUser(firebaseUser.uid);
      if (appUser == null) {
        await _firestoreService.createUser(
          uid: firebaseUser.uid,
          name: googleUser.displayName ?? 'Poornima User',
          email: googleUser.email,
          department: 'Unknown',
          employeeId: '0000',
          role: 'Faculty',
          photoUrl: googleUser.photoUrl,
        );
        appUser = await _firestoreService.getUser(firebaseUser.uid);
      }
      return appUser;
    } on auth.FirebaseAuthException {
       rethrow;
    } catch (e) {
      print("An unexpected error occurred during Google Sign-In: $e");
      return null;
    }
  }

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
      tempApp = await core.Firebase.initializeApp(
        name: tempAppName,
        options: core.Firebase.app().options,
      );
      final tempAuth = auth.FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (credential.user == null) {
        throw Exception("User creation failed in temporary Firebase app.");
      }
      await _firestoreService.createUser(
        uid: credential.user!.uid,
        name: name,
        email: email,
        department: department,
        employeeId: employeeId,
        role: role,
        photoUrl: null, 
      );
      return null;
    } on auth.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      print("Admin user creation error: $e");
      return "An unexpected error occurred.";
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } on auth.FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
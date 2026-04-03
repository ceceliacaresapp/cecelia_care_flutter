import 'package:firebase_auth/firebase_auth.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';

// A service class for Firebase Authentication operations.
class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// --------------------------------------------------------------------------
  /// 1) AUTHENTICATION‐RELATED METHODS
  /// --------------------------------------------------------------------------

  /// Static getter for the currently signed‐in Firebase [User].
  /// Returns null if nobody is signed in.
  static User? get currentUser => _firebaseAuth.currentUser;

  /// Static getter for the current user's UID.
  /// Returns null if no user is signed in.
  static String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Stream of user state changes (signed in / signed out).
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// Sign in with email & password. Throws FirebaseAuthException on failure.
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(), // Trim email
      password: password,
    );
  }

  /// Create a new account (email & password). Throws FirebaseAuthException on failure.
  /// Optionally, you might want to create a user document in Firestore here as well.
  Future<UserCredential> createUserWithEmailAndPassword({
    // Renamed from signUp
    required String email,
    required String password,
    // String? displayName, // Optional: if you want to set display name immediately
  }) async {
    UserCredential userCredential = await _firebaseAuth
        .createUserWithEmailAndPassword(
          email: email.trim(), // Trim email
          password: password,
        );
    // if (displayName != null && userCredential.user != null) {
    //   await userCredential.user!.updateDisplayName(displayName);
    // }
    // Consider creating a user profile document in Firestore here
    // e.g., using a method from UserProfileProvider or FirestoreService
    // if (userCredential.user != null) {
    //   Provider.of<UserProfileProvider>(context, listen: false).handleUserCreation(userCredential.user!);
    // }
    return userCredential;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    FirestoreService.clearProfileCache();
    await _firebaseAuth.signOut();
  }

  /// Asynchronously returns the current user’s UID, or null if not signed in.
  /// This is an alternative to the static getter if you prefer async access.
  Future<String?> getAsyncCurrentUserId() async {
    return _firebaseAuth.currentUser?.uid;
  }

  /// You can also expose displayName, email, photoURL if needed:
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;
  String? get currentUserDisplayName => _firebaseAuth.currentUser?.displayName;
  String? get currentUserPhotoURL => _firebaseAuth.currentUser?.photoURL;

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // --- CALENDAR EVENT METHODS HAVE BEEN REMOVED ---
  // These functionalities should be handled by FirestoreService or specific providers.
}

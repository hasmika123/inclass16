import 'package:firebase_auth/firebase_auth.dart';

/// Small wrapper around `FirebaseAuth` to centralize authentication calls.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Create a new user with email & password.
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Sign in existing user with email & password.
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign out the current user.
  Future<void> signOut() => _auth.signOut();

  /// Update current user's password. Throws when no user is signed in.
  Future<void> updatePassword(String newPassword) {
    final u = _auth.currentUser;
    if (u == null) {
      return Future.error(FirebaseAuthException(code: 'no-current-user', message: 'No user signed in'));
    }
    return u.updatePassword(newPassword);
  }
}

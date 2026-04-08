import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream — tells the app instantly when login state changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Sign up
  Future<User?> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // Sign in
  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // Sign out
  Future<void> signOut() => _auth.signOut();

  // Get current user ID
  String? get uid => _auth.currentUser?.uid;
}
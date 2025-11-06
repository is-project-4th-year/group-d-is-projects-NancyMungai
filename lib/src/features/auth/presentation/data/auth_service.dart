import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
   User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return userCred.user;
  }

  Future<User?> signUp(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return userCred.user;
  }

  Future<void> signOut() async => _auth.signOut();
}

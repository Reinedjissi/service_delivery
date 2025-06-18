import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    String res = "Une erreur s'est produite";
    try {
      // Enregistrer un utilisateur dans Firebase avec l'email et le mot de passe
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      res = "Reussit!";
    } catch (e) {
      print(e.toString());
      return e.toString(); // Renvoie l'erreur
    }
    return res;
  }

  Future<User?> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      UserCredential credential =  await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

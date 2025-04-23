import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> signUpUser({
    required String email,
    required String password,
    required String name, // Ajout du type String
  }) async {
    String res = "Une erreur s'est produite";
    try {
      // Enregistrer un utilisateur dans Firebase avec l'email et le mot de passe
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ajouter l'utilisateur dans Firestore
      await _firestore.collection("utilisateurs").doc(credential.user!.uid).set({
        "nom": name,
        "email": email,
        "uid": credential.user!.uid, // Correction ici
      });

      res = "Reussit!";
    } catch (e) {
      print(e.toString());
     return e.toString(); // Renvoie l'erreur
    }
    return res;
  }
  Future<String> signInUser({
    required String email,
    required String password
})async{
    String res = "Une erreur s'est produite";
    try{
      if(email.isNotEmpty || password.isNotEmpty){
        await _auth.signInWithEmailAndPassword(
            email: email,
            password: password
        );
        res = "Reussit!";
      }else{
        res = "Veuillez entrer vos informations";
      }
    }catch(e){
      return e.toString();
    }
    return res;
  }
  Future<void> signOut() async {
    await _auth.signOut();
  }


}


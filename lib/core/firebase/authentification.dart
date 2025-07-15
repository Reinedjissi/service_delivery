import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Méthode d'inscription complète avec nom d'utilisateur
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name
  }) async {
    String res = "Une erreur s'est produite";
    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        // Créer l'utilisateur avec email et mot de passe
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Mettre à jour le profil utilisateur avec le nom
        await credential.user?.updateDisplayName(name);

        // Sauvegarder les informations utilisateur dans Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        res = "Inscription réussie!";
      } else {
        res = "Veuillez remplir tous les champs";
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          res = "Le mot de passe est trop faible";
          break;
        case 'email-already-in-use':
          res = "Un compte existe déjà pour cet email";
          break;
        case 'invalid-email':
          res = "L'adresse email n'est pas valide";
          break;
        default:
          res = "Erreur d'inscription: ${e.message}";
      }
    } catch (e) {
      res = "Une erreur inattendue s'est produite: ${e.toString()}";
    }
    return res;
  }

  // Méthode de connexion améliorée
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password
  }) async {
    String res = "Une erreur s'est produite";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password
        );

        if (credential.user != null) {
          res = "Connexion réussie!";
        }
      } else {
        res = "Veuillez remplir tous les champs";
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          res = "Aucun utilisateur trouvé pour cet email";
          break;
        case 'wrong-password':
          res = "Mot de passe incorrect";
          break;
        case 'invalid-email':
          res = "L'adresse email n'est pas valide";
          break;
        case 'user-disabled':
          res = "Ce compte a été désactivé";
          break;
        case 'too-many-requests':
          res = "Trop de tentatives. Veuillez réessayer plus tard";
          break;
        default:
          res = "Erreur de connexion: ${e.message}";
      }
    } catch (e) {
      res = "Une erreur inattendue s'est produite: ${e.toString()}";
    }
    return res;
  }

  // Méthode de déconnexion
  Future<String> signOut() async {
    try {
      await _auth.signOut();
      return "Déconnexion réussie!";
    } catch (e) {
      return "Erreur lors de la déconnexion: ${e.toString()}";
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<String> resetPassword({required String email}) async {
    String res = "Une erreur s'est produite";
    try {
      if (email.isNotEmpty) {
        await _auth.sendPasswordResetEmail(email: email);
        res = "Email de réinitialisation envoyé!";
      } else {
        res = "Veuillez entrer votre adresse email";
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          res = "Aucun utilisateur trouvé pour cet email";
          break;
        case 'invalid-email':
          res = "L'adresse email n'est pas valide";
          break;
        default:
          res = "Erreur: ${e.message}";
      }
    } catch (e) {
      res = "Une erreur inattendue s'est produite: ${e.toString()}";
    }
    return res;
  }

  // Méthode pour obtenir les données utilisateur depuis Firestore
  Future<DocumentSnapshot?> getUserData({required String uid}) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc;
    } catch (e) {
      print("Erreur lors de la récupération des données utilisateur: ${e.toString()}");
      return null;
    }
  }

  // Méthode pour mettre à jour les données utilisateur
  Future<String> updateUserData({
    required String uid,
    required Map<String, dynamic> data
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return "Données mises à jour avec succès!";
    } catch (e) {
      return "Erreur lors de la mise à jour: ${e.toString()}";
    }
  }

  // Méthode pour supprimer le compte utilisateur
  Future<String> deleteAccount({required String password}) async {
    String res = "Une erreur s'est produite";
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Ré-authentifier l'utilisateur avant la suppression
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // Supprimer les données Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Supprimer le compte
        await user.delete();

        res = "Compte supprimé avec succès!";
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          res = "Mot de passe incorrect";
          break;
        case 'requires-recent-login':
          res = "Veuillez vous reconnecter avant de supprimer votre compte";
          break;
        default:
          res = "Erreur lors de la suppression: ${e.message}";
      }
    } catch (e) {
      res = "Une erreur inattendue s'est produite: ${e.toString()}";
    }
    return res;
  }

  // Méthode pour vérifier si l'email est vérifié
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Méthode pour envoyer un email de vérification
  Future<String> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return "Email de vérification envoyé!";
      }
      return "Email déjà vérifié ou utilisateur non connecté";
    } catch (e) {
      return "Erreur lors de l'envoi de l'email: ${e.toString()}";
    }
  }
}
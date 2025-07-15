import 'package:service_delivery/core/firebase/authentification.dart';

class AuthRepository extends AuthServices {

  // Méthode pour créer un utilisateur avec email et mot de passe
  Future<String> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? name, // Paramètre optionnel pour le nom
  }) async {
    try {
      // Utiliser la méthode signUpUser de la classe parent
      return await signUpUser(
        email: email,
        password: password,
        name: name ?? '', // Utiliser une chaîne vide si name est null
      );
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: ${e.toString()}');
    }
  }

  // Méthode pour se connecter avec email et mot de passe
  @override
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await super.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  // Méthode pour se déconnecter
  @override


  // Méthode pour créer un utilisateur avec nom, email et mot de passe
  @override
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      return await super.signUpUser(email: email, password: password, name: name);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }
}
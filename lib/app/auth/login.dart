import 'package:flutter/material.dart';
import 'package:service_delivery/app/auth/sign_up.dart';
import 'package:service_delivery/app/home/home.dart';
import 'package:service_delivery/app/widgets/button.dart';
import 'package:service_delivery/core/utils/asset_path.dart';
import 'package:service_delivery/core/utils/authentification.dart';


class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void login() async {
    String res = await AuthServices().signInUser(
      email: emailController.text,
      password: passwordController.text,
    );


    if (res == "Reussit!") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => home(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      // Affiche une Snackbar avec le message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image en haut de l'écran
              SizedBox(
                height: height / 3,
                width: double.infinity,
                child: Image.asset(
                  AssetPath.onboardingImg3,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),

              // Champ email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Entrez votre email",
                    prefixIcon: const Icon(Icons.email, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 20),

              // Champ mot de passe
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    hintText: "Entrez votre mot de passe",
                    prefixIcon: const Icon(Icons.lock, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true, // Masquer le mot de passe
                ),
              ),
              const SizedBox(height: 10),

              // Lien mot de passe oublié
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // Ajouter la logique pour "Mot de passe oublié"
                    },
                    child: const Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton de connexion
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isLoading
                    ? const CircularProgressIndicator() // Indicateur de chargement
                    : MyButton(
                  onTab: login,
                  text: "Connexion",
                ),
              ),
              SizedBox(height: height / 20),

              // Lien pour créer un compte
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Pas de compte ?",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUp(),
                        ),
                      );
                    },
                    child: const Text(
                      "Créer un compte",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
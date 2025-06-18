import 'package:flutter/material.dart';
import 'package:service_delivery/app/auth/view/Login_page.dart';
import 'package:service_delivery/app/widgets/button.dart';
import 'package:service_delivery/core/utils/asset_path.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
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

/*
  void signUp() async {
    setState(() {
      isLoading = true; // Début du chargement
    });

    String res = await AuthServices().signUpUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
    );

    if (res == "Reussit!!!!!") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Hom(),
        ),
      );
    } else {
      showSnackBar(context, res); // Afficher l'erreur
    }

    setState(() {
      isLoading = false; // Fin du chargement
    });
  }
*/

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  AssetPath.onboardingImg2,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Entrez votre nom",
                  prefixIcon: Icon(Icons.person, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Entrez votre email",
                  prefixIcon: Icon(Icons.email, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: "Entrez votre mot de passe",
                  prefixIcon: Icon(Icons.lock, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true, // Masquer le mot de passe
              ),
            ),
            const SizedBox(height: 20),
            MyButton(
              onTab: () {},
              text: "Créer",
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Vous avez déjà un compte ?",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Se connecter",
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
    );
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

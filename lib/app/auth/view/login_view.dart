import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_delivery/app/auth/bloc/auth.dart';
import 'package:service_delivery/app/auth/sign_up.dart';
import 'package:service_delivery/app/home/home_page.dart';
import 'package:service_delivery/app/home/home_view.dart';
import 'package:service_delivery/app/widgets/button.dart';
import 'package:service_delivery/core/utils/asset_path.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  _obscureText() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Colors.white,
        body: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(listener: (_, state) {
              if (state is AuthLoading) {
              } else if (state is AuthLoadingSuccess) {
                Navigator.pushReplacementNamed(context, HomePage.routeName);
              } else if (state is AuthLoadingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage)),
                );
              }
            }),
          ],
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: height / 3,
                    width: double.infinity,
                    child: Image.asset(
                      AssetPath.onboardingImg3,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextFormField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  hintText: "Entrez votre email",
                                  prefixIcon: const Icon(Icons.email,
                                      color: Colors.purple),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  return null;
                                }),
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextFormField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                hintText: "Entrez votre mot de passe",
                                prefixIcon: const Icon(Icons.lock,
                                    color: Colors.purple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.purple,
                                  ),
                                  onPressed: _obscureText,
                                ),
                              ),
                              obscureText: !_showPassword, //
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                return null;
                              },
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
                                    onTab: _submitLoginForm,
                                    text: "Connexion",
                                  ),
                          ),
                          SizedBox(height: height / 20),
                        ],
                      )),

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
        ));
  }

  void _submitLoginForm() async {
    //valid form
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<AuthBloc>(context).add(LoginButtonPressedEvent(
        email: emailController.text,
        password: passwordController.text,
      ));
    }
  }
}

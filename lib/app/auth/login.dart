import 'package:flutter/material.dart';
import 'package:service_delivery/onbeading_screen.dart';

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(child: const Text('Login Screen')),
    );
  }
}

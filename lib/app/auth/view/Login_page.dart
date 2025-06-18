import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_delivery/app/auth/bloc/auth_bloc.dart';
import 'package:service_delivery/app/auth/view/login_view.dart';

class LoginPageArgument {}

class LoginPage extends StatelessWidget {
  static const String routeName = '/login';

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider(create: (context) => AuthBloc()),
    ], child: const Login());
  }
}

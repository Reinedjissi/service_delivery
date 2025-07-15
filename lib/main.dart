import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:service_delivery/app/auth/sign_up.dart';
import 'package:service_delivery/app/auth/view/Login_page.dart';
import 'package:service_delivery/app/home/home_page.dart';
import 'package:service_delivery/app/home/home_view.dart';
import 'package:service_delivery/core/utils/routes.dart';
import 'package:service_delivery/firebase_options.dart';

import 'app/splash_screen/onbeading_screen.dart';
import 'app/users/admin/views/dashboad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Bloc.observer = const AppBlocObserver();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Delivery',
      home: SignUp(),
      routes: routes,
    );
  }
}

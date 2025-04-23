import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:service_delivery/app/home/home.dart';
import 'package:service_delivery/app/users/client/client_home.dart';
import 'package:service_delivery/firebase_options.dart';

import 'app/splash_screen/onbeading_screen.dart';
import 'app/users/admin/dashboad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Marketplace',
      home: Dashboard(),

    );
  }
}

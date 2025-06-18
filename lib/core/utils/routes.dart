import 'package:flutter/material.dart';
import 'package:service_delivery/app/auth/view/Login_page.dart';
import 'package:service_delivery/app/home/home_page.dart';
import 'package:service_delivery/app/splash_screen/onbeading_screen.dart';
import 'package:service_delivery/app/users/admin/views/admin_categorie.dart';

Map<String, WidgetBuilder> routes = {
  MyOnboarding.routeName: (_) => const MyOnboarding(),
  LoginPage.routeName: (_) => const LoginPage(),
  HomePage.routeName: (_) => const HomePage(),
  AdminCategories.routeName: (_) => const AdminCategories()
};

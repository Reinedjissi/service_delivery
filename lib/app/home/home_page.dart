import 'package:flutter/material.dart';
import 'package:service_delivery/app/home/home_view.dart';

class HomePageArgument{

}

class HomePage extends StatelessWidget {
  static const String routeName = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeView();
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_delivery/app/users/admin/views/admin_categorie.dart';
import 'package:service_delivery/app/users/admin/views/admin_projets.dart';
import 'package:service_delivery/app/users/admin/views/admin_services.dart';
import 'package:service_delivery/app/users/admin/views/admin_statistique.dart';
import 'package:service_delivery/app/users/admin/views/admin_users.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int categoryCount = 0;
  int serviceCount = 0;
  int userCount = 0;
  int reservationCount = 0;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    final firestore = FirebaseFirestore.instance;

    final categories = await firestore.collection('categories').get();
    final services = await firestore.collection('services').get();
    final users = await firestore.collection('users').get();
    final reservations = await firestore.collection('reservations').get();

    setState(() {
      categoryCount = categories.size;
      serviceCount = services.size;
      userCount = users.size;
      reservationCount = reservations.size;
    });
  }

  void navigateWithSlide(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return SlideTransition(position: tween.animate(curved), child: child);
        },
      ),
    );
  }

  Widget buildDashboardCard(String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 160,
          height: 130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text('$count', style: TextStyle(fontSize: 24, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;


    final crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4);

    return Scaffold(
      appBar: AppBar(title: const Text("Tableau de bord")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            buildDashboardCard(
              "Catégories",
              categoryCount,
              Icons.category,
              Colors.blue,
                  () {
                    navigateWithSlide(context, const AdminCategories());
                  },
            ),
            buildDashboardCard(
              "Services",
              serviceCount,
              Icons.home_repair_service,
              Colors.green,

                  () => navigateWithSlide(context, const AdminServices()),
            ),
            buildDashboardCard(
              "Clients",
              userCount,
              Icons.person,
              Colors.orange,
                  () => navigateWithSlide(context, const AdminClients()),
            ),
            buildDashboardCard(
              "projets",
              userCount,
              Icons.perm_data_setting_outlined,
              Colors.orange,
                  () => navigateWithSlide(context, const AdminProjets()),
            ),
            buildDashboardCard(
              "statistique",
                reservationCount,
                Icons.bar_chart,
              Colors.purple,
                 () => navigateWithSlide(context, const StatistiquesPage()),
            ),
          ],
        ),
      ),
    );
  }
}

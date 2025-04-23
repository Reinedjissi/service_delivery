import 'package:flutter/material.dart';
import 'package:service_delivery/app/users/admin/admin_services.dart';
import 'package:service_delivery/app/users/admin/admin_users.dart';
import 'admin_categorie.dart';

// TODO: importer les autres pages une fois créées

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;

  final List<String> menuTitles = [
    'Tableau de bord',
    'Utilisateurs',
    'Catégories',
    'Services',
    'Réservations',
    'Avis'
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.category,
    Icons.design_services,
    Icons.calendar_today,
    Icons.reviews
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar gauche
          Container(
            width: 220,
            color: Colors.deepPurple.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DrawerHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                      SizedBox(height: 10),
                      Text("Admin Panel",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ...List.generate(menuTitles.length, (index) {
                  return ListTile(
                    leading: Icon(menuIcons[index], color: Colors.white),
                    title: Text(menuTitles[index], style: TextStyle(color: Colors.white)),
                    selected: selectedIndex == index,
                    selectedTileColor: Colors.purple.shade900,
                    onTap: () {
                      setState(() => selectedIndex = index);
                    },
                  );
                }),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade100,
              child: _buildPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (selectedIndex) {
      case 0:
        return Center(child: Text("Bienvenue dans le Tableau de bord Admin", style: TextStyle(fontSize: 24)));
      case 1:
       return AdminUsers();// page utilisateurs
      case 2:
        return AdminCategories(); // page categorie
      case 3:
        return AdminServices(); //page service
      case 4:
        return Center(child: Text("Page Réservations")); // à remplacer
      case 5:
        return Center(child: Text("Page Avis")); // à remplacer
      default:
        return Center(child: Text("Sélectionnez une section"));
    }
  }
}

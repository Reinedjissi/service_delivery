import 'package:flutter/material.dart';
import 'package:service_delivery/app/users/admin/views/admin_dasboad.dart';
import 'package:service_delivery/app/users/admin/views/admin_projets.dart';
import 'package:service_delivery/app/users/admin/views/admin_services.dart';
import 'package:service_delivery/app/users/admin/views/admin_statistique.dart';
import 'package:service_delivery/app/users/admin/views/admin_users.dart';
import 'package:service_delivery/core/utils/asset_path.dart';
import 'admin_categorie.dart';


class Dashboard extends StatefulWidget {
  //static var routeName;

  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;

  final List<String> menuTitles = [
    'Tableau de bord',
    'clients',
    'Catégories',
    'Services',
    'Marchés',
    'statistique',
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.category,
    Icons.design_services,
    Icons.calendar_today,
    Icons.bar_chart,
  ];

  // Méthode pour gérer la déconnexion
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                // Naviguer vers la page de connexion et supprimer toutes les routes précédentes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', // Remplacez par votre route de login
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;

        return Scaffold(
          appBar: isMobile
              ? AppBar(
            title: Text(menuTitles[selectedIndex]),
            backgroundColor: Colors.deepPurple,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          )
              : null,
          drawer: isMobile ? _buildDrawer() : null,
          body: isMobile
              ? _buildPage()
              : Row(
            children: [
              _buildSideMenu(),
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
      },
    );
  }

  Widget _buildSideMenu() {
    return Container(
      width: 220,
      color: Colors.deepPurple.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  AssetPath.logo, // Utilisez votre constante de classe
                  height: 60, // Ajustez la hauteur selon vos besoins
                  width: 60,  // Ajustez la largeur selon vos besoins
                ),
                //Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                SizedBox(height: 10),
                Text("Admin",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: ListView(
              children: List.generate(menuTitles.length, (index) {
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
            ),
          ),
          // Bouton de déconnexion en bas
          Container(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.white),
              ),
              onTap: _handleLogout,
              hoverColor: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            padding: EdgeInsets.all(16), // Réduire le padding par défaut
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Centrer verticalement
              children: [
                Expanded( // Permet au logo de prendre plus d'espace
                  child: Image.asset(
                    AssetPath.logo,
                    height: double.infinity, // Prend toute la hauteur disponible
                    width: double.infinity,  // Prend toute la largeur disponible
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 10),
                // Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                Text(
                  "Admin Panel",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: ListView(
              children: List.generate(menuTitles.length, (index) {
                return ListTile(
                  leading: Icon(menuIcons[index], color: Colors.deepPurple),
                  title: Text(menuTitles[index]),
                  selected: selectedIndex == index,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                    Navigator.pop(context); // Fermer le drawer après sélection
                  },
                );
              }),
            ),
          ),
          // Bouton de déconnexion en bas du drawer
          Container(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer d'abord
                _handleLogout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (selectedIndex) {
      case 0:
        return AdminDashboardPage();
      case 1:
        return AdminClients();
      case 2:
        return AdminCategories();
      case 3:
        return AdminServices();
      case 4:
        return ProjetsPage();
      case 5:
        return StatistiquesPage();
      default:
        return Center(child: Text("Sélectionnez une section"));
    }
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_delivery/app/users/client/client_drawer.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  String selectedCategory = 'Toutes';
  String searchQuery = '';

  List<String> categories = ['Toutes'];
  User? currentUser;
  String userRole = '';

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _loadCategories();
    _loadUserRole();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    final fetched = snapshot.docs.map((doc) => doc['nom'] as String).toList();
    setState(() {
      categories = ['Toutes', ...fetched];
    });
  }

  Future<void> _loadUserRole() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance.collection('utilisateurs').doc(currentUser!.uid).get();
      setState(() {
        userRole = doc['role'] ?? '';
      });
    }
  }

  Future<Map<String, String>> _getCategorieNamesMap() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    return {
      for (var doc in snapshot.docs) doc.id: doc['nom'] as String,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accueil Client"),
        backgroundColor: Colors.deepPurple.shade200,
      ),
      drawer: ClientDrawer(),
      body: Column(
        children: [
          buildSearchBar(),
          buildCategoryFilter(),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return FutureBuilder<Map<String, String>>(
                  future: _getCategorieNamesMap(),
                  builder: (context, catSnapshot) {
                    if (!catSnapshot.hasData) return CircularProgressIndicator();
                    final catMap = catSnapshot.data!;
                    final services = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'titre': data['titre'] ?? '',
                        'description': data['description'] ?? '',
                        'categorie': catMap[data['categorieId']] ?? 'Inconnue',
                        'note': data['note']?.toString() ?? '4.5',
                        'image': data['image'] ?? '',
                      };
                    }).where((s) {
                      final matchCategory = selectedCategory == 'Toutes' || s['categorie'] == selectedCategory;
                      final matchSearch = searchQuery.isEmpty || s['titre']!.toLowerCase().contains(searchQuery.toLowerCase());
                      return matchCategory && matchSearch;
                    }).toList();

                    if (services.isEmpty) {
                      return Center(child: Text("Aucun service trouvé."));
                    }

                    return ListView(
                      children: services.map((s) => buildServiceCard(s)).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: "Rechercher un service",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(cat),
              selected: selectedCategory == cat,
              onSelected: (_) => setState(() => selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: service['image']!.toString().startsWith('http')
            ? Image.network(service['image']!, width: 60, height: 60, fit: BoxFit.cover)
            : Icon(Icons.image, size: 60),
        title: Text(service['titre'] ?? ''),
        subtitle: Text(service['description'] ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            Text(service['note'] ?? '4.5'),
          ],
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service['titre'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(service['description'] ?? ''),
                    SizedBox(height: 10),
                    Text("Catégorie : ${service['categorie'] ?? ''}"),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text("Note : ${service['note']}/5"),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    Text("Que veux-tu faire ?", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => commanderService(service),
                      icon: Icon(Icons.shopping_cart),
                      label: Text("Commander"),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> commanderService(Map<String, dynamic> service) async {
    try {
      final clientId = FirebaseAuth.instance.currentUser?.uid;
      if (clientId == null) throw Exception("Utilisateur non connecté");

      await FirebaseFirestore.instance.collection('reservations').add({
        'clientId': clientId,
        'serviceId': service['id'],
        'dateCommande': Timestamp.now(),
        'statut': 'EN_ATTENTE',
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Commande envoyée avec succès.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la commande : ${e.toString()}")),
      );
    }
  }
}

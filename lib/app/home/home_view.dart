import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_delivery/app/auth/sign_up.dart';
import 'package:service_delivery/app/auth/view/Login_page.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String selectedCategory = 'Toutes';
  String searchQuery = '';

  List<String> categories = ['Toutes'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    final fetched = snapshot.docs.map((doc) => doc['nom'] as String).toList();
    setState(() {
      categories = ['Toutes', ...fetched];
    });
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
        title: Text("Bienvenue"),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUp())),
            child: Text("Créer un compte", style: TextStyle(color: Colors.black)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.purple.shade50,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
            child: Text("Connexion", style: TextStyle(color: Colors.black)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.purple.shade50,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(width: 12),
        ],
        backgroundColor: Colors.deepPurple.shade100,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple.shade100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person, size: 40, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Bienvenue", style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text("Veuillez vous connecter", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(leading: Icon(Icons.person), title: Text('Mon profil'), onTap: () => Navigator.pop(context)),
            Divider(),
            ListTile(leading: Icon(Icons.business_center), title: Text('Mon espace'), onTap: () => Navigator.pop(context)),
            Divider(),
            ListTile(
                leading: Icon(Icons.login),
                title: Text('Connexion'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()))),
            Divider(),
            ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Créer un compte'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUp()))),
            Divider(),
            ListTile(leading: Icon(Icons.logout), title: Text('Déconnexion'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildBanner(),
            buildSearchBar(),
            buildCategoryFilter(),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Services disponibles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                return FutureBuilder<Map<String, String>>(
                  future: _getCategorieNamesMap(),
                  builder: (context, catSnapshot) {
                    if (!catSnapshot.hasData) return CircularProgressIndicator();

                    final catMap = catSnapshot.data!;
                    final services = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final titre = data['titre']?.toString() ?? '';
                      final description = data['description']?.toString() ?? '';
                      final categorieId = data['categorieId'];
                      final note = data['note'] ?? 4.5;
                      final imageUrl = data['image']?.toString() ?? '';
                      final categoryName = categorieId != null
                          ? (catMap[categorieId] ?? 'Inconnue')
                          : 'Non définie';

                      return {
                        'title': titre,
                        'description': description,
                        'category': categoryName,
                        'rating': note,
                        'imageUrl': imageUrl,
                      };
                    }).where((service) {
                      final matchCategory = selectedCategory == 'Toutes' || service['category'] == selectedCategory;
                      final matchSearch = searchQuery.isEmpty ||
                          service['title'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                      return matchCategory && matchSearch;
                    }).toList();

                    if (services.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("Aucun service trouvé pour cette recherche ou catégorie."),
                      );
                    }

                    return Column(
                      children: services.map((s) => buildServiceCard(s)).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      color: Colors.deepPurple.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Explorez nos services professionnels",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Recherchez, comparez, lisez les avis et découvrez les meilleures offres disponibles.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
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
              onSelected: (_) {
                setState(() {
                  selectedCategory = cat;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: service["imageUrl"] != null && service["imageUrl"].toString().startsWith('http')
              ? Image.network(service["imageUrl"], width: 60, height: 60, fit: BoxFit.cover)
              : Icon(Icons.image, size: 60),
        ),
        title: Text(service["title"] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(service["description"] ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            Text(service["rating"]?.toString() ?? 'N/A'),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service["title"] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(service["description"] ?? ''),
                                SizedBox(height: 10),
                                Text("Catégorie : ${service["category"] ?? 'N/A'}"),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 20),
                                    SizedBox(width: 4),
                                    Text("Note : ${service["rating"] ?? 'N/A'}/5"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: service["imageUrl"] != null && service["imageUrl"].toString().startsWith('http')
                              ? Image.network(service["imageUrl"], width: 200, height: 200, fit: BoxFit.cover)
                              : Icon(Icons.broken_image, size: 100),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    Text("Que veut-tu faire ?", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showAuthDialog(context, "contacter ce prestataire"),
                      icon: Icon(Icons.message),
                      label: Text("Contacter le prestataire"),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showAuthDialog(context, "commander ce service"),
                      icon: Icon(Icons.shopping_cart),
                      label: Text("Commander"),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showAuthDialog(context, "évaluer ce service"),
                      icon: Icon(Icons.rate_review),
                      label: Text("Évaluer ce service"),
                      style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAuthDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Connexion requise"),
        content: Text("Veuillez vous connecter pour $action."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUp()));
            },
            child: Text("Créer un compte"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: Text("Connexion"),
          ),
        ],
      ),
    );
  }
}

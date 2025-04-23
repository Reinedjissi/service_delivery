import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCategories extends StatefulWidget {
  const AdminCategories({super.key});

  @override
  State<AdminCategories> createState() => _AdminCategoriesState();
}

class _AdminCategoriesState extends State<AdminCategories> {
  final CollectionReference categoriesRef =
  FirebaseFirestore.instance.collection('categories');

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Gestion des catégories",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: Icon(Icons.add),
              label: Text("Ajouter une catégorie"),
            ),
          ],
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher une catégorie...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
        ),
        SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: categoriesRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              final filtered = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nom = data['nom']?.toString().toLowerCase() ?? '';
                final desc = data['description']?.toString().toLowerCase() ?? '';
                return nom.contains(searchQuery) || desc.contains(searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(data['nom'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _showCategoryDialog(docId: doc.id, existingData: data),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(doc.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCategory(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Supprimer la catégorie"),
        content: Text("Êtes-vous sûr de vouloir supprimer cette catégorie ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await categoriesRef.doc(id).delete();
            },
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryDialog({String? docId, Map<String, dynamic>? existingData}) async {
    final _nom = TextEditingController(text: existingData?['nom']);
    final _description = TextEditingController(text: existingData?['description']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? "Ajouter une catégorie" : "Modifier la catégorie"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nom, decoration: InputDecoration(labelText: "Nom")),
              SizedBox(height: 10),
              TextField(
                controller: _description,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final categoryData = {
                'nom': _nom.text,
                'description': _description.text,
              };

              if (docId == null) {
                await categoriesRef.add(categoryData);
              } else {
                await categoriesRef.doc(docId).update(categoryData);
              }

              Navigator.pop(context);
            },
            child: Text(docId == null ? "Ajouter" : "Enregistrer"),
          ),
        ],
      ),
    );
  }
}


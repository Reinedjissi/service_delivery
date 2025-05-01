import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminServices extends StatefulWidget {
  const AdminServices({super.key});

  @override
  State<AdminServices> createState() => _AdminServicesState();
}

class _AdminServicesState extends State<AdminServices> {
  final CollectionReference servicesRef = FirebaseFirestore.instance.collection('services');
  String searchQuery = '';
  String sortOption = 'A-Z';
  String? selectedCategoryFilter;

  Map<String, String> categorieNomMap = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    final map = <String, String>{};
    for (var doc in snapshot.docs) {
      map[doc.id] = doc['nom'];
    }
    setState(() {
      categorieNomMap = map;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Gestion des services", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showServiceDialog,
                    icon: Icon(Icons.add),
                    label: Text("Ajouter"),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text("Gestion des services",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showServiceDialog,
                    icon: Icon(Icons.add),
                    label: Text("Ajouter un service"),
                  ),
                ],
              ),
            SizedBox(height: 10),
            _buildSearchField(),
            SizedBox(height: 10),
            _buildFilters(),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: servicesRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  final filtered = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final titre = data['titre']?.toString().toLowerCase() ?? '';
                    final desc = data['description']?.toString().toLowerCase() ?? '';
                    final categoryMatch = selectedCategoryFilter == null ||
                        data['categorieId'] == selectedCategoryFilter;

                    return (titre.contains(searchQuery) || desc.contains(searchQuery)) && categoryMatch;
                  }).toList();

                  filtered.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    switch (sortOption) {
                      case 'A-Z':
                        return dataA['titre'].compareTo(dataB['titre']);
                      case 'Z-A':
                        return dataB['titre'].compareTo(dataA['titre']);
                      case 'Prix croissant':
                        return (dataA['prix'] ?? 0).compareTo(dataB['prix'] ?? 0);
                      case 'Prix décroissant':
                        return (dataB['prix'] ?? 0).compareTo(dataA['prix'] ?? 0);
                      default:
                        return 0;
                    }
                  });

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final imageUrl = data['image']?.toString() ?? '';
                      final categorieNom = categorieNomMap[data['categorieId']] ?? 'Catégorie inconnue';

                      return Card(
                        child: ListTile(
                          leading: imageUrl.startsWith('http')
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl,
                                width: 60, height: 60, fit: BoxFit.cover),
                          )
                              : Icon(Icons.image, size: 60),
                          title: Text(data['titre'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['description'] ?? '',
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 4),
                              Text("Prix : ${data['prix']} FCFA | Durée : ${data['duree']}"),
                              Text("Catégorie : $categorieNom", style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () =>
                                    _showServiceDialog(docId: doc.id, existingData: data),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteService(doc.id),
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
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un service...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: sortOption,
            onChanged: (val) => setState(() => sortOption = val!),
            items: [
              'A-Z',
              'Z-A',
              'Prix croissant',
              'Prix décroissant',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: DropdownButton<String?>(
            value: selectedCategoryFilter,
            hint: Text("Filtrer par catégorie"),
            isExpanded: true,
            onChanged: (val) => setState(() => selectedCategoryFilter = val),
            items: [
              const DropdownMenuItem(value: null, child: Text("Toutes les catégories")),
              ...categorieNomMap.entries.map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value))),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteService(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Supprimer le service"),
        content: Text("Êtes-vous sûr de vouloir supprimer ce service ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await servicesRef.doc(id).delete();
            },
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showServiceDialog({String? docId, Map<String, dynamic>? existingData}) async {
    final _titre = TextEditingController(text: existingData?['titre']);
    String? selectedCategorieId = existingData?['categorieId'];
    final _description = TextEditingController(text: existingData?['description']);
    final _prix = TextEditingController(text: existingData?['prix']?.toString());
    final _duree = TextEditingController(text: existingData?['duree']);
    final _image = TextEditingController(text: existingData?['image']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? "Ajouter un service" : "Modifier le service"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titre, decoration: InputDecoration(labelText: "Titre")),
              SizedBox(height: 10),
              TextField(
                controller: _description,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('categories').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final categories = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: selectedCategorieId,
                    items: categories.map((cat) {
                      final id = cat.id;
                      final nom = cat['nom'];
                      return DropdownMenuItem(value: id, child: Text(nom));
                    }).toList(),
                    onChanged: (val) => selectedCategorieId = val,
                    decoration: InputDecoration(labelText: "Catégorie"),
                    validator: (val) => val == null ? "Veuillez choisir une catégorie" : null,
                  );
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: _prix,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Prix (FCFA)"),
              ),
              SizedBox(height: 10),
              TextField(controller: _duree, decoration: InputDecoration(labelText: "Durée")),
              SizedBox(height: 10),
              TextField(
                controller: _image,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Image (upload depuis galerie)",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.image),
                    onPressed: () => _pickAndUploadImage(_image),
                  ),
                ),
              ),
              if (_image.text.isNotEmpty && _image.text.startsWith('http'))
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.network(_image.text, height: 100),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final serviceData = {
                'titre': _titre.text,
                'description': _description.text,
                'prix': double.tryParse(_prix.text) ?? 0,
                'duree': _duree.text,
                'image': _image.text,
                'categorieId': selectedCategorieId,
                'utilisateurId': 'admin_demo',
              };

              if (docId == null) {
                await servicesRef.add(serviceData);
              } else {
                await servicesRef.doc(docId).update(serviceData);
              }

              Navigator.pop(context);
            },
            child: Text(docId == null ? "Ajouter" : "Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('services/$fileName.jpg');

      final uploadTask = await ref.putData(bytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      setState(() {
        controller.text = downloadUrl;
      });
    }
  }
}

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
  final CollectionReference categoriesRef = FirebaseFirestore.instance.collection('categories');

  String searchQuery = '';
  String sortOption = 'A-Z';
  String? selectedCategoryFilter;
  bool isLoading = false;
  bool isUploadingImage = false;

  Map<String, String> categorieNomMap = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await categoriesRef.get();
      final map = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        map[doc.id] = data['nom'] ?? 'Sans nom';
      }
      if (mounted) {
        setState(() {
          categorieNomMap = map;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors du chargement des catégories: $e"),
            backgroundColor: Colors.orange[200]!,
          ),
        );
      }
    }
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
            _buildHeader(isMobile),
            const SizedBox(height: 10),
            _buildSearchField(),
            const SizedBox(height: 10),
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildServicesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestion des services",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _showServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text("Ajouter"),
            style: ElevatedButton.styleFrom(
             // backgroundColor: Colors.green[200]!,
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          const Expanded(
            child: Text(
              "Gestion des services",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _showServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text("Ajouter un service"),
            style: ElevatedButton.styleFrom(
              //backgroundColor: Colors.deepPurple[200],
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un service...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green.shade100, width: 2),
        ),
      ),
      onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: sortOption,
              onChanged: (val) => setState(() => sortOption = val!),
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                'A-Z',
                'Z-A',
                'Prix croissant',
                'Prix décroissant',
              ].map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String?>(
              value: selectedCategoryFilter,
              hint: const Text("Filtrer par catégorie"),
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (val) => setState(() => selectedCategoryFilter = val),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("Toutes les catégories"),
                ),
                ...categorieNomMap.entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: servicesRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Erreur de chargement: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Réessayer"),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.miscellaneous_services, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Aucun service disponible.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  "Ajoutez votre premier service !",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final titre = data['titre']?.toString().toLowerCase() ?? '';
          final desc = data['description']?.toString().toLowerCase() ?? '';
          final categoryMatch = selectedCategoryFilter == null ||
              data['categorieId'] == selectedCategoryFilter;

          return (titre.contains(searchQuery) || desc.contains(searchQuery)) && categoryMatch;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Aucun service trouvé.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Tri des résultats
        filtered.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          switch (sortOption) {
            case 'A-Z':
              return (dataA['titre'] ?? '').toString().compareTo((dataB['titre'] ?? '').toString());
            case 'Z-A':
              return (dataB['titre'] ?? '').toString().compareTo((dataA['titre'] ?? '').toString());
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
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 2,
              child: ListTile(
                leading: _buildServiceImage(imageUrl),
                title: Text(
                  data['titre'] ?? 'Sans titre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['description'] ?? 'Pas de description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Prix : ${data['prix'] ?? 0} FCFA | Durée : ${data['duree'] ?? 'Non spécifiée'}",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Catégorie : $categorieNom",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: isLoading ? null : () => _showServiceDialog(
                        docId: doc.id,
                        existingData: data,
                      ),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: isLoading ? null : () => _deleteService(
                        doc.id,
                        data['titre'] ?? 'Service sans nom',
                      ),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServiceImage(String imageUrl) {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image,
          size: 30,
          color: Colors.grey.shade500,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image,
            size: 30,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteService(String id, String serviceName) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le service"),
        content: Text("Êtes-vous sûr de vouloir supprimer le service \"$serviceName\" ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      setState(() => isLoading = true);
      try {
        await servicesRef.doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Service \"$serviceName\" supprimé avec succès"),
              backgroundColor: Colors.green[200]!,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur lors de la suppression: $e"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<void> _showServiceDialog({String? docId, Map<String, dynamic>? existingData}) async {
    final titreController = TextEditingController(text: existingData?['titre'] ?? '');
    final descriptionController = TextEditingController(text: existingData?['description'] ?? '');
    final prixController = TextEditingController(text: existingData?['prix']?.toString() ?? '');
    final dureeController = TextEditingController(text: existingData?['duree'] ?? '');
    final imageController = TextEditingController(text: existingData?['image'] ?? '');

    String? selectedCategorieId = existingData?['categorieId'];
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? "Ajouter un service" : "Modifier le service"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titreController,
                    decoration: const InputDecoration(
                      labelText: "Titre *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre est obligatoire';
                      }
                      if (value.trim().length < 3) {
                        return 'Le titre doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La description est obligatoire';
                      }
                      if (value.trim().length < 10) {
                        return 'La description doit contenir au moins 10 caractères';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<QuerySnapshot>(
                    future: categoriesRef.get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Text(
                            "Aucune catégorie disponible. Veuillez d'abord créer des catégories.",
                            style: TextStyle(color: Colors.orange),
                          ),
                        );
                      }

                      final categories = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedCategorieId,
                        decoration: const InputDecoration(
                          labelText: "Catégorie *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories.map((cat) {
                          final data = cat.data() as Map<String, dynamic>;
                          final id = cat.id;
                          final nom = data['nom'] ?? 'Sans nom';
                          return DropdownMenuItem(value: id, child: Text(nom));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedCategorieId = val),
                        validator: (val) => val == null ? "Veuillez choisir une catégorie" : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: prixController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Prix (FCFA) *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prix est obligatoire';
                      }
                      final prix = double.tryParse(value);
                      if (prix == null || prix < 0) {
                        return 'Veuillez entrer un prix valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dureeController,
                    decoration: const InputDecoration(
                      labelText: "Durée *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                      hintText: "Ex: 1h30, 2 heures, 30 min",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La durée est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: imageController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Image",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.image),
                      suffixIcon: IconButton(
                        icon: isUploadingImage
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.photo_library),
                        onPressed: isUploadingImage ? null : () => _pickAndUploadImage(imageController, setDialogState),
                      ),
                    ),
                  ),
                  if (imageController.text.isNotEmpty && imageController.text.startsWith('http'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageController.text,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _saveService(
                    docId: docId,
                    titre: titreController.text.trim(),
                    description: descriptionController.text.trim(),
                    prix: double.parse(prixController.text.trim()),
                    duree: dureeController.text.trim(),
                    image: imageController.text.trim(),
                    categorieId: selectedCategorieId!,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                //backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.deepPurple,
              ),
              child: Text(docId == null ? "Ajouter" : "Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveService({
    String? docId,
    required String titre,
    required String description,
    required double prix,
    required String duree,
    required String image,
    required String categorieId,
  }) async {
    setState(() => isLoading = true);

    try {
      final serviceData = {
        'titre': titre,
        'description': description,
        'prix': prix,
        'duree': duree,
        'image': image,
        'categorieId': categorieId,
        'utilisateurId': 'admin_demo',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        // Ajout d'un nouveau service
        serviceData['createdAt'] = FieldValue.serverTimestamp();
        await servicesRef.add(serviceData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Service \"$titre\" ajouté avec succès"),
              backgroundColor: Colors.green[200]!,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Modification d'un service existant
        await servicesRef.doc(docId).update(serviceData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Service \"$titre\" modifié avec succès"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'enregistrement: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage(TextEditingController controller, StateSetter setDialogState) async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setDialogState(() => isUploadingImage = true);

        final bytes = await pickedFile.readAsBytes();
        final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('services/$fileName');

        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        setDialogState(() {
          controller.text = downloadUrl;
          isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image uploadée avec succès"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setDialogState(() => isUploadingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'upload: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
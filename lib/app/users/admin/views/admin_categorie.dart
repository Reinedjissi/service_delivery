import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCategories extends StatefulWidget {
  static var routeName = '/ AdminCategories';

  const AdminCategories({super.key});

  @override
  State<AdminCategories> createState() => _AdminCategoriesState();
}

class _AdminCategoriesState extends State<AdminCategories> {
  final CollectionReference categoriesRef = FirebaseFirestore.instance.collection('categories');
  String searchQuery = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 10),
              _buildSearchField(),
              const SizedBox(height: 10),
              Expanded(
                child: _buildCategoriesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*const Text(
            //"Gestion des catégories",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),*/
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _showCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text("Ajouter"),
            style: ElevatedButton.styleFrom(
            //  backgroundColor: Colors.deepPurpleAccent[200],
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
              "Gestion des catégories",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _showCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text("Ajouter une catégorie"),
            style: ElevatedButton.styleFrom(
             // backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ],
      );
    }
  }


  Widget _buildSearchField() {
    return Material(
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une catégorie...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
          ),
        ),
        onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: categoriesRef.orderBy('nom').snapshots(),
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
                Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Aucune catégorie disponible.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  "Ajoutez votre première catégorie !",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nom = data['nom']?.toString().toLowerCase() ?? '';
          final desc = data['description']?.toString().toLowerCase() ?? '';
          return nom.contains(searchQuery) || desc.contains(searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  "Aucune catégorie trouvée.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (data['nom'] ?? '').toString().isNotEmpty
                        ? data['nom'].toString()[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.deepPurple.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  data['nom'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: isLoading ? null : () => _showCategoryDialog(
                        docId: doc.id,
                        existingData: data,
                      ),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: isLoading ? null : () => _deleteCategory(doc.id, data['nom'] ?? ''),
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

  Future<void> _deleteCategory(String id, String categoryName) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer la catégorie"),
        content: Text("Êtes-vous sûr de vouloir supprimer la catégorie \"$categoryName\" ?"),
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
        await categoriesRef.doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Catégorie \"$categoryName\" supprimée avec succès"),
              backgroundColor: Colors.green,
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

  Future<void> _showCategoryDialog({String? docId, Map<String, dynamic>? existingData}) async {
    final nomController = TextEditingController(text: existingData?['nom'] ?? '');
    final descriptionController = TextEditingController(text: existingData?['description'] ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? "Ajouter une catégorie" : "Modifier la catégorie"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: "Nom *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    if (value.trim().length < 2) {
                      return 'Le nom doit contenir au moins 2 caractères';
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
                    if (value.trim().length < 5) {
                      return 'La description doit contenir au moins 5 caractères';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
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
                await _saveCategory(
                  docId: docId,
                  nom: nomController.text.trim(),
                  description: descriptionController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
            //  backgroundColor: Colors.blue,
              foregroundColor: Colors.deepPurple,
            ),
            child: Text(docId == null ? "Ajouter" : "Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory({String? docId, required String nom, required String description}) async {
    setState(() => isLoading = true);

    try {
      final categoryData = {
        'nom': nom,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        // Ajout d'une nouvelle catégorie
        categoryData['createdAt'] = FieldValue.serverTimestamp();
        await categoriesRef.add(categoryData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Catégorie \"$nom\" ajoutée avec succès"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Modification d'une catégorie existante
        await categoriesRef.doc(docId).update(categoryData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Catégorie \"$nom\" modifiée avec succès"),
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
}
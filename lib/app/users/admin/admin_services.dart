import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
//import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text("Gestion des services", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddServiceDialog(),
              icon: Icon(Icons.add),
              label: Text("Ajouter un service"),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un service...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              ),
            ),
            SizedBox(width: 10),
            DropdownButton<String>(
              value: sortOption,
              items: ['A-Z', 'Z-A', 'Prix croissant', 'Prix décroissant']
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) => setState(() => sortOption = val!),
            ),
          ],
        ),
        SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: servicesRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              var docs = snapshot.data!.docs;

              var filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final titre = data['titre']?.toString().toLowerCase() ?? '';
                final desc = data['description']?.toString().toLowerCase() ?? '';
                return titre.contains(searchQuery) || desc.contains(searchQuery);
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
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: data['image'] != null && data['image'].toString().startsWith('http')
                            ? Image.network(data['image'], width: 60, height: 60, fit: BoxFit.cover)
                            : Icon(Icons.image, size: 60),
                      ),
                      title: Text(data['titre'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4),
                          Text("Prix : ${data['prix']} FCFA | Durée : ${data['duree']}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: () => _showEditServiceDialog(doc.id, data), icon: Icon(Icons.edit)),
                          IconButton(
                            onPressed: () => _deleteService(doc.id),
                            icon: Icon(Icons.delete, color: Colors.red),
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

  Future<void> _deleteService(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment supprimer ce service ?"),
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

  Future<void> _showAddServiceDialog() async {
    await showDialog(
      context: context,
      builder: (_) => ServiceFormDialog(onSubmit: (serviceData) async {
        await servicesRef.add(serviceData);
        Navigator.pop(context);
      }),
    );
  }
Future<void> _showEditServiceDialog(String docId, Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (_) => ServiceFormDialog(
        existingData: data,
        onSubmit: (updatedData) async {
          await servicesRef.doc(docId).update(updatedData);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class ServiceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final Function(Map<String, dynamic>) onSubmit;

  const ServiceFormDialog({super.key, this.existingData, required this.onSubmit});

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titre = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _prix = TextEditingController();
  final TextEditingController _duree = TextEditingController();
  final TextEditingController _image = TextEditingController();

  String? selectedCategorieId;
  final CollectionReference categoriesRef = FirebaseFirestore.instance.collection('categories');

  Uint8List? _pickedImageBytes;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titre.text = widget.existingData!['titre'] ?? '';
      _description.text = widget.existingData!['description'] ?? '';
      _prix.text = widget.existingData!['prix']?.toString() ?? '';
      _duree.text = widget.existingData!['duree'] ?? '';
      _image.text = widget.existingData!['image'] ?? '';
      selectedCategorieId = widget.existingData!['categorieId'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingData == null ? "Ajouter un service" : "Modifier le service"),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_titre, "Titre", icon: Icons.title),
                _buildTextField(_description, "Description", icon: Icons.description),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_prix, "Prix", isNumber: true, icon: Icons.attach_money)),
                    SizedBox(width: 10),
                    Expanded(child: _buildTextField(_duree, "Durée", icon: Icons.schedule)),
                  ],
                ),
                SizedBox(height: 12),
                Text("Image du service", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      if (_pickedImageBytes != null)
                        Image.memory(_pickedImageBytes!, width: 100, height: 100, fit: BoxFit.cover),
                      if (_image.text.isNotEmpty && _pickedImageBytes == null)
                        Image.network(_image.text, width: 100, height: 100, fit: BoxFit.cover),
                      TextButton.icon(
                        icon: Icon(Icons.image),
                        label: Text("Choisir une image"),
                        onPressed: _pickAndUploadImage,
                      ),
                      if (_uploading) CircularProgressIndicator(),

                    ],

                  ),
                ),
                SizedBox(height: 16),
                Text("Catégorie", style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<QuerySnapshot>(
                  future: categoriesRef.get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final categories = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedCategorieId,
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat['nom']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedCategorieId = value),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null ? "Choisissez une catégorie" : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
        ElevatedButton.icon(
          icon: Icon(widget.existingData == null ? Icons.add : Icons.save),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final serviceData = {
                'titre': _titre.text,
                'description': _description.text,
                'prix': double.tryParse(_prix.text) ?? 0,
                'duree': _duree.text,
                'image': _image.text,
                'categorieId': selectedCategorieId,
                'utilisateurId': 'admin_demo',
              };
              widget.onSubmit(serviceData);
            }
          },
          label: Text(widget.existingData == null ? "Ajouter" : "Enregistrer"),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _uploading = true);
    try {
      Uint8List? imageBytes;
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      if (kIsWeb) {
       //final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
       //if (result != null && result.files.single.bytes != null) {
       //  imageBytes = result.files.single.bytes;
       //}
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          imageBytes = await picked.readAsBytes();
        }
      }

      if (imageBytes != null) {
        final ref = FirebaseStorage.instance.ref().child('services/$fileName.jpg');
        final uploadTask = await ref.putData(imageBytes);
        final url = await uploadTask.ref.getDownloadURL();

        setState(() {
          _pickedImageBytes = imageBytes;
          _image.text = url;
          _uploading = false;
        });
      } else {
        setState(() => _uploading = false);
      }
    } catch (e) {
      print("Erreur lors de l'upload de l'image : $e");
      setState(() => _uploading = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

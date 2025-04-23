import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final CollectionReference usersRef =
  FirebaseFirestore.instance.collection('utilisateurs');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String searchQuery = '';
  String roleFilter = 'TOUS';
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Gestion des utilisateurs",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showUserFormDialog(),
              icon: Icon(Icons.person_add),
              label: Text("Ajouter un utilisateur"),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou email...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) =>
                    setState(() => searchQuery = val.toLowerCase()),
              ),
            ),
            SizedBox(width: 10),
            DropdownButton<String>(
              value: roleFilter,
              items: ['TOUS', 'CLIENT', 'PRESTATAIRE', 'ADMIN']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => roleFilter = val!),
            ),
          ],
        ),
        SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: usersRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final filtered = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name =
                    data['nom']?.toString().toLowerCase() ?? '';
                final email =
                    data['email']?.toString().toLowerCase() ?? '';
                final role = data['role']?.toString() ?? '';
                final matchesSearch =
                    name.contains(searchQuery) || email.contains(searchQuery);
                final matchesRole =
                    roleFilter == 'TOUS' || role == roleFilter;
                return matchesSearch && matchesRole;
              }).toList();

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: ListTile(
                      title: Text(data['nom'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                      Text("${data['email']} - Rôle : ${data['role']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (data['aDemandeRolePrestataire'] == true &&
                              data['role'] == 'CLIENT')
                            IconButton(
                              icon: Icon(Icons.verified_user,
                                  color: Colors.green),
                              tooltip: "Valider comme prestataire",
                              onPressed: () => _validerDemande(doc.id),
                            ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showUserFormDialog(
                                docId: doc.id, existingData: data),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(doc.id),
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

  Future<void> _validerDemande(String userId) async {
    await usersRef.doc(userId).update({
      'role': 'PRESTATAIRE',
      'aDemandeRolePrestataire': false,
    });
  }

  Future<void> _deleteUser(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Supprimer l'utilisateur"),
        content: Text("Êtes-vous sûr de vouloir supprimer cet utilisateur ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await usersRef.doc(id).delete();
            },
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserFormDialog(
      {String? docId, Map<String, dynamic>? existingData}) async {
    final _nom = TextEditingController(text: existingData?['nom']);
    final _email = TextEditingController(text: existingData?['email']);
    final _motDePasse = TextEditingController();
    String role = existingData?['role'] ?? 'CLIENT';
    bool aDemande = existingData?['aDemandeRolePrestataire'] ?? false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(docId == null
                ? "Ajouter un utilisateur"
                : "Modifier l'utilisateur"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: _nom,
                      decoration: InputDecoration(labelText: "Nom")),
                  SizedBox(height: 8),
                  TextField(
                      controller: _email,
                      decoration: InputDecoration(labelText: "Email")),
                  SizedBox(height: 8),
                  if (docId == null)
                    TextField(
                      controller: _motDePasse,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: ['CLIENT', 'PRESTATAIRE', 'ADMIN']
                        .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => role = val!,
                    decoration: InputDecoration(labelText: "Rôle"),
                  ),
                  SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text("Demande de rôle prestataire"),
                    value: aDemande,
                    onChanged: (val) =>
                        setStateDialog(() => aDemande = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annuler")),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (docId == null) {
                      if (_motDePasse.text.trim().length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Le mot de passe doit contenir au moins 6 caractères."),
                          ),
                        );
                        return;
                      }

                      final userCredential =
                      await _auth.createUserWithEmailAndPassword(
                        email: _email.text.trim(),
                        password: _motDePasse.text.trim(),
                      );

                      await usersRef.doc(userCredential.user!.uid).set({
                        'nom': _nom.text,
                        'email': _email.text,
                        'role': role,
                        'aDemandeRolePrestataire': aDemande,
                      });
                    } else {
                      await usersRef.doc(docId).update({
                        'nom': _nom.text,
                        'email': _email.text,
                        'role': role,
                        'aDemandeRolePrestataire': aDemande,
                      });
                    }

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur : ${e.toString()}")),
                    );
                  }
                },
                child: Text(docId == null ? "Ajouter" : "Enregistrer"),
              ),
            ],
          );
        },
      ),
    );
  }
}

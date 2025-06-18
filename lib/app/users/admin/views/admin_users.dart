import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminClients extends StatefulWidget {
  const AdminClients({super.key});

  @override
  State<AdminClients> createState() => _AdminClientsState();
}

class _AdminClientsState extends State<AdminClients> {
  final CollectionReference clientsRef = FirebaseFirestore.instance.collection('clients');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String searchQuery = '';
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Gestion des clients",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showClientFormDialog,
                      icon: Icon(Icons.person_add),
                      label: Text("Ajouter"),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _testFirestoreConnection,
                      icon: Icon(Icons.refresh),
                      label: Text("Actualiser"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[100]),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Gestion des clients",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showClientFormDialog,
                  icon: Icon(Icons.person_add),
                  label: Text("Ajouter un client"),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _testFirestoreConnection,
                  icon: Icon(Icons.refresh),
                  label: Text("Actualiser"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[100]),
                ),
              ],
            ),
          SizedBox(height: 12),
          _buildSearchField(),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: clientsRef.snapshots(),
              builder: (context, snapshot) {
                // Gestion des erreurs
                if (snapshot.hasError) {
                  print("Erreur StreamBuilder: ${snapshot.error}");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          "Erreur de connexion",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Impossible de charger les clients",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text("Réessayer"),
                        ),
                      ],
                    ),
                  );
                }

                // Chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Chargement des clients..."),
                      ],
                    ),
                  );
                }

                // Vérifier si des données existent
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Aucune donnée disponible",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "La collection clients semble vide",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                print("Nombre total de documents: ${docs.length}");

                // Aucun document trouvé
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Aucun client enregistré",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Commencez par ajouter votre premier client",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showClientFormDialog,
                          icon: Icon(Icons.person_add),
                          label: Text("Ajouter un client"),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrage des clients
                final filtered = docs.where((doc) {
                  try {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null) return false;

                    final nom = data['nom']?.toString().toLowerCase() ?? '';
                    final prenom = data['prenom']?.toString().toLowerCase() ?? '';
                    final email = data['email']?.toString().toLowerCase() ?? '';
                    final telephone = data['telephone']?.toString().toLowerCase() ?? '';

                    final matchesSearch = searchQuery.isEmpty ||
                        nom.contains(searchQuery) ||
                        prenom.contains(searchQuery) ||
                        email.contains(searchQuery) ||
                        telephone.contains(searchQuery);

                    return matchesSearch;
                  } catch (e) {
                    print("Erreur lors du filtrage du document ${doc.id}: $e");
                    return false;
                  }
                }).toList();

                print("Nombre de clients après filtrage: ${filtered.length}");

                // Aucun résultat de recherche
                if (filtered.isEmpty && searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Aucun résultat trouvé",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Aucun client ne correspond à \"$searchQuery\"",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Affichage de la liste des clients
                return Column(
                  children: [
                    // Compteur de clients
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${filtered.length} client${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}",
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final doc = filtered[index];
                          try {
                            final data = doc.data() as Map<String, dynamic>?;

                            if (data == null) {
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                child: ListTile(
                                  title: Text("Données corrompues"),
                                  subtitle: Text("Document ID: ${doc.id}"),
                                  leading: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            }

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    "${data['prenom']?.toString().substring(0, 1).toUpperCase() ?? '?'}${data['nom']?.toString().substring(0, 1).toUpperCase() ?? '?'}",
                                    style: TextStyle(
                                      color: Colors.deepPurpleAccent[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  "${data['prenom'] ?? 'Prénom'} ${data['nom'] ?? 'Nom'}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data['email'] ?? 'Email non renseigné',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data['telephone'] ?? 'Téléphone non renseigné',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (data['adresse'] != null && data['adresse'].toString().isNotEmpty) ...[
                                      SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              data['adresse'],
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showClientFormDialog(
                                          docId: doc.id, existingData: data),
                                      tooltip: "Modifier",
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteClient(doc.id),
                                      tooltip: "Supprimer",
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } catch (e) {
                            print("Erreur lors de l'affichage du client ${doc.id}: $e");
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: ListTile(
                                title: Text("Erreur d'affichage"),
                                subtitle: Text("Document ID: ${doc.id}"),
                                leading: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher par nom, prénom, email ou téléphone...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
    );
  }

  // Méthode de test pour vérifier la connexion Firestore
  Future<void> _testFirestoreConnection() async {
    try {
      print("Test de connexion Firestore...");

      // Vérifier l'authentification
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Aucun utilisateur connecté");
      }
      print("Utilisateur connecté: ${currentUser.email}");

      // Test 1: Créer un document de test
      final testDoc = clientsRef.doc('client_test_${DateTime.now().millisecondsSinceEpoch}');
      await testDoc.set({
        'nom': 'Test',
        'prenom': 'Client',
        'email': 'test@exemple.com',
        'telephone': '+237 000 000 000',
        'adresse': 'Adresse de test',
        'role': 'CLIENT',
        'dateCreation': FieldValue.serverTimestamp(),
        'estTest': true,
      });

      print("Document de test créé avec succès");

      // Test 2: Lire tous les documents
      final querySnapshot = await clientsRef.get();
      print("Nombre total de clients dans Firestore: ${querySnapshot.docs.length}");

      for (var doc in querySnapshot.docs) {
        print("Client trouvé: ${doc.id} - ${doc.data()}");
      }

      // Test 3: Supprimer le document de test
      await testDoc.delete();
      print("Document de test supprimé");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Connexion Firestore OK - ${querySnapshot.docs.length} clients trouvés"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Erreur de test Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur Firestore: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteClient(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Supprimer le client"),
        content: Text("Êtes-vous sûr de vouloir supprimer ce client ? Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await clientsRef.doc(id).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Client supprimé avec succès"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur lors de la suppression: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showClientFormDialog({String? docId, Map<String, dynamic>? existingData}) async {
    final _nom = TextEditingController(text: existingData?['nom']);
    final _prenom = TextEditingController(text: existingData?['prenom']);
    final _email = TextEditingController(text: existingData?['email']);
    final _telephone = TextEditingController(text: existingData?['telephone']);
    final _adresse = TextEditingController(text: existingData?['adresse']);
    final _motDePasse = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(docId == null ? "Ajouter un client" : "Modifier le client"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [


                  TextField(
                      controller: _nom,
                      decoration: InputDecoration(
                        labelText: "Nom *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      )
                  ),
                  SizedBox(height: 12),
                  TextField(
                      controller: _prenom,
                      decoration: InputDecoration(
                        labelText: "Prénom *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_add_alt),
                      )
                  ),
                  SizedBox(height: 12),
                  TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      )
                  ),
                  SizedBox(height: 12),
                  TextField(
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Téléphone",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      )
                  ),
                  SizedBox(height: 12),
                  TextField(
                      controller: _adresse,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Adresse",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      )
                  ),
                  SizedBox(height: 12),
                  if (docId == null)
                    TextField(
                      controller: _motDePasse,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Mot de passe *",
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Validation des champs obligatoires
                    if (_nom.text.trim().isEmpty || _prenom.text.trim().isEmpty || _email.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Le nom, prénom et email sont obligatoires.")),
                      );
                      return;
                    }

                    if (docId == null) {
                      // Création d'un nouveau client
                      if (_motDePasse.text.trim().length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Le mot de passe doit contenir au moins 6 caractères.")),
                        );
                        return;
                      }

                      final userCredential = await _auth.createUserWithEmailAndPassword(
                        email: _email.text.trim(),
                        password: _motDePasse.text.trim(),
                      );

                      // Créer le document client avec un ID personnalisé
                      final clientDoc = clientsRef.doc(userCredential.user!.uid);
                      await clientDoc.set({
                        'nom': _nom.text.trim(),
                        'prenom': _prenom.text.trim(),
                        'email': _email.text.trim(),
                        'telephone': _telephone.text.trim(),
                        'adresse': _adresse.text.trim(),
                        'role': 'CLIENT',
                        'dateCreation': FieldValue.serverTimestamp(),
                        'uid': userCredential.user!.uid,
                      });

                      print("Client créé avec l'ID: ${userCredential.user!.uid}");
                    } else {
                      // Modification d'un client existant
                      await clientsRef.doc(docId).update({
                        'nom': _nom.text.trim(),
                        'prenom': _prenom.text.trim(),
                        'email': _email.text.trim(),
                        'telephone': _telephone.text.trim(),
                        'adresse': _adresse.text.trim(),
                        'dateModification': FieldValue.serverTimestamp(),
                      });
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(docId == null ? "Client ajouté avec succès" : "Client modifié avec succès"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print("Erreur lors de la création/modification du client: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur : ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
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
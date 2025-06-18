import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminProjets extends StatefulWidget {
  const AdminProjets({super.key});

  @override
  State<AdminProjets> createState() => _AdminProjetsState();
}

class _AdminProjetsState extends State<AdminProjets> {
  final CollectionReference projetsRef = FirebaseFirestore.instance.collection('projets');
  String searchQuery = '';
  String sortOption = 'Date récente';
  String? selectedStatusFilter;
  String? selectedClientFilter;

  Map<String, String> clientNomMap = {};
  Map<String, String> serviceNomMap = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClientsAndServices();
    _initializeFirestoreCollections(); // Nouvelle méthode
  }

  // Initialiser les collections Firestore si elles n'existent pas
  Future<void> _initializeFirestoreCollections() async {
    try {
      // Vérifier si la collection projets existe, sinon créer un document exemple
      final projetsSnapshot = await projetsRef.limit(1).get();
      if (projetsSnapshot.docs.isEmpty) {
        await _createInitialProject();
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    }
  }

  // Créer un projet initial pour initialiser la collection
  Future<void> _createInitialProject() async {
    try {
      final initialProject = {
        'titre': 'Projet de démonstration',
        'description': 'Ceci est un projet de démonstration créé automatiquement pour illustrer le fonctionnement de l\'application.',
        'clientId': 'demo_client',
        'serviceId': 'demo_service',
        'statut': 'Nouveau',
        'commentaires': 'Projet créé automatiquement lors de l\'initialisation',
        'documents': [],
        'dateCreation': Timestamp.now(),
        'dateLivraison': null,
        'dateModification': Timestamp.now(),
        'utilisateurId': 'system',
        'priorite': 'Normale', // Nouveau champ
        'budget': 0.0, // Nouveau champ
        'progression': 0, // Nouveau champ (0-100%)
      };

      await projetsRef.add(initialProject);
      print('Projet initial créé avec succès');
    } catch (e) {
      print('Erreur lors de la création du projet initial: $e');
    }
  }

  Future<void> _loadClientsAndServices() async {
    try {
      setState(() => isLoading = true);

      // Charger les clients avec gestion d'erreur améliorée
      try {
        final clientsSnapshot = await FirebaseFirestore.instance.collection('clients').get();
        final clientsMap = <String, String>{};
        for (var doc in clientsSnapshot.docs) {
          final data = doc.data();
          clientsMap[doc.id] = '${data['nom'] ?? ''} ${data['prenom'] ?? ''}';
        }
        clientNomMap = clientsMap;
      } catch (e) {
        print('Erreur lors du chargement des clients: $e');
        // Créer un client par défaut si la collection n'existe pas
        clientNomMap = {'demo_client': 'Client Démonstration'};
      }

      // Charger les services avec gestion d'erreur améliorée
      try {
        final servicesSnapshot = await FirebaseFirestore.instance.collection('services').get();
        final servicesMap = <String, String>{};
        for (var doc in servicesSnapshot.docs) {
          final data = doc.data();
          servicesMap[doc.id] = data['titre'] ?? 'Service sans titre';
        }
        serviceNomMap = servicesMap;
      } catch (e) {
        print('Erreur lors du chargement des services: $e');
        // Créer un service par défaut si la collection n'existe pas
        serviceNomMap = {'demo_service': 'Service Démonstration'};
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du chargement: $e")),
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
            Expanded(child: _buildProjectsList()),
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
          const Text("Gestion des projets",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showProjetDialog,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter"),
                style: ElevatedButton.styleFrom(
                  //backgroundColor: Colors.deepPurple[200],
                  foregroundColor: Colors.deepPurple,
                ),
              ),
             /* const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _createTestProject,
                icon: const Icon(Icons.science),
                label: const Text("Test"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),*/
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          const Expanded(
            child: Text("Gestion des projets",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          /*ElevatedButton.icon(
            onPressed: _createTestProject,
            icon: const Icon(Icons.science),
            label: const Text("Créer projet test"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),*/
         // ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _showProjetDialog,
            icon: const Icon(Icons.add),
            label: const Text("Ajouter un projet"),
            style: ElevatedButton.styleFrom(
             // backgroundColor: Colors.deepPurple[100],
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildProjectsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: projetsRef.orderBy('dateCreation', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 50, color: Colors.red),
                const SizedBox(height: 10),
                Text("Erreur: ${snapshot.error}"),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Réessayer"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _createInitialProject,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Initialiser la base de données"),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 50, color: Colors.grey),
                const SizedBox(height: 10),
                const Text("Aucun projet trouvé", style: TextStyle(fontSize: 16)),
                const Text("Cliquez sur 'Ajouter' pour créer votre premier projet"),
                const SizedBox(height: 20),
                /*ElevatedButton.icon(
                  onPressed: _createTestProject,
                  icon: const Icon(Icons.science),
                  label: const Text("Créer un projet de test"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),*/
              ],
            ),
          );
        }

        final filtered = _filterAndSortProjects(snapshot.data!.docs);

        return Column(
          children: [
            // Statistiques en haut
            //_buildStatsCard(_getProjectStats(snapshot.data!.docs)),
            const SizedBox(height: 10),
            // Liste des projets
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, index) => _buildProjectCard(filtered[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterAndSortProjects(List<QueryDocumentSnapshot> docs) {
    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final titre = data['titre']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      final statusMatch = selectedStatusFilter == null ||
          data['statut'] == selectedStatusFilter;
      final clientMatch = selectedClientFilter == null ||
          data['clientId'] == selectedClientFilter;

      return (titre.contains(searchQuery) || description.contains(searchQuery)) &&
          statusMatch && clientMatch;
    }).toList();

    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      switch (sortOption) {
        case 'A-Z':
          return (dataA['titre'] ?? '').toString().compareTo((dataB['titre'] ?? '').toString());
        case 'Z-A':
          return (dataB['titre'] ?? '').toString().compareTo((dataA['titre'] ?? '').toString());
        case 'Date récente':
          final dateA = dataA['dateCreation'] as Timestamp?;
          final dateB = dataB['dateCreation'] as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        case 'Date ancienne':
          final dateA = dataA['dateCreation'] as Timestamp?;
          final dateB = dataB['dateCreation'] as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        default:
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildProjectCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final clientNom = clientNomMap[data['clientId']] ?? 'Client inconnu';
    final serviceNom = serviceNomMap[data['serviceId']] ?? 'Service inconnu';
    final statut = data['statut'] ?? 'En cours';
    final dateCreation = data['dateCreation'] as Timestamp?;
    final progression = data['progression'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 2,
      child: ListTile(
        leading: _buildStatusIcon(statut),
        title: Text(data['titre'] ?? 'Projet sans titre',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['description'] ?? 'Aucune description',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text("Client : $clientNom", style: TextStyle(color: Colors.grey[600])),
            Text("Service : $serviceNom", style: TextStyle(color: Colors.grey[600])),
            Text("Statut : $statut | Date : ${_formatDate(dateCreation)}",
                style: TextStyle(color: Colors.grey[600])),
            // Barre de progression
            if (progression > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("Progression: $progression%",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progression / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progression < 30 ? Colors.red :
                        progression < 50 ? Colors.blue :
                        progression < 70 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (data['commentaires'] != null && data['commentaires'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("Commentaires : ${data['commentaires']}",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showProjetDetails(doc.id, data);
                break;
              case 'edit':
                _showProjetDialog(docId: doc.id, existingData: data);
                break;
              case 'delete':
                _deleteProjet(doc.id, data['titre'] ?? 'ce projet');
                break;
              case 'duplicate':
                _duplicateProject(data);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Voir détails'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 20),
                  SizedBox(width: 8),
                  Text('Dupliquer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nouvelle méthode pour dupliquer un projet
  Future<void> _duplicateProject(Map<String, dynamic> originalData) async {
    try {
      final duplicatedData = Map<String, dynamic>.from(originalData);
      duplicatedData['titre'] = '${originalData['titre'] ?? 'Projet'} - Copie';
      duplicatedData['dateCreation'] = Timestamp.now();
      duplicatedData['dateModification'] = Timestamp.now();
      duplicatedData['statut'] = 'Nouveau';
      duplicatedData['progression'] = 0;

      await projetsRef.add(duplicatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Projet dupliqué avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la duplication: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusIcon(String statut) {
    IconData icon;
    Color color;

    switch (statut) {
      case 'Terminé':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'En cours':
        icon = Icons.access_time;
        color = Colors.blue;
        break;
      case 'Suspendu':
        icon = Icons.pause_circle;
        color = Colors.orange;
        break;
      case 'Nouveau':
        icon = Icons.fiber_new;
        color = Colors.purple;
        break;
      default:
        icon = Icons.work;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Non définie';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un projet...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: sortOption,
                decoration: InputDecoration(
                  labelText: 'Trier par',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => setState(() => sortOption = val!),
                items: [
                  'Date récente',
                  'Date ancienne',
                  'A-Z',
                  'Z-A',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: selectedStatusFilter,
                decoration: InputDecoration(
                  labelText: 'Statut',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => setState(() => selectedStatusFilter = val),
                items: [null, 'Nouveau', 'En cours', 'Terminé', 'Suspendu']
                    .map((statut) => DropdownMenuItem(
                    value: statut,
                    child: Text(statut ?? 'Tous les statuts')
                )).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          value: selectedClientFilter,
          decoration: InputDecoration(
            labelText: 'Filtrer par client',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (val) => setState(() => selectedClientFilter = val),
          items: [
            const DropdownMenuItem(value: null, child: Text("Tous les clients")),
            ...clientNomMap.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))),
          ],
        ),
      ],
    );
  }

  Future<void> _deleteProjet(String id, String titre) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le projet"),
        content: Text("Êtes-vous sûr de vouloir supprimer '$titre' ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await projetsRef.doc(id).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Projet supprimé avec succès"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur lors de la suppression: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showProjetDetails(String docId, Map<String, dynamic> data) async {
    final clientNom = clientNomMap[data['clientId']] ?? 'Client inconnu';
    final serviceNom = serviceNomMap[data['serviceId']] ?? 'Service inconnu';
    final dateCreation = data['dateCreation'] as Timestamp?;
    final dateLivraison = data['dateLivraison'] as Timestamp?;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['titre'] ?? 'Détails du projet'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Client', clientNom),
              _buildDetailRow('Service', serviceNom),
              _buildDetailRow('Statut', data['statut'] ?? 'Non défini'),
              _buildDetailRow('Progression', '${data['progression'] ?? 0}%'),
              _buildDetailRow('Date de création', _formatDate(dateCreation)),
              if (dateLivraison != null)
                _buildDetailRow('Date de livraison', _formatDate(dateLivraison)),
              _buildDetailRow('Description', data['description'] ?? 'Aucune description'),
              if (data['commentaires'] != null && data['commentaires'].toString().isNotEmpty)
                _buildDetailRow('Commentaires', data['commentaires'].toString()),
              if (data['documents'] != null && (data['documents'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate((data['documents'] as List).length, (index) {
                      final doc = data['documents'][index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.attach_file),
                        title: Text(doc['nom'] ?? 'Document ${index + 1}'),
                        trailing: const Icon(Icons.download),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showProjetDialog({String? docId, Map<String, dynamic>? existingData}) async {
    final formKey = GlobalKey<FormState>();
    final _titre = TextEditingController(text: existingData?['titre']);
    final _description = TextEditingController(text: existingData?['description']);
    final _commentaires = TextEditingController(text: existingData?['commentaires']);
    String? selectedClientId = existingData?['clientId'];
    String? selectedServiceId = existingData?['serviceId'];
    String selectedStatut = existingData?['statut'] ?? 'Nouveau';
    double progression = (existingData?['progression'] ?? 0).toDouble();
    DateTime? dateLivraison = existingData?['dateLivraison'] != null
        ? (existingData!['dateLivraison'] as Timestamp).toDate()
        : null;
    List<Map<String, dynamic>> documents = List.from(existingData?['documents'] ?? []);
    bool isSaving = false;

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: Text(docId == null ? "Ajouter un projet" : "Modifier le projet"),
        content: SingleChildScrollView(
        child: Form(
        key: formKey,
        child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    TextFormField(
    controller: _titre,
    decoration: const InputDecoration(
    labelText: "Titre du projet *",
    border: OutlineInputBorder(),
    ),
    validator: (value) {
    if (value == null || value.trim().isEmpty) {
    return 'Le titre est obligatoire';
    }
    return null;
    },
    ),
    const SizedBox(height: 10),
    TextFormField(
    controller: _description,
    decoration: const InputDecoration(
    labelText: "Description",
    border: OutlineInputBorder(),
    ),
    maxLines: 3,
    ),
    const SizedBox(height: 10),
    // Dropdown Client
    DropdownButtonFormField<String>(
    value: selectedClientId,
    items: clientNomMap.entries.map((entry) {
    return DropdownMenuItem(
    value: entry.key,
    child: Text(entry.value),
    );
    }).toList(),
    onChanged: (val) => setDialogState(() => selectedClientId = val),
    decoration: const InputDecoration(
    labelText: "Client *",
    border: OutlineInputBorder(),
    ),
    validator: (val) => val == null ? "Veuillez choisir un client" : null,
    ),
    const SizedBox(height: 10),
    // Dropdown Service
    DropdownButtonFormField<String>(
    value: selectedServiceId,
    items: serviceNomMap.entries.map((entry) {
    return DropdownMenuItem(
    value: entry.key,
    child: Text(entry.value),
    );
    }).toList(),
    onChanged: (val) => setDialogState(() => selectedServiceId = val),
    decoration: const InputDecoration(
    labelText: "Service *",
    border: OutlineInputBorder(),
    ),
      validator: (val) => val == null ? "Veuillez choisir un service" : null,
    ),
      const SizedBox(height: 10),
      // Dropdown Statut
      DropdownButtonFormField<String>(
        value: selectedStatut,
        items: ['Nouveau', 'En cours', 'Terminé', 'Suspendu']
            .map((statut) => DropdownMenuItem(
          value: statut,
          child: Text(statut),
        ))
            .toList(),
        onChanged: (val) => setDialogState(() => selectedStatut = val!),
        decoration: const InputDecoration(
          labelText: "Statut",
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      // Slider pour la progression
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progression: ${progression.toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: progression,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${progression.toInt()}%',
            onChanged: (val) => setDialogState(() => progression = val),
          ),
        ],
      ),
      const SizedBox(height: 10),
      // Date de livraison
      Row(
        children: [
          Expanded(
            child: Text(
              dateLivraison != null
                  ? 'Date de livraison: ${_formatDate(Timestamp.fromDate(dateLivraison!))}'
                  : 'Aucune date de livraison',
            ),
          ),
          TextButton(
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: dateLivraison ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (selectedDate != null) {
                setDialogState(() => dateLivraison = selectedDate);
              }
            },
            child: const Text('Choisir date'),
          ),
          if (dateLivraison != null)
            IconButton(
              onPressed: () => setDialogState(() => dateLivraison = null),
              icon: const Icon(Icons.clear),
              tooltip: 'Supprimer la date',
            ),
        ],
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _commentaires,
        decoration: const InputDecoration(
          labelText: "Commentaires",
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 10),
      // Section Documents
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _ajouterDocument(setDialogState, documents),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          if (documents.isNotEmpty)
            ...documents.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              return ListTile(
                dense: true,
                leading: const Icon(Icons.attach_file),
                title: Text(doc['nom'] ?? 'Document ${index + 1}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setDialogState(() => documents.removeAt(index));
                  },
                ),
              );
            }).toList(),
        ],
      ),
    ],
    ),
        ),
        ),
        ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSaving = true);
                  try {
                    final projetData = {
                      'titre': _titre.text.trim(),
                      'description': _description.text.trim(),
                      'clientId': selectedClientId!,
                      'serviceId': selectedServiceId!,
                      'statut': selectedStatut,
                      'progression': progression.toInt(),
                      'commentaires': _commentaires.text.trim(),
                      'documents': documents,
                      'dateLivraison': dateLivraison != null ? Timestamp.fromDate(dateLivraison!) : null,
                      'dateModification': Timestamp.now(),
                    };

                    if (docId == null) {
                      projetData['dateCreation'] = Timestamp.now();
                      projetData['utilisateurId'] = 'current_user'; // À adapter selon votre système d'auth
                      await projetsRef.add(projetData);
                    } else {
                      await projetsRef.doc(docId).update(projetData);
                    }

                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(docId == null
                              ? "Projet ajouté avec succès"
                              : "Projet modifié avec succès"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erreur: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(docId == null ? "Ajouter" : "Modifier"),
            ),
          ],
        ),
        ),
    );
  }

  Future<void> _ajouterDocument(StateSetter setDialogState, List<Map<String, dynamic>> documents) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        final bytes = await file.readAsBytes();
        final fileName = file.name;

        // Simuler l'upload - dans un vrai projet, vous uploaderiez vers Firebase Storage
        final documentData = {
          'nom': fileName,
          'taille': bytes.length,
          'type': file.mimeType ?? 'unknown',
          'url': 'temp_url_$fileName', // URL temporaire
          'dateAjout': Timestamp.now(),
        };

        setDialogState(() {
          documents.add(documentData);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'ajout du document: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 /* Future<void> _createTestProject() async {
    final testProjects = [
      {
        'titre': 'Site Web E-commerce',
        'description': 'Développement d\'un site e-commerce avec système de paiement intégré',
        'clientId': clientNomMap.keys.first,
        'serviceId': serviceNomMap.keys.first,
        'statut': 'En cours',
        'progression': 65,
        'commentaires': 'Le client souhaite ajouter une fonctionnalité de chat en direct',
        'documents': [],
        'dateCreation': Timestamp.now(),
        'dateLivraison': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'dateModification': Timestamp.now(),
        'utilisateurId': 'test_user',
        'priorite': 'Haute',
        'budget': 5000.0,
      },
      {
        'titre': 'Application Mobile',
        'description': 'Application mobile pour la gestion des commandes',
        'clientId': clientNomMap.keys.first,
        'serviceId': serviceNomMap.keys.first,
        'statut': 'Nouveau',
        'progression': 0,
        'commentaires': 'Première réunion prévue la semaine prochaine',
        'documents': [],
        'dateCreation': Timestamp.now(),
        'dateLivraison': null,
        'dateModification': Timestamp.now(),
        'utilisateurId': 'test_user',
        'priorite': 'Normale',
        'budget': 8000.0,
      },
      {
        'titre': 'Refonte Logo',
        'description': 'Création d\'une nouvelle identité visuelle complète',
        'clientId': clientNomMap.keys.first,
        'serviceId': serviceNomMap.keys.first,
        'statut': 'Terminé',
        'progression': 100,
        'commentaires': 'Projet livré avec succès, client très satisfait',
        'documents': [],
        'dateCreation': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))),
        'dateLivraison': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'dateModification': Timestamp.now(),
        'utilisateurId': 'test_user',
        'priorite': 'Faible',
        'budget': 1500.0,
      },
    ];

    try {
      for (final project in testProjects) {
        await projetsRef.add(project);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Projets de test créés avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la création des projets de test: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }*/

  Map<String, int> _getProjectStats(List<QueryDocumentSnapshot> docs) {
    final stats = <String, int>{
      'total': docs.length,
      'nouveau': 0,
      'en_cours': 0,
      'termine': 0,
      'suspendu': 0,
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final statut = data['statut']?.toString().toLowerCase() ?? '';

      switch (statut) {
        case 'nouveau':
          stats['nouveau'] = stats['nouveau']! + 1;
          break;
        case 'en cours':
          stats['en_cours'] = stats['en_cours']! + 1;
          break;
        case 'terminé':
          stats['termine'] = stats['termine']! + 1;
          break;
        case 'suspendu':
          stats['suspendu'] = stats['suspendu']! + 1;
          break;
      }
    }

    return stats;
  }

  /*Widget _buildStatsCard(Map<String, int> stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques des projets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildStatChip('Total', stats['total']!, Colors.blue),
                _buildStatChip('Nouveau', stats['nouveau']!, Colors.purple),
                _buildStatChip('En cours', stats['en_cours']!, Colors.orange),
                _buildStatChip('Terminé', stats['termine']!, Colors.green),
                _buildStatChip('Suspendu', stats['suspendu']!, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }*/

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
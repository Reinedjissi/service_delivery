import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProjetsPage extends StatefulWidget {
  const ProjetsPage({super.key});

  @override
  State<ProjetsPage> createState() => _ProjetsPageState();
}

class _ProjetsPageState extends State<ProjetsPage> {
  final CollectionReference projetsRef = FirebaseFirestore.instance.collection('projets');
  final CollectionReference clientsRef = FirebaseFirestore.instance.collection('clients');
  final CollectionReference servicesRef = FirebaseFirestore.instance.collection('services');

  Map<String, String> clientNomMap = {};
  Map<String, String> serviceNomMap = {};
  List<QueryDocumentSnapshot> clients = [];
  List<QueryDocumentSnapshot> services = [];
  bool isLoading = true;
  String selectedStatut = 'Tous';
  String searchQuery = '';

  List<QueryDocumentSnapshot> projets = [];
  List<QueryDocumentSnapshot> projetsFiltered = [];

  // Contrôleurs pour le formulaire de création
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _commentairesController = TextEditingController();
  String? _selectedClientId;
  List<String> _selectedServiceIds = [];
  String _selectedStatutProjet = 'Nouveau';
  String _selectedPriorite = 'Normale';
  double _progression = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      await _loadClientsAndServices();
      await _loadProjets();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadClientsAndServices() async {
    // Charger les clients
    final clientsSnapshot = await clientsRef.get();
    clients = clientsSnapshot.docs;
    final clientsMap = <String, String>{};
    for (var doc in clients) {
      final data = doc.data() as Map<String, dynamic>;
      clientsMap[doc.id] = '${data['nom'] ?? ''} ${data['prenom'] ?? ''}'.trim();
    }
    clientNomMap = clientsMap;

    // Charger les services
    final servicesSnapshot = await servicesRef.get();
    services = servicesSnapshot.docs;
    final servicesMap = <String, String>{};
    for (var doc in services) {
      final data = doc.data() as Map<String, dynamic>;
      servicesMap[doc.id] = data['titre'] ?? 'Service sans titre';
    }
    serviceNomMap = servicesMap;
  }

  Future<void> _loadProjets() async {
    final snapshot = await projetsRef.orderBy('dateCreation', descending: true).get();
    projets = snapshot.docs;
    _applyFilters(); // Appelé après le chargement
  }
  void _applyFilters() {
    projetsFiltered = projets.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final statut = data['statut'] ?? 'Nouveau';
      final statutMatch = selectedStatut == 'Tous' || statut == selectedStatut;

      final titre = (data['titre'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final clientNom = clientNomMap[data['clientId']] ?? '';

      final searchMatch = searchQuery.isEmpty ||
          titre.contains(searchQuery.toLowerCase()) ||
          description.contains(searchQuery.toLowerCase()) ||
          clientNom.toLowerCase().contains(searchQuery.toLowerCase());

      return statutMatch && searchMatch;
    }).toList();

    setState(() {});
  }

  Future<void> _creerProjet() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await projetsRef.add({
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'clientId': _selectedClientId,
        'serviceIds': _selectedServiceIds,
        'budget': double.tryParse(_budgetController.text) ?? 0.0,
        'statut': _selectedStatutProjet,
        'priorite': _selectedPriorite,
        'progression': _progression,
        'commentaires': _commentairesController.text.trim(),
        'dateCreation': Timestamp.now(),
        'dateModification': Timestamp.now(),
      });

      _resetForm();
      Navigator.of(context).pop();
      _loadProjets();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marchés créé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _modifierStatut(String projetId, String nouveauStatut) async {
    try {
      await projetsRef.doc(projetId).update({
        'statut': nouveauStatut,
        'dateModification': Timestamp.now(),
      });

      _loadProjets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut mis à jour')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _supprimerProjet(String projetId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce Marchés ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await projetsRef.doc(projetId).delete();
        _loadProjets();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marchés supprimé')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _resetForm() {
    _titreController.clear();
    _descriptionController.clear();
    _budgetController.clear();
    _commentairesController.clear();
    _selectedClientId = null;
    _selectedServiceIds.clear();
    _selectedStatutProjet = 'Nouveau';
    _selectedPriorite = 'Normale';
    _progression = 0.0;
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'Nouveau':
        return Colors.purple;
      case 'En cours':
        return Colors.blue;
      case 'Terminé':
        return Colors.green;
      case 'Suspendu':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'Haute':
        return Colors.red;
      case 'Normale':
        return Colors.orange;
      case 'Basse':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Non défini';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 16),
            _buildFilters(isMobile),
            const SizedBox(height: 16),
            _buildSummary(isMobile),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(child: _buildProjetsList(isMobile)),
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
            "Gestion des Projets",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateProjetDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nouveau', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Text(
            "Gestion des Marchés",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showCreateProjetDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau Marchés'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildFilters(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Rechercher...',
              hintText: 'Titre, description ou client',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStatut,
            decoration: InputDecoration(
              labelText: 'Filtrer par statut',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              selectedStatut = val!;
              _applyFilters();
            },
            items: ['Tous', 'Nouveau', 'En cours', 'Terminé', 'Suspendu']
                .map((statut) => DropdownMenuItem(value: statut, child: Text(statut)))
                .toList(),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Rechercher...',
              hintText: 'Titre, description ou client',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) {
              searchQuery = value;
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: selectedStatut,
            decoration: InputDecoration(
              labelText: 'Statut',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              selectedStatut = val!;
              _applyFilters();
            },
            items: ['Tous', 'Nouveau', 'En cours', 'Terminé', 'Suspendu']
                .map((statut) => DropdownMenuItem(value: statut, child: Text(statut)))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(bool isMobile) {
    final total = projetsFiltered.length;
    final nouveaux = projetsFiltered.where((p) => (p.data() as Map)['statut'] == 'Nouveau').length;
    final enCours = projetsFiltered.where((p) => (p.data() as Map)['statut'] == 'En cours').length;
    final termines = projetsFiltered.where((p) => (p.data() as Map)['statut'] == 'Terminé').length;
    final suspendus = projetsFiltered.where((p) => (p.data() as Map)['statut'] == 'Suspendu').length;

    if (isMobile) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total', total.toString(), Colors.blue, true),
                  _buildSummaryItem('Nouveaux', nouveaux.toString(), Colors.purple, true),
                  _buildSummaryItem('En cours', enCours.toString(), Colors.orange, true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Terminés', termines.toString(), Colors.green, true),
                  _buildSummaryItem('Suspendus', suspendus.toString(), Colors.red, true),
                  const SizedBox(width: 50), // Espace vide pour l'alignement
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total', total.toString(), Colors.blue, false),
            _buildSummaryItem('Nouveaux', nouveaux.toString(), Colors.purple, false),
            _buildSummaryItem('En cours', enCours.toString(), Colors.orange, false),
            _buildSummaryItem('Terminés', termines.toString(), Colors.green, false),
            _buildSummaryItem('Suspendus', suspendus.toString(), Colors.red, false),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isMobile) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProjetsList(bool isMobile) {
    if (projetsFiltered.isEmpty) {
      return const Center(
        child: Text(
          'Aucun Marchés trouvé',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: projetsFiltered.length,
      itemBuilder: (context, index) {
        final doc = projetsFiltered[index];
        final data = doc.data() as Map<String, dynamic>;

        if (isMobile) {
          return _buildMobileProjetCard(doc, data);
        }

        return _buildDesktopProjetCard(doc, data);
      },
    );
  }

  Widget _buildMobileProjetCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showProjetDetailsDialog(doc, data),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['titre'] ?? 'Sans titre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatutColor(data['statut'] ?? 'Nouveau'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data['statut'] ?? 'Nouveau',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Client: ${clientNomMap[data['clientId']] ?? 'Non défini'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Créé: ${_formatDate(data['dateCreation'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (data['progression'] != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (data['progression'] as num).toDouble() / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatutColor(data['statut'] ?? 'Nouveau'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progression: ${data['progression']}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _showStatutMenu(context, doc.id),
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Changer statut',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _supprimerProjet(doc.id),
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'Supprimer',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopProjetCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                data['titre'] ?? 'Sans titre',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatutColor(data['statut'] ?? 'Nouveau'),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data['statut'] ?? 'Nouveau',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${clientNomMap[data['clientId']] ?? 'Non défini'}'),
            Text('Créé: ${_formatDate(data['dateCreation'])}'),
            if (data['progression'] != null)
              LinearProgressIndicator(
                value: (data['progression'] as num).toDouble() / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatutColor(data['statut'] ?? 'Nouveau'),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['description'] != null && data['description'].isNotEmpty)
                  Text('Description: ${data['description']}'),

                if (data['serviceIds'] != null && (data['serviceIds'] as List).isNotEmpty)
                  Text('Services: ${(data['serviceIds'] as List).map((id) => serviceNomMap[id] ?? 'Inconnu').join(', ')}'),

                if (data['budget'] != null)
                  Text('Budget: ${data['budget']} FCFA'),

                if (data['priorite'] != null)
                  Row(
                    children: [
                      const Text('Priorité: '),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPrioriteColor(data['priorite']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['priorite'],
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                if (data['progression'] != null)
                  Text('Progression: ${data['progression']}%'),

                if (data['commentaires'] != null && data['commentaires'].isNotEmpty)
                  Text('Commentaires: ${data['commentaires']}'),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      child: ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.edit),
                        label: const Text('Changer statut'),
                      ),
                      onSelected: (newStatut) => _modifierStatut(doc.id, newStatut),
                      itemBuilder: (context) => [
                        'Nouveau',
                        'En cours',
                        'Terminé',
                        'Suspendu'
                      ].map((statut) => PopupMenuItem(
                        value: statut,
                        child: Text(statut),
                      )).toList(),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _supprimerProjet(doc.id),
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatutMenu(BuildContext context, String projetId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Changer le statut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...['Nouveau', 'En cours', 'Terminé', 'Suspendu'].map((statut) =>
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatutColor(statut),
                  radius: 8,
                ),
                title: Text(statut),
                onTap: () {
                  Navigator.pop(context);
                  _modifierStatut(projetId, statut);
                },
              ),
          ).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showProjetDetailsDialog(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text(data['titre'] ?? 'Sans titre'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data['description'] != null && data['description'].isNotEmpty) ...[
                    const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['description']),
                    const SizedBox(height: 12),
                  ],

                  Text('Client: ${clientNomMap[data['clientId']] ?? 'Non défini'}'),
                  const SizedBox(height: 8),

                  if (data['serviceIds'] != null && (data['serviceIds'] as List).isNotEmpty) ...[
                    const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text((data['serviceIds'] as List).map((id) => serviceNomMap[id] ?? 'Inconnu').join(', ')),
                    const SizedBox(height: 8),
                  ],

                  if (data['budget'] != null) ...[
                    Text('Budget: ${data['budget']} FCFA'),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    children: [
                      const Text('Statut: '),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatutColor(data['statut'] ?? 'Nouveau'),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['statut'] ?? 'Nouveau',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (data['priorite'] != null) ...[
                    Row(
                      children: [
                        const Text('Priorité: '),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPrioriteColor(data['priorite']),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['priorite'],
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (data['progression'] != null) ...[
                    Text('Progression: ${data['progression']}%'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (data['progression'] as num).toDouble() / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatutColor(data['statut'] ?? 'Nouveau'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (data['commentaires'] != null && data['commentaires'].isNotEmpty) ...[
                    const Text('Commentaires:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['commentaires']),
                    const SizedBox(height: 8),
                  ],

                  Text('Créé: ${_formatDate(data['dateCreation'])}'),
                  if (data['dateModification'] != null)
                    Text('Modifié: ${_formatDate(data['dateModification'])}'),
                ],
              ),
            ),
            actions: [
            TextButton(
            onPressed: () => Navigator.pop(context),
    child: const Text('Fermer'),
    ),
    TextButton(
    onPressed: () {
    Navigator.pop(context);
    _showStatutMenu(context, doc.id);
    },
      child: const Text('Changer statut'),
    ),
            ],
        ),
    );
  }

  void _showCreateProjetDialog() {
    _resetForm();
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _MobileCreateProjetPage(
            formKey: _formKey,
            titreController: _titreController,
            descriptionController: _descriptionController,
            budgetController: _budgetController,
            commentairesController: _commentairesController,
            clients: clients,
            services: services,
            selectedClientId: _selectedClientId,
            selectedServiceIds: _selectedServiceIds,
            selectedPriorite: _selectedPriorite,
            onClientChanged: (value) => setState(() => _selectedClientId = value),
            onServiceChanged: (serviceId, isSelected) => setState(() {
              if (isSelected) {
                _selectedServiceIds.add(serviceId);
              } else {
                _selectedServiceIds.remove(serviceId);
              }
            }),
            onPrioriteChanged: (value) => setState(() => _selectedPriorite = value!),
            onSubmit: _creerProjet,
          ),
        ),
      );
    } else {
      _showDesktopCreateProjetDialog();
    }
  }

  void _showDesktopCreateProjetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un nouveau Marchés'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titreController,
                    decoration: const InputDecoration(labelText: 'Titre *'),
                    validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedClientId,
                    decoration: const InputDecoration(labelText: 'Client *'),
                    validator: (value) => value == null ? 'Champ obligatoire' : null,
                    onChanged: (value) => setState(() => _selectedClientId = value),
                    items: clients.map((client) {
                      final data = client.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: client.id,
                        child: Text('${data['nom']} ${data['prenom']}'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setDialogState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Services *'),
                        ...services.map((service) {
                          final data = service.data() as Map<String, dynamic>;
                          return CheckboxListTile(
                            title: Text(data['titre']),
                            value: _selectedServiceIds.contains(service.id),
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  if (!_selectedServiceIds.contains(service.id)) {
                                    _selectedServiceIds.add(service.id);
                                  }
                                } else {
                                  _selectedServiceIds.remove(service.id);
                                }
                              });
                              setState(() {}); // Synchronise l'état global
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _budgetController,
                    decoration: const InputDecoration(labelText: 'Budget (FCFA)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPriorite,
                    decoration: const InputDecoration(labelText: 'Priorité'),
                    onChanged: (value) => setState(() => _selectedPriorite = value!),
                    items: ['Haute', 'Normale', 'Basse']
                        .map((priorite) => DropdownMenuItem(value: priorite, child: Text(priorite)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentairesController,
                    decoration: const InputDecoration(labelText: 'Commentaires'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _progression,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_progression.round()}%',
                    onChanged: (value) => setState(() => _progression = value),
                  ),
                  Text('Progression: ${_progression.round()}%'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _creerProjet,
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _MobileCreateProjetPage extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titreController;
  final TextEditingController descriptionController;
  final TextEditingController budgetController;
  final TextEditingController commentairesController;
  final List<QueryDocumentSnapshot> clients;
  final List<QueryDocumentSnapshot> services;
  final String? selectedClientId;
  final List<String> selectedServiceIds;
  final String selectedPriorite;
  final Function(String?) onClientChanged;
  final Function(String, bool) onServiceChanged;
  final Function(String?) onPrioriteChanged;
  final VoidCallback onSubmit;

  const _MobileCreateProjetPage({
    required this.formKey,
    required this.titreController,
    required this.descriptionController,
    required this.budgetController,
    required this.commentairesController,
    required this.clients,
    required this.services,
    required this.selectedClientId,
    required this.selectedServiceIds,
    required this.selectedPriorite,
    required this.onClientChanged,
    required this.onServiceChanged,
    required this.onPrioriteChanged,
    required this.onSubmit,
  });

  @override
  State<_MobileCreateProjetPage> createState() => _MobileCreateProjetPageState();
}

class _MobileCreateProjetPageState extends State<_MobileCreateProjetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Projet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              if (widget.formKey.currentState!.validate()) {
                widget.onSubmit();
              }
            },
            child: const Text(
              'Créer',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: widget.titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value?.isEmpty == true
                    ? 'Champ obligatoire'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: widget.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: widget.selectedClientId,
                decoration: const InputDecoration(
                  labelText: 'Client *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null
                    ? 'Champ obligatoire'
                    : null,
                onChanged: widget.onClientChanged,
                items: widget.clients.map((client) {
                  final data = client.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: client.id,
                    child: Text('${data['nom']} ${data['prenom']}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text(
                'Services *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: widget.services.map((service) {
                    final data = service.data() as Map<String, dynamic>;
                    return CheckboxListTile(
                      title: Text(data['titre']),
                      value: widget.selectedServiceIds.contains(service.id),
                      onChanged: (checked) {
                        widget.onServiceChanged(service.id, checked == true);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: widget.budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (FCFA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: widget.selectedPriorite,
                decoration: const InputDecoration(
                  labelText: 'Priorité',
                  border: OutlineInputBorder(),
                ),
                onChanged: widget.onPrioriteChanged,
                items: ['Haute', 'Normale', 'Basse']
                    .map((priorite) =>
                    DropdownMenuItem(value: priorite, child: Text(priorite)))
                    .toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: widget.commentairesController,
                decoration: const InputDecoration(
                  labelText: 'Commentaires',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.formKey.currentState!.validate()) {
                      widget.onSubmit();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Créer le Marchés',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
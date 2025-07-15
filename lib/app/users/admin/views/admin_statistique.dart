import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatistiquesPage extends StatefulWidget {
  static const String routeName = '/statistiques';

  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  final CollectionReference projetsRef = FirebaseFirestore.instance.collection('projets');
  final CollectionReference clientsRef = FirebaseFirestore.instance.collection('clients');
  final CollectionReference servicesRef = FirebaseFirestore.instance.collection('services');

  Map<String, String> clientNomMap = {};
  Map<String, String> serviceNomMap = {};
  bool isLoading = true;
  String selectedPeriode = 'Tous';
  String selectedMetrique = 'Projets';

  // Données statistiques
  Map<String, int> statutStats = {};
  Map<String, int> clientStats = {};
  Map<String, int> serviceStats = {};
  Map<String, double> budgetStats = {};
  Map<String, int> prioriteStats = {};
  List<Map<String, dynamic>> progressionData = [];
  List<Map<String, dynamic>> tendanceData = [];

  int totalProjets = 0;
  double budgetTotal = 0;
  double progressionMoyenne = 0;
  int projetsTermines = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // Charger les clients et services
      await _loadClientsAndServices();

      // Charger les statistiques des projets
      await _loadProjectStats();

    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadClientsAndServices() async {
    // Charger les clients
    final clientsSnapshot = await clientsRef.get();
    final clientsMap = <String, String>{};
    for (var doc in clientsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final nom = data['nom']?.toString() ?? '';
      final prenom = data['prenom']?.toString() ?? '';
      clientsMap[doc.id] = '$nom $prenom'.trim();
    }
    clientNomMap = clientsMap;

    // Charger les services
    final servicesSnapshot = await servicesRef.get();
    final servicesMap = <String, String>{};
    for (var doc in servicesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      servicesMap[doc.id] = data['titre']?.toString() ?? 'Service sans titre';
    }
    serviceNomMap = servicesMap;
  }

  Future<void> _loadProjectStats() async {
    Query query = projetsRef;

    // Filtrer par période si nécessaire
    if (selectedPeriode != 'Tous') {
      DateTime startDate;
      switch (selectedPeriode) {
        case '7 jours':
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case '30 jours':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case '3 mois':
          startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        case '6 mois':
          startDate = DateTime.now().subtract(const Duration(days: 180));
          break;
        case '1 an':
          startDate = DateTime.now().subtract(const Duration(days: 365));
          break;
        default:
          startDate = DateTime.now().subtract(const Duration(days: 30));
      }
      query = query.where('dateCreation', isGreaterThan: Timestamp.fromDate(startDate));
    }

    final snapshot = await query.get();
    final projets = snapshot.docs;

    // Réinitialiser les stats
    statutStats.clear();
    clientStats.clear();
    serviceStats.clear();
    budgetStats.clear();
    prioriteStats.clear();
    progressionData.clear();
    tendanceData.clear();

    totalProjets = projets.length;
    budgetTotal = 0;
    progressionMoyenne = 0;
    projetsTermines = 0;

    // Calculer les statistiques
    for (var doc in projets) {
      final data = doc.data() as Map<String, dynamic>;

      // Stats par statut
      final statut = data['statut']?.toString() ?? 'Non défini';
      statutStats[statut] = (statutStats[statut] ?? 0) + 1;

      if (statut == 'Terminé') projetsTermines++;

      // Stats par client
      final clientId = data['clientId']?.toString();
      if (clientId != null && clientId.isNotEmpty) {
        final clientNom = clientNomMap[clientId] ?? 'Client inconnu';
        clientStats[clientNom] = (clientStats[clientNom] ?? 0) + 1;
      }

      // Stats par service
      final serviceIds = data['serviceIds'] as List<dynamic>? ?? [];
      for (var serviceId in serviceIds) {
        final serviceIdStr = serviceId?.toString();
        if (serviceIdStr != null && serviceIdStr.isNotEmpty) {
          final serviceNom = serviceNomMap[serviceIdStr] ?? 'Service inconnu';
          serviceStats[serviceNom] = (serviceStats[serviceNom] ?? 0) + 1;
        }
      }

      // Stats budget
      final budget = data['budget'];
      if (budget != null && budget is num) {
        final budgetValue = budget.toDouble();
        budgetTotal += budgetValue;

        final statutBudget = data['statut']?.toString() ?? 'Non défini';
        budgetStats[statutBudget] = (budgetStats[statutBudget] ?? 0) + budgetValue;
      }

      // Stats priorité
      final priorite = data['priorite']?.toString() ?? 'Normale';
      prioriteStats[priorite] = (prioriteStats[priorite] ?? 0) + 1;

      // Progression
      final progression = data['progression'];
      final progressionValue = progression != null && progression is num
          ? progression.toDouble()
          : 0.0;
      progressionMoyenne += progressionValue;

      progressionData.add({
        'titre': data['titre']?.toString() ?? 'Sans titre',
        'progression': progressionValue,
        'statut': statut,
      });
    }

    if (totalProjets > 0) {
      progressionMoyenne = progressionMoyenne / totalProjets;
    }

    // Calculer la tendance (projets créés par mois sur les 6 derniers mois)
    await _calculateTendance();
  }

  Future<void> _calculateTendance() async {
    final now = DateTime.now();
    tendanceData.clear();

    for (int i = 5; i >= 0; i--) {
      // Calcul correct des dates de début et fin de mois
      DateTime startDate;
      DateTime endDate;

      if (now.month - i > 0) {
        startDate = DateTime(now.year, now.month - i, 1);
        endDate = DateTime(now.year, now.month - i + 1, 1);
      } else {
        // Gérer le cas où on traverse l'année précédente
        final targetMonth = 12 + (now.month - i);
        final targetYear = now.year - 1;
        startDate = DateTime(targetYear, targetMonth, 1);
        endDate = DateTime(targetYear, targetMonth + 1, 1);
      }

      final snapshot = await projetsRef
          .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateCreation', isLessThan: Timestamp.fromDate(endDate))
          .get();

      final monthNames = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];

      // Utiliser l'index correct pour le mois
      final monthIndex = startDate.month - 1;
      final monthName = monthNames[monthIndex];

      tendanceData.add({
        'mois': monthName,
        'projets': snapshot.docs.length, // ← Correction ici : 'projets' au lieu de 'Marchés'
        'budget': snapshot.docs.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final budget = data['budget'];
          return sum + (budget != null && budget is num ? budget.toDouble() : 0.0);
        }),
      });
    }
  }

  // Méthode pour déterminer la taille de l'écran
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text(
                "Statistiques",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                ),
              ],
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  children: [
                    _buildFilters(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    if (isLoading)
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      _buildStatsContent(isMobile, isTablet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildFilterDropdown(
            'Période',
            selectedPeriode,
            ['Tous', '7 jours', '30 jours', '3 mois', '6 mois', '1 an'],
                (val) {
              setState(() => selectedPeriode = val!);
              _loadData();
            },
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            'Métrique',
            selectedMetrique,
            ['Projets', 'Budget', 'Progression'],
                (val) => setState(() => selectedMetrique = val!),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              'Période',
              selectedPeriode,
              ['Tous', '7 jours', '30 jours', '3 mois', '6 mois', '1 an'],
                  (val) {
                setState(() => selectedPeriode = val!);
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildFilterDropdown(
              'Métrique',
              selectedMetrique,
              ['Projets', 'Budget', 'Progression'],
                  (val) => setState(() => selectedMetrique = val!),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFilterDropdown(
      String label,
      String value,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
    );
  }

  Widget _buildStatsContent(bool isMobile, bool isTablet) {
    return Column(
      children: [
        // Cartes de résumé
        _buildSummaryCards(isMobile, isTablet),
        SizedBox(height: isMobile ? 16 : 20),

        // Graphiques
        _buildChartsLayout(isMobile, isTablet),

        SizedBox(height: isMobile ? 16 : 20),
        _buildDetailedStats(isMobile),
      ],
    );
  }

  Widget _buildSummaryCards(bool isMobile, bool isTablet) {
    final cards = [
      _buildSummaryCard(
        'Total Projets',
        totalProjets.toString(),
        Icons.work,
        Colors.blue,
        isMobile,
      ),
      _buildSummaryCard(
        'Projets Terminés',
        projetsTermines.toString(),
        Icons.check_circle,
        Colors.green,
        isMobile,
      ),
      _buildSummaryCard(
        'Budget Total',
        '${budgetTotal.toStringAsFixed(0)} FCFA',
        Icons.euro,
        Colors.orange,
        isMobile,
      ),
      _buildSummaryCard(
        'Progression Moyenne',
        '${progressionMoyenne.toStringAsFixed(1)}%',
        Icons.trending_up,
        Colors.purple,
        isMobile,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: cards,
      );
    } else if (isTablet) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: cards,
      );
    } else {
      return Row(
        children: cards.map((card) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: card,
          ),
        )).toList(),
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isMobile ? 24 : 32, color: color),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 2 : 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsLayout(bool isMobile, bool isTablet) {
    final charts = [
      _buildStatutChart(isMobile),
      _buildTendanceChart(isMobile),
      _buildProgressionChart(isMobile),
      _buildClientChart(isMobile),
    ];

    if (isMobile) {
      return Column(
        children: charts.map((chart) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: chart,
        )).toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: charts[0]),
              const SizedBox(width: 12),
              Expanded(child: charts[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: charts[2]),
              const SizedBox(width: 12),
              Expanded(child: charts[3]),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: charts[0]),
              const SizedBox(width: 16),
              Expanded(child: charts[1]),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: charts[2]),
              const SizedBox(width: 16),
              Expanded(child: charts[3]),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatutChart(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            Text(
              'Répartition par Statut',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            SizedBox(
              height: isMobile ? 160 : 200,
              child: statutStats.isEmpty
                  ? const Center(child: Text('Aucune donnée'))
                  : PieChart(
                PieChartData(
                  sections: statutStats.entries.map((entry) {
                    final colors = {
                      'Nouveau': Colors.purple,
                      'En cours': Colors.blue,
                      'Terminé': Colors.green,
                      'Suspendu': Colors.orange,
                    };
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: isMobile ? '${entry.value}' : '${entry.key}\n${entry.value}',
                      color: colors[entry.key] ?? Colors.grey,
                      radius: isMobile ? 50 : 60,
                      titleStyle: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: isMobile ? 30 : 40,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            if (isMobile)
              Column(
                children: statutStats.entries.map((entry) {
                  final colors = {
                    'Nouveau': Colors.purple,
                    'En cours': Colors.blue,
                    'Terminé': Colors.green,
                    'Suspendu': Colors.orange,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[entry.key] ?? Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${entry.key} (${entry.value})')),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              Wrap(
                children: statutStats.entries.map((entry) {
                  final colors = {
                    'Nouveau': Colors.purple,
                    'En cours': Colors.blue,
                    'Terminé': Colors.green,
                    'Suspendu': Colors.orange,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[entry.key] ?? Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${entry.key} (${entry.value})'),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTendanceChart(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            Text(
              'Tendance ${selectedMetrique == 'Budget' ? 'Budget' : 'Projets'} (6 mois)',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            SizedBox(
              height: isMobile ? 160 : 200,
              child: tendanceData.isEmpty
                  ? const Center(child: Text('Aucune donnée'))
                  : LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: !isMobile,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 30 : 40,
                        getTitlesWidget: (value, meta) {
                          if (isMobile && value != 0 && value % 2 != 0) {
                            return const SizedBox();
                          }
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(fontSize: isMobile ? 10 : 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 25 : 30,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < tendanceData.length) {
                            return Text(
                              tendanceData[value.toInt()]['mois'],
                              style: TextStyle(fontSize: isMobile ? 10 : 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: tendanceData.asMap().entries.map((entry) {
                        final value = selectedMetrique == 'Budget'
                            ? (entry.value['budget'] as double? ?? 0.0)
                            : (entry.value['projets'] as int? ?? 0).toDouble(); // ← Correction ici
                        return FlSpot(entry.key.toDouble(), value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: !isMobile),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionChart(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            Text(
              'Distribution de la Progression',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            SizedBox(
              height: isMobile ? 160 : 200,
              child: progressionData.isEmpty
                  ? const Center(child: Text('Aucune donnée'))
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _buildProgressionBars(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 30 : 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(fontSize: isMobile ? 10 : 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 25 : 30,
                        getTitlesWidget: (value, meta) {
                          final ranges = isMobile
                              ? ['0-25', '26-50', '51-75', '76-100']
                              : ['0-25%', '26-50%', '51-75%', '76-100%'];
                          if (value >= 0 && value < ranges.length) {
                            return Text(
                              ranges[value.toInt()],
                              style: TextStyle(fontSize: isMobile ? 10 : 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildProgressionBars() {
    final ranges = [0, 0, 0, 0]; // 0-25, 26-50, 51-75, 76-100

    for (var projet in progressionData) {
      final progression = projet['progression'] as double;
      if (progression <= 25) {
        ranges[0]++;
      } else if (progression <= 50) {
        ranges[1]++;
      } else if (progression <= 75) {
        ranges[2]++;
      } else {
        ranges[3]++;
      }
    }

    return ranges.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.blue,
            width: 20,
          ),
        ],
      );
    }).toList();
  }
  Widget _buildClientChart(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            Text(
              'Projets par Client',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            SizedBox(
              height: isMobile ? 160 : 200,
              child: clientStats.isEmpty
                  ? const Center(child: Text('Aucune donnée'))
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _buildClientBars(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 30 : 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(fontSize: isMobile ? 10 : 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 35 : 40,
                        getTitlesWidget: (value, meta) {
                          final clients = clientStats.keys.toList();
                          if (value >= 0 && value < clients.length) {
                            final clientName = clients[value.toInt()];
                            // Tronquer le nom si trop long sur mobile
                            final displayName = isMobile && clientName.length > 8
                                ? '${clientName.substring(0, 8)}...'
                                : clientName;
                            return Transform.rotate(
                              angle: isMobile ? -0.5 : -0.3,
                              child: Text(
                                displayName,
                                style: TextStyle(fontSize: isMobile ? 10 : 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildClientBars() {
    final clients = clientStats.entries.toList();
    // Limiter aux 10 premiers clients pour éviter l'encombrement
    final topClients = clients.take(10).toList();

    return topClients.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: Colors.green,
            width: 20,
          ),
        ],
      );
    }).toList();
  }

  Widget _buildDetailedStats(bool isMobile) {
    return Column(
      children: [
        // Statistiques par service
        _buildServiceStats(isMobile),
        SizedBox(height: isMobile ? 16 : 20),

        // Statistiques par priorité
        _buildPriorityStats(isMobile),
        SizedBox(height: isMobile ? 16 : 20),

        // Statistiques budget par statut
        _buildBudgetStats(isMobile),
      ],
    );
  }

  Widget _buildServiceStats(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services les plus demandés',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            if (serviceStats.isEmpty)
              const Center(child: Text('Aucune donnée'))
            else
              Column(
                children: serviceStats.entries
                    .toList()
                    .take(5) // Limiter aux 5 premiers services
                    .map((entry) => _buildServiceStatItem(entry, isMobile))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatItem(MapEntry<String, int> entry, bool isMobile) {
    final percentage = totalProjets > 0 ? (entry.value / totalProjets * 100) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              entry.key,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Text(
            '${entry.value} (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityStats(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par Priorité',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            if (prioriteStats.isEmpty)
              const Center(child: Text('Aucune donnée'))
            else
              Row(
                children: prioriteStats.entries.map((entry) {
                  final colors = {
                    'Haute': Colors.red,
                    'Moyenne': Colors.orange,
                    'Normale': Colors.green,
                    'Basse': Colors.grey,
                  };
                  return Expanded(
                    child: _buildPriorityCard(
                      entry.key,
                      entry.value,
                      colors[entry.key] ?? Colors.grey,
                      isMobile,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard(String priority, int count, Color color, bool isMobile) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Column(
          children: [
            Icon(
              Icons.priority_high,
              color: color,
              size: isMobile ? 20 : 24,
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              priority,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStats(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget par Statut',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            if (budgetStats.isEmpty)
              const Center(child: Text('Aucune donnée'))
            else
              Column(
                children: budgetStats.entries
                    .map((entry) => _buildBudgetStatItem(entry, isMobile))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStatItem(MapEntry<String, double> entry, bool isMobile) {
    final percentage = budgetTotal > 0 ? (entry.value / budgetTotal * 100) : 0.0;
    final colors = {
      'Nouveau': Colors.purple,
      'En cours': Colors.blue,
      'Terminé': Colors.green,
      'Suspendu': Colors.orange,
    };
    final color = colors[entry.key] ?? Colors.grey;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            flex: 2,
            child: Text(
              entry.key,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              color: color,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Text(
            '${entry.value.toStringAsFixed(0)} FCFA (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

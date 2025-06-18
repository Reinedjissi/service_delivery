import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:service_delivery/app/users/admin/views/admin_categorie.dart';
import 'package:service_delivery/app/users/admin/views/admin_projets.dart';
import 'package:service_delivery/app/users/admin/views/admin_services.dart';

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({Key? key}) : super(key: key);

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  int touchedIndex = -1; // Pour tracker quelle section est touchée

  // Données pour les services
  final List<Map<String, dynamic>> servicesData = [
    {'nom': 'ENCEINTE LUMINEUSE', 'valeur': 35, 'couleur': Colors.blue[200]!},
    {'nom': 'Totem double face', 'valeur': 25, 'couleur': Colors.green[200]!},
    {'nom': 'Totem mono face lumineuse', 'valeur': 20, 'couleur': Colors.orange[200]!},
    {'nom': 'Plaque lumineuse', 'valeur': 15, 'couleur': Colors.purple[200]!},
    {'nom': 'Plaque non lumineuse', 'valeur': 5, 'couleur': Colors.red[200]!},
  ];

  // Données pour les projets (évolution mensuelle)
  final List<Map<String, dynamic>> projetsData = [
    {'mois': 'Jan', 'nouveaux': 5, 'termines': 3},
    {'mois': 'Fév', 'nouveaux': 8, 'termines': 6},
    {'mois': 'Mar', 'nouveaux': 12, 'termines': 4},
    {'mois': 'Avr', 'nouveaux': 7, 'termines': 9},
    {'mois': 'Mai', 'nouveaux': 15, 'termines': 8},
    {'mois': 'Jun', 'nouveaux': 10, 'termines': 12},
  ];

  @override
  Widget build(BuildContext context) {
    // Obtenir les dimensions de l'écran
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Services - Layout adaptatif
            if (isLargeScreen)
              _buildLargeScreenServicesSection(screenWidth)
            else if (isTablet)
              _buildTabletServicesSection(screenWidth)
            else
              _buildMobileServicesSection(screenWidth),

            SizedBox(height: isLargeScreen ? 32 : 20),

            // Section Projets - Layout adaptatif
            if (isLargeScreen)
              _buildLargeScreenProjectsSection(screenWidth)
            else if (isTablet)
              _buildTabletProjectsSection(screenWidth)
            else
              _buildMobileProjectsSection(screenWidth),

            SizedBox(height: isLargeScreen ? 32 : 20),

            // Résumé statistiques - Layout adaptatif
            _buildResponsiveSummaryCards(isTablet, isLargeScreen),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: isTablet ? 14 : 12,
        unselectedFontSize: isTablet ? 12 : 10,
        onTap: (index) {
          if (index == 0) return;
          switch (index) {
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AdminProjets()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AdminCategories()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AdminServices()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Projets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catégories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Services',
          ),
        ],
      ),
    );
  }

  // Version mobile (< 600px)
  Widget _buildMobileServicesSection(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Répartition des Services', Icons.pie_chart, Colors.blue[200]!),
            const SizedBox(height: 20),
            Column(
              children: [
                SizedBox(
                  height: screenWidth * 0.7, // Hauteur adaptative
                  child: _buildPieChart(screenWidth * 0.15, screenWidth * 0.18),
                ),
                const SizedBox(height: 16),
                _buildServiceDisplay(),
                const SizedBox(height: 16),
                _buildCompactLegend(false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Version tablette (600px - 900px)
  Widget _buildTabletServicesSection(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Répartition des Services', Icons.pie_chart, Colors.blue[200]!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 350,
                    child: _buildPieChart(100, 120),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildServiceDisplay(),
                      const SizedBox(height: 16),
                      _buildCompactLegend(true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Version grand écran (> 900px)
  Widget _buildLargeScreenServicesSection(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Répartition des Services', Icons.pie_chart, Colors.blue[200]!),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 400,
                    child: _buildPieChart(120, 140),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildServiceDisplay(),
                      const SizedBox(height: 24),
                      _buildDetailedLegend(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Version mobile pour les projets
  Widget _buildMobileProjectsSection(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Évolution des Projets', Icons.bar_chart, Colors.green[200]!),
            const SizedBox(height: 20),
            SizedBox(
              height: screenWidth * 0.8,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 16),
            _buildBarLegend(),
          ],
        ),
      ),
    );
  }

  // Version tablette pour les projets
  Widget _buildTabletProjectsSection(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Évolution des Projets', Icons.bar_chart, Colors.green[200]!),
            const SizedBox(height: 24),
            Container(
              height: 350,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 20),
            _buildBarLegend(),
          ],
        ),
      ),
    );
  }

  // Version grand écran pour les projets
  Widget _buildLargeScreenProjectsSection(double screenWidth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Évolution des Projets', Icons.bar_chart, Colors.green[200]!),
            const SizedBox(height: 32),
            Container(
              height: 400,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 24),
            _buildBarLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(double normalRadius, double touchedRadius) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (event is FlTapUpEvent) {
              setState(() {
                if (pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                int newIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                touchedIndex = (touchedIndex == newIndex) ? -1 : newIndex;
              });
            }
          },
        ),
        sections: _buildPieChartSections(normalRadius, touchedRadius),
        centerSpaceRadius: normalRadius * 0.6,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20.0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (group.x.toInt() >= projetsData.length) {
                return null;
              }
              String mois = projetsData[group.x.toInt()]['mois'];
              String type = rodIndex == 0 ? 'Nouveaux' : 'Terminés';
              return BarTooltipItem(
                '$type\n$mois: ${rod.toY.round()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                int index = value.toInt();
                if (index >= 0 && index < projetsData.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      projetsData[index]['mois'] as String,
                      style: style,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5.0,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildServiceDisplay() {
    return Container(
      width: double.infinity,
      child: touchedIndex >= 0 && touchedIndex < servicesData.length
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: servicesData[touchedIndex]['couleur'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: servicesData[touchedIndex]['couleur'].withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app,
              color: servicesData[touchedIndex]['couleur'],
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              servicesData[touchedIndex]['nom'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: servicesData[touchedIndex]['couleur'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${servicesData[touchedIndex]['valeur']}% du total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: servicesData[touchedIndex]['couleur'],
              ),
            ),
          ],
        ),
      )
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.grey.shade500,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              '',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(double normalRadius, double touchedRadius) {
    return List.generate(servicesData.length, (index) {
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? touchedRadius : normalRadius;
      final service = servicesData[index];

      return PieChartSectionData(
        color: service['couleur'] as Color,
        value: (service['valeur'] as int).toDouble(),
        title: '${service['valeur']}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCompactLegend(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Légende:',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: servicesData.map((service) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 10 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: service['couleur'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: service['couleur'].withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isTablet ? 12 : 10,
                    height: isTablet ? 12 : 10,
                    decoration: BoxDecoration(
                      color: service['couleur'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${service['valeur']}%',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: service['couleur'],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailedLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tous les services:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...servicesData.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> service = entry.value;
          bool isSelected = index == touchedIndex;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? service['couleur'].withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: service['couleur'].withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: service['couleur'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service['nom'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? service['couleur']
                          : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '${service['valeur']}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? service['couleur']
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(projetsData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (projetsData[index]['nouveaux'] as int).toDouble(),
            color: Colors.blue[200]!,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: (projetsData[index]['termines'] as int).toDouble(),
            color: Colors.green[200],
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Nouveaux projets'),
          ],
        ),
        const SizedBox(width: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green[200],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Projets terminés'),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsiveSummaryCards(bool isTablet, bool isLargeScreen) {
    int totalNouveaux = projetsData.fold(0, (sum, item) => sum + (item['nouveaux'] as int));
    int totalTermines = projetsData.fold(0, (sum, item) => sum + (item['termines'] as int));

    final cardPadding = isLargeScreen ? 20.0 : (isTablet ? 18.0 : 16.0);
    final iconSize = isLargeScreen ? 50.0 : (isTablet ? 45.0 : 40.0);
    final titleFontSize = isLargeScreen ? 14.0 : (isTablet ? 13.0 : 12.0);
    final valueFontSize = isLargeScreen ? 28.0 : (isTablet ? 26.0 : 24.0);

    return isLargeScreen
        ? Row(
      children: [
        Expanded(child: _buildSummaryCard('Services Actifs', '${servicesData.length}', Icons.business_center, Colors.blue[200]!, cardPadding, iconSize, titleFontSize, valueFontSize)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Nouveaux Projets', '$totalNouveaux', Icons.trending_up, Colors.green[200]!, cardPadding, iconSize, titleFontSize, valueFontSize)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Projets Terminés', '$totalTermines', Icons.check_circle, Colors.orange[200]!, cardPadding, iconSize, titleFontSize, valueFontSize)),
      ],
    )
        : Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Services Actifs', '${servicesData.length}', Icons.business_center, Colors.blue[200]!, cardPadding, iconSize, titleFontSize, valueFontSize)),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryCard('Nouveaux Projets', '$totalNouveaux', Icons.trending_up, Colors.green[200]!, cardPadding, iconSize, titleFontSize, valueFontSize)),
          ],
        ),
        const SizedBox(height: 8),
        _buildSummaryCard('Projets Terminés', '$totalTermines', Icons.check_circle, Colors.orange[200]!, cardPadding, iconSize, titleFontSize, valueFontSize),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, double padding, double iconSize, double titleFontSize, double valueFontSize) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
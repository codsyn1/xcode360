import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  Map<String, int> countryStats = {};
  Map<String, int> cityStats = {};
  int totalUsers = 0;
  int freeUsers = 0;
  int paidUsers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      countryStats.clear();
      cityStats.clear();
      totalUsers = 0;
      freeUsers = 0;
      paidUsers = 0;

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        totalUsers++;
        
        // Count free vs paid users
        String subscription = userData['subscription'] ?? 'free';
        if (subscription == 'free') {
          freeUsers++;
        } else {
          paidUsers++;
        }
        
        // Count countries
        String? country = userData['country'];
        if (country != null && country.isNotEmpty) {
          countryStats[country] = (countryStats[country] ?? 0) + 1;
        }
        
        // Count cities
        String? city = userData['city'];
        if (city != null && city.isNotEmpty) {
          cityStats[city] = (cityStats[city] ?? 0) + 1;
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showLocationStats(String title, Map<String, int> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top 10 locations
                        ...data.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value))
                          .take(10)
                          .map((entry) => _buildLocationItem(entry.key, entry.value)),
                        
                        const SizedBox(height: 20),
                        
                        // Chart
                        if (data.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: data.values.isNotEmpty 
                                  ? data.values.reduce((a, b) => a > b ? a : b).toDouble()
                                  : 10,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => Colors.blueGrey,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final location = data.keys.elementAt(group.x.toInt());
                                      return BarTooltipItem(
                                        '$location: ${group.y}',
                                        const TextStyle(color: Colors.white),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= data.length) return const Text('');
                                        final location = data.keys.elementAt(value.toInt());
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            location.length > 8 
                                              ? '${location.substring(0, 8)}...'
                                              : location,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: data.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value))
                                  .take(10)
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final index = entry.key;
                                    final data = entry.value;
                                    return BarChartGroupData(
                                      x: index.toDouble(),
                                      barRods: [
                                        BarChartRodData(
                                          toY: data.value.toDouble(),
                                          color: Colors.blue,
                                          width: 16,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(4),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationItem(String location, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              location,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Admin Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E3192),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserStats,
        child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Total Users Card
                  _buildStatsCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                    () {},
                  ),
                  
                  // Free Users Card
                  _buildStatsCard(
                    'Free Users',
                    freeUsers.toString(),
                    Icons.person_outline,
                    Colors.green,
                    () {},
                  ),
                  
                  // Countries Card
                  _buildStatsCard(
                    'Countries',
                    countryStats.length.toString(),
                    Icons.location_on,
                    Colors.orange,
                    () => _showLocationStats('Users by Country', countryStats),
                  ),
                  
                  // Cities Card
                  _buildStatsCard(
                    'Cities',
                    cityStats.length.toString(),
                    Icons.location_city,
                    Colors.purple,
                    () => _showLocationStats('Users by City', cityStats),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

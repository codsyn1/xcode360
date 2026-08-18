import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_payments_cubit.dart';
import 'admin_payments_state.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminPaymentsCubit()..init(),
      child: Scaffold(
        backgroundColor: const Color(0xFF232323),
        appBar: AppBar(
          title: const Text('Admin • Payments'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocConsumer<AdminPaymentsCubit, AdminPaymentsState>(
          listenWhen: (p, c) => p.error != c.error || p.message != c.message,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
              );
            } else if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!, style: const TextStyle(color: Colors.white))),
              );
            }
          },
          builder: (context, state) {
            if (state.loading && state.usersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics Cards Section
                  _buildAnalyticsCards(context, state),
                  const SizedBox(height: 20),
                  
                  // Search by PIN/email/username
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by PIN, email or username',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    ),
                    onChanged: (v) => context.read<AdminPaymentsCubit>().setSearchQuery(v),
                  ),
                  const SizedBox(height: 12),
                // Users section
                const Text('All Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (state.usersLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ))
                else if (state.users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No users found', style: TextStyle(color: Colors.white70)),
                  )
                else
                  ...((state.searchQuery.isEmpty) ? state.users : state.filteredUsers).map((u) => InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              String fmtDate(DateTime? d) => d == null ? '—' : d.toLocal().toString().split('.').first;
                              return AlertDialog(
                                backgroundColor: const Color(0xFF2C2C2C),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white12,
                                      backgroundImage: (u.profileImageUrl != null && u.profileImageUrl!.isNotEmpty)
                                          ? NetworkImage(u.profileImageUrl!)
                                          : null,
                                      child: (u.profileImageUrl == null || u.profileImageUrl!.isEmpty)
                                          ? const Icon(Icons.person, color: Colors.white70)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(u.name.isEmpty ? '(no name)' : u.name, style: const TextStyle(color: Colors.white))),
                                  ],
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _infoRow('Email', u.email),
                                      if (u.username.isNotEmpty) _infoRow('Username', '@${u.username}'),
                                      if (u.userPin.isNotEmpty) _infoRow('User PIN', u.userPin),
                                      _infoRow('Plan', u.plan),
                                      _infoRow('Signup Category', u.signupCategory ?? 'Not specified'),
                                      _infoRow('Pro Since', fmtDate(u.proSince)),
                                      _infoRow('Pro Active Until', fmtDate(u.proActiveUntil)),
                                      if (u.jobTitle != null && u.jobTitle!.isNotEmpty) _infoRow('Job Title', u.jobTitle!),
                                      if (u.country != null && u.country!.isNotEmpty) _infoRow('Country', u.country!),
                                      if (u.city != null && u.city!.isNotEmpty) _infoRow('City', u.city!),
                                      _infoRow('Created At', fmtDate(u.createdAt)),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.read<AdminPaymentsCubit>().deleteUser(u.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete User'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Card(
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u.name.isEmpty ? '(no name)' : u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(u.email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          if (u.username.isNotEmpty) Text('@${u.username}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                          if (u.userPin.isNotEmpty) Text('PIN: ${u.userPin}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: u.plan.toLowerCase() == 'pro' ? Colors.amber : Colors.white10,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(u.plan, style: TextStyle(color: u.plan.toLowerCase() == 'pro' ? Colors.black : Colors.white)),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete Icon
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: const Color(0xFF2C2C2C),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            title: const Text('Delete User', style: TextStyle(color: Colors.white)),
                                            content: Text('Are you sure you want to delete ${u.name.isEmpty ? "this user" : u.name}? This action cannot be undone.', style: const TextStyle(color: Colors.white70)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.read<AdminPaymentsCubit>().deleteUser(u.id);
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: state.processing ? null : () => context.read<AdminPaymentsCubit>().setUserFree(u.id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Colors.white24),
                                        ),
                                        child: Text(state.processing ? 'Please wait...' : 'Set Free'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: state.processing ? null : () => context.read<AdminPaymentsCubit>().setUserPro(u.id),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                                        child: Text(state.processing ? 'Please wait...' : 'Set Pro'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Helper to render a labeled info row in dialogs
Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: SelectableText(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// Analytics Cards Section
Widget _buildAnalyticsCards(BuildContext context, AdminPaymentsState state) {
  return Column(
    children: [
      // First row of cards
      Row(
        children: [
          // Total Users Card
          Expanded(
            child: _buildStatsCard(
              'Total Users',
              state.totalUsers.toString(),
              Icons.people,
              Colors.blue,
              () {},
            ),
          ),
          const SizedBox(width: 12),
          // Free Users Card
          Expanded(
            child: _buildStatsCard(
              'Free Users',
              state.freeUsers.toString(),
              Icons.person_outline,
              Colors.green,
              () {},
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Second row of cards
      Row(
        children: [
          // Pro Users Card
          Expanded(
            child: _buildStatsCard(
              'Pro Users',
              state.proUsers.toString(),
              Icons.star,
              Colors.amber,
              () {},
            ),
          ),
          const SizedBox(width: 12),
          // Countries Card
          Expanded(
            child: _buildStatsCard(
              'Countries',
              state.countryStats.length.toString(),
              Icons.location_on,
              Colors.orange,
              () => _showLocationStats(context, 'Users by Country', state.countryStats),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Third row of cards
      Row(
        children: [
          // Cities Card
          Expanded(
            child: _buildStatsCard(
              'Cities',
              state.cityStats.length.toString(),
              Icons.location_city,
              Colors.purple,
              () => _showLocationStats(context, 'Users by City', state.cityStats),
            ),
          ),
        ],
      ),
    ],
  );
}

// Individual Stats Card
Widget _buildStatsCard(
  String title,
  String value,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return Container(
    child: Card(
      color: const Color(0xFF1A1A1A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Location Stats Popup
void _showLocationStats(BuildContext context, String title, Map<String, int> data) {
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
                      ..._getTopLocations(data),
                      
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
                                      '$location: ${group.barRods.first.toY.round()}',
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
                              barGroups: _createBarGroups(data),
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

// Helper method to get top locations as widgets
List<Widget> _getTopLocations(Map<String, int> data) {
  final entries = data.entries.toList();
  entries.sort((a, b) => b.value.compareTo(a.value));
  final topEntries = entries.take(10).toList();
  
  return List.generate(topEntries.length, (index) {
    final entry = topEntries[index];
    return _buildLocationItem(entry.key, entry.value);
  });
}

// Helper method to create bar groups for chart
List<BarChartGroupData> _createBarGroups(Map<String, int> data) {
  final sortedEntries = data.entries.toList();
  sortedEntries.sort((a, b) => b.value.compareTo(a.value));
  final topEntries = sortedEntries.take(10).toList();
  
  return List.generate(topEntries.length, (index) {
    final entryData = topEntries[index];
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: entryData.value.toDouble(),
          color: Colors.blue,
          width: 16,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(4),
          ),
        ),
      ],
    );
  });
}

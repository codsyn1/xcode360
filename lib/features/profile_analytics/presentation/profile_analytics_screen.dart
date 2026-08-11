import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/profile_analytics_cubit.dart';
import 'bloc/profile_analytics_state.dart';
import '../data/profile_analytics_repository.dart';

class ProfileAnalyticsScreen extends StatefulWidget {
  final String? userId;
  const ProfileAnalyticsScreen({super.key, this.userId});

  @override
  State<ProfileAnalyticsScreen> createState() => _ProfileAnalyticsScreenState();
}

class _LevelsInfoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color color, String title, String subtitle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Levels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          row(Icons.emoji_events_outlined, Colors.grey, 'Level 1', 'New Member — fewer than 50 completed exchange projects.'),
          row(Icons.emoji_events, Colors.blueAccent, 'Level 2', 'Achieved at 50+ completed exchange projects.'),
          row(Icons.military_tech, Colors.amber, 'Level 3', 'Achieved at 500+ completed exchange projects.'),
          row(Icons.workspace_premium, Colors.purpleAccent, 'X360 Top Rated', 'Achieved at 1000+ completed exchange projects.'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final Color color;
  final String title;
  final int value;
  const _MiniStat({required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value.toString(), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RequestsBarChart extends StatelessWidget {
  final int pending;
  final int accepted;
  final int rejected;
  final int completed;
  const _RequestsBarChart({
    required this.pending,
    required this.accepted,
    required this.rejected,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final values = [pending, accepted, rejected, completed];
    final labels = ['Pending', 'Accepted', 'Rejected', 'Completed'];
    final colors = [
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.redAccent,
      Colors.tealAccent,
    ];
    final maxVal = (values.fold<int>(0, (p, e) => e > p ? e : p)).clamp(1, 999999);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Requests Overview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (i) {
              final h = 140.0 * (values[i] / maxVal);
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: colors[i].withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(values[i].toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(labels[i], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  final String imageUrl;
  final String badgeText;
  const _AvatarWithBadge({required this.imageUrl, required this.badgeText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white24,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 36) : null,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your Profile Analytics',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _LevelSummary extends StatelessWidget {
  final String levelLabel;
  final double levelProgress; // 0..1 from Bloc
  final String nextTargetLabel;
  const _LevelSummary({required this.levelLabel, required this.levelProgress, required this.nextTargetLabel});

  @override
  Widget build(BuildContext context) {
    // Use values from Bloc (repository computed)
    final progress = levelProgress.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(levelLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: Colors.blueAccent,
              backgroundColor: Colors.white10,
            ),
          ),
          const SizedBox(height: 8),
          // We keep completed count elsewhere in quick stats; here focus on level guidance
          const SizedBox(height: 4),
          Text(nextTargetLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProfileAnalyticsScreenState extends State<ProfileAnalyticsScreen> {
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Prefer explicitly provided userId
    String uid = widget.userId ?? '';
    if (uid.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString('userId') ?? '';
    }
    setState(() => _userId = uid);
    // After the widget builds with BlocProvider in the tree, trigger the load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (uid.isEmpty) return; // avoid loading with empty user id
      try {
        context.read<ProfileAnalyticsCubit>().load(uid);
      } catch (_) {
        // Provider may not be mounted yet on very first frame; it's okay, the next build will wire it.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ProfileAnalyticsCubit(ProfileAnalyticsRepository());
        final directId = widget.userId;
        if (directId != null && directId.isNotEmpty) {
          // Kick off immediately if caller passed userId
          cubit.load(directId);
        }
        return cubit;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF232323),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('Profile Analytics'),
        ),
        body: BlocBuilder<ProfileAnalyticsCubit, ProfileAnalyticsState>(
          builder: (context, state) {
            if (_userId.isEmpty || state.loading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (state.error != null) {
              return Center(
                child: Text(
                  'Error\n${state.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final data = state.data;
            if (data == null) {
              return const Center(
                child: Text('No analytics available.', style: TextStyle(color: Colors.white70)),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar with Level Badge
                  _AvatarWithBadge(imageUrl: data.profileImageUrl, badgeText: data.levelLabel),
                  const SizedBox(height: 16),

                  // Visits and Chats quick stats
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.remove_red_eye, title: 'Profile Visits', value: data.profileVisits.toString())),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(icon: Icons.chat, title: 'Total Chats', value: data.totalChats.toString())),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(icon: Icons.mark_chat_unread, title: 'Unread Messages', value: data.unreadMessages.toString()),

                  const SizedBox(height: 16),
                  // Requests breakdown
                  Text('Exchange Requests', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _MiniStat(color: Colors.blueAccent, title: 'Active Sent', value: data.requestsSent)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniStat(color: Colors.orangeAccent, title: 'Pending', value: data.requestsPending)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniStat(color: Colors.greenAccent, title: 'Accepted', value: data.requestsAccepted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _MiniStat(color: Colors.redAccent, title: 'Rejected', value: data.requestsRejected)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniStat(color: Colors.tealAccent, title: 'Completed', value: data.requestsCompleted)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // Simple bar chart for statuses
                  _RequestsBarChart(
                    pending: data.requestsPending,
                    accepted: data.requestsAccepted,
                    rejected: data.requestsRejected,
                    completed: data.requestsCompleted,
                  ),

                  const SizedBox(height: 16),
                  // Level summary
                  _LevelSummary(levelLabel: data.levelLabel, levelProgress: data.levelProgress, nextTargetLabel: data.nextTargetLabel),

                  const SizedBox(height: 16),
                  // Levels Info
                  _LevelsInfoList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/profile_analytics_cubit.dart';
import 'bloc/profile_analytics_state.dart';
import '../data/profile_analytics_repository.dart';
import '../../../../app_colors.dart';
import '../../../../theme_cubit.dart';

class ProfileAnalyticsScreen extends StatefulWidget {
  final String? userId;
  const ProfileAnalyticsScreen({super.key, this.userId});

  @override
  State<ProfileAnalyticsScreen> createState() => _ProfileAnalyticsScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets – each accepts isDarkMode so colors match the current theme
// ─────────────────────────────────────────────────────────────────────────────

class _LevelsInfoList extends StatelessWidget {
  final bool isDarkMode;
  const _LevelsInfoList({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color color, String title, String subtitle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppColors.textPrimary(isDarkMode),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                          fontSize: 12)),
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
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Levels',
              style: TextStyle(
                  color: AppColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          row(Icons.emoji_events_outlined, Colors.grey, 'Level 1',
              'New Member — fewer than 50 completed exchange projects.'),
          row(Icons.emoji_events, Colors.blueAccent, 'Level 2',
              'Achieved at 50+ completed exchange projects.'),
          row(Icons.military_tech, Colors.amber, 'Level 3',
              'Achieved at 500+ completed exchange projects.'),
          row(Icons.workspace_premium, Colors.purpleAccent, 'X360 Top Rated',
              'Achieved at 1000+ completed exchange projects.'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final Color color;
  final String title;
  final int value;
  final bool isDarkMode;
  const _MiniStat({
    required this.color,
    required this.title,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? color.withValues(alpha: 0.4)
              : AppColors.border(isDarkMode),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textSecondary(isDarkMode), fontSize: 12)),
          const SizedBox(height: 6),
          Text(value.toString(),
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
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
  final bool isDarkMode;
  const _RequestsBarChart({
    required this.pending,
    required this.accepted,
    required this.rejected,
    required this.completed,
    required this.isDarkMode,
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
    final maxVal =
        (values.fold<int>(0, (p, e) => e > p ? e : p)).clamp(1, 999999);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requests Overview',
              style: TextStyle(
                  color: AppColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.bold)),
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
                        color: colors[i].withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(values[i].toString(),
                        style: TextStyle(
                            color: AppColors.textSecondary(isDarkMode),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(labels[i],
                        style: TextStyle(
                            color: AppColors.textSecondary(isDarkMode),
                            fontSize: 11)),
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
  final bool isDarkMode;
  const _AvatarWithBadge({
    required this.imageUrl,
    required this.badgeText,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.cardSurface(isDarkMode),
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? Icon(Icons.person,
                  color: AppColors.textSecondary(isDarkMode), size: 36)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your Profile Analytics',
            style: TextStyle(
                color: AppColors.textPrimary(isDarkMode),
                fontSize: 18,
                fontWeight: FontWeight.bold),
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
                  const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelSummary extends StatelessWidget {
  final String levelLabel;
  final double levelProgress;
  final String nextTargetLabel;
  final bool isDarkMode;
  const _LevelSummary({
    required this.levelLabel,
    required this.levelProgress,
    required this.nextTargetLabel,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final progress = levelProgress.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(levelLabel,
              style: TextStyle(
                  color: AppColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: Colors.blueAccent,
              backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
            ),
          ),
          const SizedBox(height: 12),
          Text(nextTargetLabel,
              style: TextStyle(
                  color: AppColors.textSecondary(isDarkMode), fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDarkMode;
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child:
                Icon(icon, color: AppColors.textPrimary(isDarkMode), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(color: AppColors.textSecondary(isDarkMode))),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: AppColors.textPrimary(isDarkMode),
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen state
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileAnalyticsScreenState extends State<ProfileAnalyticsScreen> {
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String uid = widget.userId ?? '';
    if (uid.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString('userId') ?? '';
    }
    setState(() => _userId = uid);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (uid.isEmpty) return;
      try {
        context.read<ProfileAnalyticsCubit>().load(uid);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read live theme — reacts immediately when user toggles Dark/Light Mode
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return BlocProvider(
      create: (_) {
        final cubit = ProfileAnalyticsCubit(ProfileAnalyticsRepository());
        final directId = widget.userId;
        if (directId != null && directId.isNotEmpty) {
          cubit.load(directId);
        }
        return cubit;
      },
      child: Scaffold(
        // ✅ No longer hardcoded — respects ThemeCubit
        backgroundColor: AppColors.background(isDarkMode),
        appBar: AppBar(
          backgroundColor: AppColors.background(isDarkMode),
          elevation: 0,
          foregroundColor: AppColors.textPrimary(isDarkMode),
          // ✅ Back button always present
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: AppColors.textPrimary(isDarkMode)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Profile Analytics',
            style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
          ),
        ),
        body: BlocBuilder<ProfileAnalyticsCubit, ProfileAnalyticsState>(
          builder: (context, state) {
            if (_userId.isEmpty || state.loading) {
              return Center(
                child: CircularProgressIndicator(
                    color: isDarkMode ? Colors.white : Colors.black54),
              );
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
              return Center(
                child: Text('No analytics available.',
                    style: TextStyle(
                        color: AppColors.textSecondary(isDarkMode))),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AvatarWithBadge(
                    imageUrl: data.profileImageUrl,
                    badgeText: data.levelLabel,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),

                  // Quick stat cards
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              icon: Icons.remove_red_eye,
                              title: 'Profile Visits',
                              value: data.profileVisits.toString(),
                              isDarkMode: isDarkMode)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              icon: Icons.chat,
                              title: 'Total Chats',
                              value: data.totalChats.toString(),
                              isDarkMode: isDarkMode)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                      icon: Icons.mark_chat_unread,
                      title: 'Unread Messages',
                      value: data.unreadMessages.toString(),
                      isDarkMode: isDarkMode),

                  const SizedBox(height: 16),
                  Text('Exchange Requests',
                      style: TextStyle(
                          color: AppColors.textPrimary(isDarkMode),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _MiniStat(
                              color: Colors.blueAccent,
                              title: 'Active Sent',
                              value: data.requestsSent,
                              isDarkMode: isDarkMode)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _MiniStat(
                              color: Colors.orangeAccent,
                              title: 'Pending',
                              value: data.requestsPending,
                              isDarkMode: isDarkMode)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _MiniStat(
                              color: Colors.greenAccent,
                              title: 'Accepted',
                              value: data.requestsAccepted,
                              isDarkMode: isDarkMode)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _MiniStat(
                              color: Colors.redAccent,
                              title: 'Rejected',
                              value: data.requestsRejected,
                              isDarkMode: isDarkMode)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _MiniStat(
                              color: Colors.tealAccent,
                              title: 'Completed',
                              value: data.requestsCompleted,
                              isDarkMode: isDarkMode)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _RequestsBarChart(
                    pending: data.requestsPending,
                    accepted: data.requestsAccepted,
                    rejected: data.requestsRejected,
                    completed: data.requestsCompleted,
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 16),
                  _LevelSummary(
                    levelLabel: data.levelLabel,
                    levelProgress: data.levelProgress,
                    nextTargetLabel: data.nextTargetLabel,
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 16),
                  _LevelsInfoList(isDarkMode: isDarkMode),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

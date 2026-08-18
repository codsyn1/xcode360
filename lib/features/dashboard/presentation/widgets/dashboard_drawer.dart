import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../profile_analytics/presentation/profile_analytics_screen.dart';
import '../../../admin/payments/admin_payments_screen.dart';
import '../../../admin/support/admin_support_screen.dart';
import '../../../../features/profile_analytics/presentation/bloc/analytics_access_cubit.dart';
import '../../bloc/dashboard_cubit.dart';
import '../../bloc/dashboard_state.dart';
import '../../../../exchange_projects_screen.dart';
import '../../../../users_profiles_screen.dart';
import '../../../../settings_screen.dart';
import '../../../../features/admin/slider/slider_admin_screen.dart';
import '../../../../features/admin/popup/popup_admin_screen.dart';
import '../../../../features/admin/agency_pro/agency_pro_admin_screen.dart';

class DashboardDrawer extends StatelessWidget {
  final String userId;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  const DashboardDrawer({
    super.key,
    required this.userId,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) => DashboardCubit()..init(userId, selectedIndex: selectedIndex),
      child: Container(
        color: const Color(0xFF232323),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white24,
                              backgroundImage: state.userImageUrl != null && state.userImageUrl!.isNotEmpty
                                  ? NetworkImage(state.userImageUrl!)
                                  : null,
                              child: (state.userImageUrl == null || state.userImageUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 32, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.userName ?? 'User',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  if (state.userJobTitle != null && state.userJobTitle!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        state.userJobTitle!,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.userPlan == 'Pro' ? 'Pro Member' : 'Free Member',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                if (!state.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white),
                    title: const Text('Home', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      onSelectIndex(0);
                    },
                  ),
                if (!state.isAdmin) const Divider(color: Colors.white24, height: 1),
                if (!state.isAdmin)
                  Tooltip(
                    message: (state.userPlan?.toLowerCase() == 'pro') ? 'View Profile Analytics' : 'Pro only feature',
                    child: Opacity(
                      opacity: (state.userPlan?.toLowerCase() == 'pro') ? 1.0 : 0.55,
                      child: ListTile(
                        leading: const Icon(Icons.analytics, color: Colors.white),
                        title: Row(
                          children: [
                            const Text('Profile Analytics', style: TextStyle(color: Colors.white)),
                            if ((state.userPlan?.toLowerCase() ?? 'free') != 'pro') ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.lock, color: Colors.white54, size: 16),
                            ],
                          ],
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          final access = AnalyticsAccessCubit();
                          final allowed = await access.check(userId);
                          if (allowed) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ProfileAnalyticsScreen(userId: userId)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile Analytics is available for Pro members only.')),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                if (!state.isAdmin) const Divider(color: Colors.white24, height: 1),
                if (!state.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white),
                    title: const Text('Settings', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                if (!state.isAdmin) const Divider(color: Colors.white24, height: 1),
                if (!state.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: const Text('Profile', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      onSelectIndex(4);
                    },
                  ),
                if (!state.isAdmin) const Divider(color: Colors.white24, height: 1),
                if (!state.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.card_membership, color: Colors.white),
                    title: const Text('Subscription', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      onSelectIndex(1);
                    },
                  ),
                if (!state.isAdmin) const Divider(color: Colors.white24, height: 1),
                if (!state.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.groups, color: Colors.white),
                    title: const Text('Communities', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      onSelectIndex(3);
                    },
                  ),
                if (state.isAdmin) ...[
                  const Divider(color: Colors.white24, height: 1),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.shield, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.payments_rounded, color: Colors.white),
                    title: const Text('Payments', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminPaymentsScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.support_agent, color: Colors.white),
                    title: const Text('Support', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminSupportScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.slideshow, color: Colors.white),
                    title: const Text('Slider Images', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SliderAdminScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.workspace_premium, color: Colors.white),
                    title: const Text('Agency Pro', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AgencyProAdminScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.image, color: Colors.white),
                    title: const Text('Popup Image', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PopupAdminScreen()),
                      );
                    },
                  ),
                ],
                if (!state.isAdmin) const Divider(color: Colors.white24, height: 1),
                if (!state.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.swap_horiz, color: Colors.white),
                    title: const Text('Exchange Projects', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ExchangeProjectsScreen(currentUserId: userId)),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

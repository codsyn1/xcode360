import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'features/subscription/presentation/bloc/subscription_cubit.dart';
import 'features/subscription/presentation/bloc/subscription_state.dart';
import 'features/subscription/presentation/payment/payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final String userId;
  const SubscriptionScreen({super.key, required this.userId});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return BlocProvider(
      create: (_) => SubscriptionCubit()..init(widget.userId),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode ? const [Color(0xFF232323), Color(0xFF181818)] : const [Color(0xFFF2F2F7), Color(0xFFE8E8E8)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: BlocConsumer<SubscriptionCubit, SubscriptionState>(
                  listenWhen: (p, c) => p.error != c.error || p.message != c.message,
                  listener: (context, state) {
                    if (state.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error!, style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    } else if (state.message != null) {
                      if (state.message == 'GO_DASHBOARD') {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => DashboardScreen(userId: widget.userId)),
                          (route) => false,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message!, style: const TextStyle(color: Colors.white))),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Fallback to ensure content always shows
                    final plan = state.plan.isNotEmpty ? state.plan : 'Free';
                    final isPro = plan.toLowerCase() == 'pro';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current Plan + Upgrade/Downgrade
                        Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  isPro ? Icons.verified : Icons.workspace_premium_outlined,
                                  color: isPro ? Colors.amber : Colors.white70,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Your Current Plan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        plan,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isPro)
                                  SizedBox(
                                    width: 120,
                                    child: ElevatedButton.icon(
                                      onPressed: state.upgrading
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => PaymentDetailsScreen(userId: widget.userId),
                                                ),
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        minimumSize: const Size(120, 32),
                                        maximumSize: const Size(120, 40),
                                      ),
                                      icon: state.upgrading
                                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.upgrade, size: 16),
                                      label: Text(
                                        state.upgrading ? 'Upgrading...' : 'Upgrade',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Pro details card (visible only if Pro)
                        if (isPro)
                          Card(
                            color: const Color(0xFF1E1E1E),
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pro Benefits', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(height: 8),
                                  _Bullet(text: 'Verified badge on your profile'),
                                  _Bullet(text: 'Featured profile listing for better discovery'),
                                  _Bullet(text: 'Profile view analytics'),
                                  _Bullet(text: 'Online availability status'),
                                  _Bullet(text: 'Unlimited project exchanges'),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Features comparison table (existing)
                        const _FeaturesTable(),

                        const SizedBox(height: 20),

                        // Continue with Free button (only if plan is Free AND first time after signup)
                        if (!isPro && !state.subscriptionCompleted)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.upgrading ? null : () => context.read<SubscriptionCubit>().proceedWithFree(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white12,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(state.upgrading ? 'Please wait...' : 'Continue with Free'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NextScreen extends StatelessWidget {
  final String plan;
  const NextScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Next Screen'),
      ),
      body: Center(
        child: Text(
          'You selected $plan Plan',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _FeaturesTable extends StatelessWidget {
  final List<Map<String, dynamic>> features = const [
    {'name': 'Project Exchanges', 'free': '5', 'pro': 'Unlimited'},
    {'name': 'Skill Tags', 'free': true, 'pro': true},
    {'name': 'Priority Chat Visibility', 'free': true, 'pro': true},
    {'name': 'Advanced Exchange Form', 'free': true, 'pro': true},
    {'name': 'Skill & Country Filters', 'free': true, 'pro': true},
    {'name': 'Exchange Status Tracking', 'free': true, 'pro': true},
    {'name': 'Dev Rooms Access (Communities)', 'free': true, 'pro': true},
    {'name': 'Dedicated Support', 'free': true, 'pro': true},
    {'name': 'Verified Badge', 'free': false, 'pro': true},
    {'name': 'Featured Profile Listing', 'free': false, 'pro': true},
    {'name': 'Profile View Analytics', 'free': false, 'pro': true},
    {'name': 'Online Availability Status', 'free': false, 'pro': true},
  ];

  const _FeaturesTable();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Features', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: Text('Free Plan', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Expanded(
                  child: Text('Pro Plan', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 18),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          feature['name'],
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: feature['name'] == 'Project Exchanges'
                              ? Text(
                                  feature['free'].toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : Icon(
                                  feature['free'] == true ? Icons.check_circle : Icons.cancel,
                                  color: feature['free'] == true ? Colors.greenAccent : Colors.redAccent,
                                  size: 20,
                                ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: feature['name'] == 'Project Exchanges'
                              ? Text(
                                  feature['pro'].toString(),
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                )
                              : Icon(
                                  feature['pro'] == true ? Icons.check_circle : Icons.cancel,
                                  color: feature['pro'] == true ? Colors.greenAccent : Colors.redAccent,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}

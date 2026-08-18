import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/users_repository.dart';
import '../bloc/users_cubit.dart';
import '../bloc/users_state.dart';
import '../../../../profile_screen.dart';

class UsersHorizontalSlider extends StatelessWidget {
  final String userId;
  final String? subcategory;
  final EdgeInsetsGeometry padding;
  final int maxItems;
  const UsersHorizontalSlider({super.key, required this.userId, this.subcategory, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8), this.maxItems = 12});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(UsersRepository())..start(subcategory: subcategory),
      child: _UsersHorizontalList(userId: userId, padding: padding, maxItems: maxItems),
    );
  }
}

class _UsersHorizontalList extends StatelessWidget {
  final String userId;
  final EdgeInsetsGeometry padding;
  final int maxItems;
  const _UsersHorizontalList({required this.userId, required this.padding, required this.maxItems});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        if (state.loading) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: Colors.white)));
        }
        if (state.error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Failed to load users: ${state.error}', style: const TextStyle(color: Colors.redAccent)),
          );
        }
        final users = state.users.take(maxItems).toList();
        if (users.isEmpty) {
          return const SizedBox.shrink();
        }
        final screenWidth = MediaQuery.of(context).size.width;
        final height = screenWidth > 700 ? 300.0 : 260.0;
        return SizedBox(
          height: height,
          child: ListView.separated(
            padding: padding,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final data = users[index];
              return _UserCardMini(data: data, onTap: () {
                final id = (data['id'] ?? '').toString();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: id)));
              });
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: users.length,
          ),
        );
      },
    );
  }
}

class _UserCardMini extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _UserCardMini({required this.data, required this.onTap});

  String _computeLevelLabel(dynamic raw) {
    int normalize(dynamic r) {
      if (r == null) return 0;
      if (r is int) return r;
      final s = r.toString();
      final digits = RegExp(r'\d+').allMatches(s).map((m) => m.group(0)!).join();
      if (digits.isEmpty) return 0;
      return int.tryParse(digits) ?? 0;
    }
    final px = normalize(raw);
    if (px >= 1000) return 'X360 Top Rated';
    if (px >= 500) return 'Level 3';
    if (px >= 50) return 'Level 2';
    return 'Level 1';
  }

  @override
  Widget build(BuildContext context) {
    final name = (data['fullName'] ?? data['name'] ?? 'User').toString();
    final coverImageUrl = (data['coverImageUrl'] ?? '').toString();
    final jobTitle = (data['jobTitle'] ?? '').toString();
    final online = (data['onlineStatus'] ?? false) == true;
    final country = (data['country'] ?? '').toString();
    final city = (data['city'] ?? '').toString();
    final plan = (data['plan'] ?? '').toString();
    final isPro = plan.toLowerCase() == 'pro';
    final levelLabel = _computeLevelLabel(data['projectsExchanged']);

    final normalizedCoverUrl = (coverImageUrl.trim().toLowerCase() == 'null') ? '' : coverImageUrl.trim();

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.biggest.width == 0 ? MediaQuery.of(context).size.width * 0.55 : constraints.biggest.width;
          final cardWidth = w.clamp(220.0, 320.0);
          final coverHeight = (cardWidth * 0.48).clamp(90.0, 150.0);
          return SizedBox(
            width: cardWidth,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 6,
              clipBehavior: Clip.none,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    height: coverHeight,
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: (normalizedCoverUrl.isNotEmpty)
                              ? CachedNetworkImage(imageUrl: normalizedCoverUrl, fit: BoxFit.cover)
                              : Container(color: Colors.grey[300]),
                        ),
                        if (isPro && online)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Level pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]),
                            child: Text(levelLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                          const SizedBox(height: 10),
                          // Name + pro badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: cardWidth * 0.095, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPro) const SizedBox(width: 6),
                              if (isPro) const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 18),
                            ],
                          ),
                          if (jobTitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(jobTitle, style: TextStyle(fontSize: cardWidth * 0.07, color: Colors.black54, fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (country.isNotEmpty) ...[
                                const Text('🇵🇰', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Flexible(child: Text(country, style: const TextStyle(color: Colors.blueGrey, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                              if (city.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                                const SizedBox(width: 4),
                                Flexible(child: Text(city, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text((data['bio'] ?? '').toString(), style: const TextStyle(color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: OutlinedButton(
                              onPressed: onTap,
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueAccent), foregroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('View Profile'),
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
      ),
    );
  }
}

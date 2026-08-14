import 'package:flutter/material.dart';
import 'theme_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'subscription_screen.dart';
import 'chat_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'community_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/users/presentation/bloc/users_cubit.dart';
import 'features/users/presentation/bloc/users_state.dart';
import 'features/users/data/users_repository.dart';
import 'features/users/presentation/bloc/users_ui_config_cubit.dart';
import 'features/users/presentation/bloc/users_filter_cubit.dart';
import 'features/users/presentation/bloc/users_card_ui_cubit.dart';
import 'features/profile_analytics/presentation/bloc/profile_analytics_cubit.dart';
import 'features/profile_analytics/presentation/bloc/profile_analytics_state.dart';
import 'features/profile_analytics/data/profile_analytics_repository.dart';

class UsersProfilesScreen extends StatefulWidget {
  final String? subcategory;
  const UsersProfilesScreen({Key? key, this.subcategory}) : super(key: key);

  @override
  State<UsersProfilesScreen> createState() => _UsersProfilesScreenState();
}

class _UsersProfilesScreenState extends State<UsersProfilesScreen> {
  String _searchQuery = '';
  int _selectedIndex = 0;
  String? _selectedCountry;
  int? _selectedRating;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UsersUIConfigCubit()),
        BlocProvider(create: (_) => UsersFilterCubit()),
        BlocProvider(create: (_) => UsersCardUICubit()),
        BlocProvider(create: (_) => UsersCubit(UsersRepository())..start(subcategory: widget.subcategory)),
      ],
      child: Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.search, color: Colors.white70, size: 22),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    style: const TextStyle(color: Colors.white, height: 1.0),
                    cursorColor: Colors.white,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              onPressed: () async {
              final snapshot = await FirebaseFirestore.instance.collection('users').get();
              final allCountries = snapshot.docs
                  .map((doc) => (doc.data()['country'] ?? '').toString())
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList();
              allCountries.sort();
              if (!mounted) return;
              final usersFilterCubit = ctx.read<UsersFilterCubit>();
              showDialog(
                context: ctx,
                useRootNavigator: false,
                builder: (dialogCtx) {
                  return BlocBuilder<UsersFilterCubit, UsersFilterState>(
                    bloc: usersFilterCubit,
                    builder: (context, filterState) {
                      final current = filterState.country;
                      final currentOnlineOnly = filterState.onlineOnly;
                      final currentLevel = filterState.level;
                      return AlertDialog(
                        backgroundColor: const Color(0xFF232323),
                        title: const Text('Filters', style: TextStyle(color: Colors.white)),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Country', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...allCountries.map((c) => ListTile(
                                          title: Text(c, style: const TextStyle(color: Colors.white)),
                                          leading: const Icon(Icons.flag, color: Colors.white70),
                                          onTap: () {
                                            usersFilterCubit.setCountry(c);
                                            Navigator.of(dialogCtx).pop();
                                          },
                                          selected: current == c,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                ),
                                CheckboxListTile(
                                  value: currentOnlineOnly,
                                  onChanged: (val) {
                                    usersFilterCubit.setOnlineOnly(val ?? false);
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: const Text('Online', style: TextStyle(color: Colors.white)),
                                  activeColor: Colors.green,
                                  checkColor: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Level', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...['Level 1','Level 2','Level 3','X360 Top Rated'].map((lvl) => ListTile(
                                          title: Text(lvl, style: const TextStyle(color: Colors.white)),
                                          leading: const Icon(Icons.workspace_premium, color: Colors.white70),
                                          onTap: () {
                                            usersFilterCubit.setLevel(lvl);
                                            Navigator.of(dialogCtx).pop();
                                          },
                                          selected: currentLevel == lvl,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            tooltip: 'Filter',
          ),
          ),
        ],
      ),
      body: BlocBuilder<UsersFilterCubit, UsersFilterState>(
          builder: (context, filterState) {
            return BlocBuilder<UsersCubit, UsersState>(
                builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (state.error != null) {
              return Center(
                child: Text(
                  'Error: \n${state.error}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final docs = state.users;
            // Filter users by country, level, search query, and exclude current user
            final filteredDocs = docs.where((data) {
              final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
              final country = (data['country'] ?? '').toString();
              final id = (data['id'] ?? '').toString();
              // Robust parse for projectsExchanged: handle ints, numeric strings, strings with commas or plus signs (e.g., "1,200" or "60+")
              int normalizeProjectsExchanged(dynamic raw) {
                if (raw == null) return 0;
                if (raw is int) return raw;
                final s = raw.toString();
                final digits = RegExp(r'\d+').allMatches(s).map((m) => m.group(0)!).join();
                if (digits.isEmpty) return 0;
                return int.tryParse(digits) ?? 0;
              }
              final int projectsExchanged = normalizeProjectsExchanged(data['projectsExchanged']);
              String computedLevelLabel = 'Level 1';
              if (projectsExchanged >= 1000) {
                computedLevelLabel = 'X360 Top Rated';
              } else if (projectsExchanged >= 500) {
                computedLevelLabel = 'Level 3';
              } else if (projectsExchanged >= 50) {
                computedLevelLabel = 'Level 2';
              }
              // Country filter: treat null/empty as All; compare case-insensitively and trimmed
              final String selectedCountry = (filterState.country ?? '').trim();
              final matchesCountry = selectedCountry.isEmpty || selectedCountry.toLowerCase() == 'all' ||
                  country.trim().toLowerCase() == selectedCountry.toLowerCase();
              // Level filter: treat null/empty/'All' as All; compare case-insensitively
              final String selectedLevel = (filterState.level ?? '').trim();
              final matchesLevel = selectedLevel.isEmpty || selectedLevel.toLowerCase() == 'all' ||
                  computedLevelLabel.trim().toLowerCase() == selectedLevel.toLowerCase();
              final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
              final isNotCurrentUser = _currentUserId != null && _currentUserId!.isNotEmpty ? id != _currentUserId : true;
              final matchesOnline = !filterState.onlineOnly || ((data['onlineStatus'] ?? false) == true);
              return matchesCountry && matchesLevel && matchesSearch && isNotCurrentUser && matchesOnline;
            }).toList();
            if (filteredDocs.isEmpty) {
              return const Center(child: Text('No users found.', style: TextStyle(color: Colors.white70)));
            }
            // Decide layout via UI config cubit
            final double screenWidth = MediaQuery.of(context).size.width;
            // Guard against emitting during build repeatedly causing rebuild loops
            final uiConfigState = context.read<UsersUIConfigCubit>().state;
            if (uiConfigState.screenWidth != screenWidth) {
              context.read<UsersUIConfigCubit>().setScreenWidth(screenWidth);
            }
            final uiCardState = context.read<UsersCardUICubit>().state;
            if (uiCardState.screenWidth != screenWidth) {
              context.read<UsersCardUICubit>().setScreenWidth(screenWidth);
            }

            return BlocBuilder<UsersUIConfigCubit, UsersUIConfigState>(
              builder: (context, ui) {
                final uiCard = context.read<UsersCardUICubit>().state;
                if (ui.isHorizontal) {
                  // Horizontal list for mobile/tablet
                  return SizedBox(
                    height: ui.listHeight,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final data = filteredDocs[index] as Map<String, dynamic>;
                        final userId = (data['id'] ?? '').toString();
                        final name = (data['fullName'] ?? data['name'] ?? 'User').toString();
                        final imageUrl = (data['profileImageUrl'] ?? '').toString();
                        final coverImageUrl = (data['coverImageUrl'] ?? '').toString();
                        final jobTitle = (data['jobTitle'] ?? '').toString();
                        final country = (data['country'] ?? '').toString();
                        final plan = (data['plan'] ?? '').toString();
                        final bool isPro = plan.toLowerCase() == 'pro';
                        final bool online = (data['onlineStatus'] ?? false) == true;
                        final String cardLevelLabel = computeLevelLabelFromProjects(data['projectsExchanged']);
                        return SizedBox(
                          width: ui.cardWidth,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = constraints.maxWidth;
                              final uiCardLocal = context.read<UsersCardUICubit>().state;
                              final double coverHeight = (itemWidth * uiCardLocal.horizontalCoverHeightFactor).clamp(56.0, 140.0) as double;
                              final double avatarSize = (itemWidth * uiCardLocal.horizontalAvatarSizeFactor).clamp(54.0, 110.0) as double;
                              final String normalizedCoverUrl = (coverImageUrl.trim().toLowerCase() == 'null') ? '' : coverImageUrl.trim();
                              final String normalizedAvatarUrl = (imageUrl.trim().toLowerCase() == 'null') ? '' : imageUrl.trim();
                              return Card(
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
                                                ? CachedNetworkImage(
                                                    imageUrl: normalizedCoverUrl,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                                                    errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
                                                  )
                                                : Container(color: Colors.grey[300]),
                                          ),
                                          if (isPro && uiCard.showOnlinePill && online)
                                            (uiCard.onlinePillAtRight
                                                ? Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 8.0),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.9),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: const [
                                                            Icon(Icons.circle, size: 8, color: Colors.green),
                                                            SizedBox(width: 6),
                                                            Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : (uiCard.onlinePillAtCenterLeft
                                                    ? Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(left: 8.0),
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.9),
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: const [
                                                                Icon(Icons.circle, size: 8, color: Colors.green),
                                                                SizedBox(width: 6),
                                                                Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Positioned(
                                                        left: 8,
                                                        top: 8,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withOpacity(0.9),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: const [
                                                              Icon(Icons.circle, size: 8, color: Colors.green),
                                                              SizedBox(width: 6),
                                                              Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                            ],
                                                          ),
                                                        ),
                                                      ))),
                                        ],
                                      ),
                                    ),
                                    // Online status just below cover image
                                    if (online)
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(itemWidth * 0.05, 8, itemWidth * 0.05, 0),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1DB954), // Spotify-like green
                                              borderRadius: BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.12),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.circle, size: 8, color: Colors.white),
                                                SizedBox(width: 6),
                                                Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    Transform.translate(
                                      offset: Offset(0, -avatarSize * 0.45),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            height: avatarSize,
                                            width: avatarSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.grey[400]!, width: 4),
                                              color: Colors.white,
                                            ),
                                            child: ClipOval(
                                              child: (normalizedAvatarUrl.isNotEmpty)
                                                  ? CachedNetworkImage(
                                                      imageUrl: normalizedAvatarUrl,
                                                      width: avatarSize - 12,
                                                      height: avatarSize - 12,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => Container(
                                                        width: avatarSize - 12,
                                                        height: avatarSize - 12,
                                                        color: Colors.white,
                                                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                      ),
                                                      errorWidget: (context, url, error) => Container(
                                                        width: avatarSize - 12,
                                                        height: avatarSize - 12,
                                                        color: Colors.white,
                                                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Container(
                                                      width: avatarSize - 12,
                                                      height: avatarSize - 12,
                                                      color: Colors.white,
                                                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            right: -6,
                                            bottom: -6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
                                                ],
                                              ),
                                              child: Text(
                                                cardLevelLabel,
                                                style: TextStyle(color: Colors.white, fontSize: (avatarSize * 0.18).clamp(9.0, 12.0)),
                                              ),
                                            ),
                                          ),
                                          // remove avatar online dot when Fiverr-style pill is enabled
                                          if (isPro && !uiCard.proBadgeAboveButtonLeft)
                                            const SizedBox.shrink(),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: itemWidth * 0.05),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    name,
                                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: itemWidth * 0.095, color: Colors.black87),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    softWrap: false,
                                                  ),
                                                ),
                                                if (isPro) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 18),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (jobTitle.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 0.0),
                                                child: Text(
                                                  jobTitle,
                                                  style: TextStyle(fontSize: itemWidth * 0.07, color: Colors.black54, fontWeight: FontWeight.w400),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            // Country + City placed close to profession
                                            Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  if (country.isNotEmpty) ...[
                                                    Text(
                                                      countryCodeToEmojiStatic(country) + ' ',
                                                      style: const TextStyle(fontSize: 15),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        country,
                                                        style: const TextStyle(
                                                          color: Colors.blueGrey,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                  if ((data['city'] ?? '').toString().isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        (data['city'] ?? '').toString(),
                                                        style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            const SizedBox(height: 4),
                                            if (data['projectsExchanged'] != null) ...[
                                              const Icon(Icons.swap_horiz, size: 14, color: Colors.blue),
                                              const SizedBox(width: 3),
                                              Text(
                                                data['projectsExchanged'].toString(),
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            
                                            // Country + City already shown above, keep bio next
                                            // Optional bio in horizontal layout for responsiveness
                                            if ((data['bio'] ?? '').toString().isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                (data['bio'] ?? '').toString(),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 13.5,
                                                  height: 1.25,
                                                ),
                                                maxLines: uiCard.maxBioLines,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            const Spacer(),
                                            const SizedBox(height: 6),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox.shrink(),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: itemWidth * 0.05, vertical: itemWidth * 0.02),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue[800],
                                            side: BorderSide(color: Colors.blue[800]!, width: 1.5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            padding: EdgeInsets.symmetric(vertical: itemWidth * 0.028),
                                          ),
                                          onPressed: () async {
                                            try {
                                              final prefs = await SharedPreferences.getInstance();
                                              final viewerId = prefs.getString('userId') ?? '';
                                              final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
                                              await docRef.collection('visits').add({
                                                'viewerId': viewerId,
                                                'timestamp': FieldValue.serverTimestamp(),
                                              });
                                              await docRef.set({'profileVisits': FieldValue.increment(1)}, SetOptions(merge: true));
                                            } catch (_) {}
                                            if (!context.mounted) return;
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => ProfileScreen(userId: userId),
                                              ),
                                            );
                                          },
                                          child: Text('View Profile', style: TextStyle(fontSize: itemWidth * 0.065, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                }

                // Vertical list for other cases (default with current UI config)
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index] as Map<String, dynamic>;
                    final userId = (data['id'] ?? '').toString();
                    final name = (data['fullName'] ?? data['name'] ?? 'User').toString();
                    final imageUrl = (data['profileImageUrl'] ?? '').toString();
                    final coverImageUrl = (data['coverImageUrl'] ?? '').toString();
                    final jobTitle = (data['jobTitle'] ?? '').toString();
                    final bio = (data['bio'] ?? '').toString();
                    final country = (data['country'] ?? '').toString();
                    final plan = (data['plan'] ?? '').toString();
                    final isPro = plan.toLowerCase() == 'pro';
                    final bool online = (data['onlineStatus'] ?? false) == true;
                    final String cardLevelLabel = computeLevelLabelFromProjects(data['projectsExchanged']);
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth;
                        final uiCardLocal = context.read<UsersCardUICubit>().state;
                        final double coverHeight = (itemWidth * uiCardLocal.verticalCoverHeightFactor).clamp(56.0, 140.0) as double;
                        final double avatarSize = (itemWidth * uiCardLocal.verticalAvatarSizeFactor).clamp(54.0, 110.0) as double;
                        final String normalizedCoverUrl = (coverImageUrl.trim().toLowerCase() == 'null') ? '' : coverImageUrl.trim();
                        final String normalizedAvatarUrl = (imageUrl.trim().toLowerCase() == 'null') ? '' : imageUrl.trim();
                        final double itemHeight = ((itemWidth * 0.9)).clamp(uiCardLocal.verticalMinHeight, uiCardLocal.verticalMaxHeight) as double;
                        // Calculate minimum required height to prevent overflow
                        final double minRequiredHeight = coverHeight + (avatarSize * 0.6) + 200; // Increased to 200 for content area
                        final double finalHeight = itemHeight > minRequiredHeight ? itemHeight : minRequiredHeight;
                        return SizedBox(
                          height: finalHeight,
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 6,
                            clipBehavior: Clip.none,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Cover image area
                                SizedBox(
                                  height: coverHeight,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fill(
                                        child: (normalizedCoverUrl.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: normalizedCoverUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(color: Colors.grey[300]),
                                                errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
                                              )
                                            : Container(color: Colors.grey[300]),
                                      ),
                                      if (false && context.read<UsersCardUICubit>().state.showOnlinePill && online)
                                        (uiCardLocal.onlinePillAtRight
                                            ? Align(
                                                alignment: Alignment.centerRight,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(right: 8.0),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.9),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.circle, size: 8, color: Colors.green),
                                                        SizedBox(width: 6),
                                                        Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : (uiCardLocal.onlinePillAtCenterLeft
                                                ? Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(left: 8.0),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.9),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: const [
                                                            Icon(Icons.circle, size: 8, color: Colors.green),
                                                            SizedBox(width: 6),
                                                            Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Positioned(
                                                    left: 8,
                                                    top: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.9),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: const [
                                                          Icon(Icons.circle, size: 8, color: Colors.green),
                                                          SizedBox(width: 6),
                                                          Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                        ],
                                                      ),
                                                    ),
                                                  ))),
                                      // Avatar overlapping bottom-left
                                      Positioned(
                                        left: 16,
                                        bottom: -avatarSize * 0.6,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              height: avatarSize,
                                              width: avatarSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 3),
                                                color: Colors.white,
                                              ),
                                              child: ClipOval(
                                                child: (normalizedAvatarUrl.isNotEmpty)
                                                    ? CachedNetworkImage(
                                                        imageUrl: normalizedAvatarUrl,
                                                        width: avatarSize - 12,
                                                        height: avatarSize - 12,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => Container(
                                                          width: avatarSize - 12,
                                                          height: avatarSize - 12,
                                                          color: Colors.white,
                                                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                        ),
                                                        errorWidget: (context, url, error) => Container(
                                                          width: avatarSize - 12,
                                                          height: avatarSize - 12,
                                                          color: Colors.white,
                                                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: avatarSize - 12,
                                                        height: avatarSize - 12,
                                                        color: Colors.white,
                                                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                                      ),
                                              ),
                                            ),
                                            // Remove avatar online dot when using Fiverr-style pill
                                            if (isPro && !context.read<UsersCardUICubit>().state.hideAvatarOnlineDot)
                                              Positioned(
                                                right: 4,
                                                top: 4,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: online ? Colors.green : Colors.grey,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 2),
                                                  ),
                                                ),
                                              ),
                                            Positioned(
                                              right: -6,
                                              bottom: -6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blueAccent,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
                                                  ],
                                                ),
                                                child: Text(
                                                  cardLevelLabel,
                                                  style: TextStyle(color: Colors.white, fontSize: (avatarSize * 0.18).clamp(9.0, 12.0)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Online status just below cover image (vertical card)
                                if (online)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1DB954),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.circle, size: 7, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                // Details area
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(16, 10 + avatarSize * 0.6, 16, 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        
                                        // Name with verified icon (Pro)
                                        Row(
                                          children: [
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    fit: FlexFit.loose,
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF232323)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isPro) ...[
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 18),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        // Profession directly under name with small gap
                                        if (jobTitle.isNotEmpty)
                                          Text(
                                            jobTitle,
                                            style: const TextStyle(color: Colors.black54),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 1),
                                        if ((data['rating'] ?? '') != '')
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 14),
                                              const SizedBox(width: 3),
                                              Text('${data['rating']}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        if ((data['rating'] ?? '') != '') const SizedBox(height: 2),
                                        // Title/job moved above (under name)
                                        const SizedBox.shrink(),
                                        // Country + City placed right before bio with minimal gap
                                        Row(
                                          children: [
                                            if (country.isNotEmpty) ...[
                                              Text(countryCodeToEmojiStatic(country)),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  country,
                                                  style: const TextStyle(color: Colors.blueGrey),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                            if ((data['city'] ?? '').toString().isNotEmpty) ...[
                                              if (country.isNotEmpty) const SizedBox(width: 8),
                                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  (data['city'] ?? '').toString(),
                                                  style: const TextStyle(color: Colors.black54),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        // Online pill above action row removed; pill is shown just below cover image
                                        if (bio.isNotEmpty) ...[
                                          const SizedBox(height: 1),
                                          Flexible(
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: Text(
                                                bio,
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 11.5,
                                                  height: 1.15,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        // Pro chip will be shown directly above the action button below
                                        // removed in-body online row (moved to avatar)
                                        const Spacer(),
                                        // Bottom row: From price and button/menu
                                        Row(
                                          children: [
                                            Builder(
                                              builder: (_) {
                                                final dynamic price = data['price'] ?? data['startingFrom'] ?? data['hourlyRate'];
                                                if (price == null || price.toString().isEmpty) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Text('From \$${price.toString()}', style: const TextStyle(fontWeight: FontWeight.bold));
                                              },
                                            ),
                                            const Spacer(),
                                            const SizedBox.shrink(),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.blue[800],
                                                side: BorderSide(color: Colors.blue[800]!, width: 1.2),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                              onPressed: () async {
                                                try {
                                                  final prefs = await SharedPreferences.getInstance();
                                                  final viewerId = prefs.getString('userId') ?? '';
                                                  final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
                                                  await docRef.collection('visits').add({'viewerId': viewerId, 'timestamp': FieldValue.serverTimestamp()});
                                                  await docRef.set({'profileVisits': FieldValue.increment(1)}, SetOptions(merge: true));
                                                } catch (_) {}
                                                if (!context.mounted) return;
                                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
                                              },
                                              child: const Text('View Profile'),
                                            ),
                                            // removed trailing dots icon as requested
                                          ],
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
                  },
                );
              },
            );
          },
        );
      },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF232323),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (idx) async {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('userId') ?? '';
          setState(() => _selectedIndex = idx);
          if (idx == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => DashboardScreen(userId: userId, selectedIndex: 0),
              ),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardScreen(userId: userId, selectedIndex: idx),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: 'Subscription',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    ),
    );
    
  }
}

// Helper for country flag emoji
String countryCodeToEmojiStatic(String? countryOrCode) {
  if (countryOrCode == null || countryOrCode.isEmpty) return '';
  String code = countryOrCode.trim();
  if (code.length != 2) {
    // Use the same mapping as in profile_screen.dart
    final map = {
      'Pakistan': 'PK', 'India': 'IN', 'Azerbaijan': 'AZ', 'United States': 'US', 'United Kingdom': 'GB',
      'Germany': 'DE', 'France': 'FR', 'Canada': 'CA', 'Australia': 'AU', 'Bangladesh': 'BD', 'Nepal': 'NP',
      'China': 'CN', 'Japan': 'JP', 'Turkey': 'TR', 'Russia': 'RU', 'Saudi Arabia': 'SA', 'UAE': 'AE',
      'Afghanistan': 'AF', 'Sri Lanka': 'LK', 'South Africa': 'ZA', 'Brazil': 'BR', 'Italy': 'IT', 'Spain': 'ES',
      'Egypt': 'EG', 'Indonesia': 'ID', 'Malaysia': 'MY', 'Singapore': 'SG', 'Qatar': 'QA', 'Kuwait': 'KW',
      'Oman': 'OM', 'Yemen': 'YE', 'Jordan': 'JO', 'Iraq': 'IQ', 'Iran': 'IR', 'Philippines': 'PH',
      'Thailand': 'TH', 'Vietnam': 'VN', 'South Korea': 'KR', 'North Korea': 'KP', 'Sweden': 'SE', 'Norway': 'NO',
      'Denmark': 'DK', 'Finland': 'FI', 'Poland': 'PL', 'Netherlands': 'NL', 'Belgium': 'BE', 'Switzerland': 'CH',
      'Austria': 'AT', 'Greece': 'GR', 'Portugal': 'PT', 'Mexico': 'MX', 'Argentina': 'AR', 'Colombia': 'CO',
      'Chile': 'CL', 'New Zealand': 'NZ',
    };
    if (map.containsKey(code)) code = map[code]!;
  }
  if (code.length != 2) return '';
  code = code.toUpperCase();
  return String.fromCharCodes([
    code.codeUnitAt(0) + 127397,
    code.codeUnitAt(1) + 127397,
  ]);
} 
// Helper to compute level label from projectsExchanged
// Ensures the badge label matches the filter logic everywhere
String computeLevelLabelFromProjects(dynamic raw) {
  int normalize(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    final s = v.toString();
    final digits = RegExp(r'\d+').allMatches(s).map((m) => m.group(0)!).join();
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  final int projects = normalize(raw);
  if (projects >= 1000) return 'X360 Top Rated';
  if (projects >= 500) return 'Level 3';
  if (projects >= 50) return 'Level 2';
  return 'Level 1';
}

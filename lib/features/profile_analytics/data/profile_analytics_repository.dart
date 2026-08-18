import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileLevelInfo {
  final int level; // 1,2,3
  final bool topRated; // >= 1000 completed
  final String levelLabel; // "Level 1", "Level 2", "Level 3", or "X360 Top Rated"
  final double levelProgress; // 0..1 progress within current level range
  final String nextTargetLabel; // Human label for next milestone
  final IconData icon;
  final Color color;
  final int completedCount; // input completed-exchanges count (for convenience)
  final int baseCount; // lower bound of current level
  final int nextTargetCount; // upper bound (target) for next level

  const ProfileLevelInfo({
    required this.level,
    required this.topRated,
    required this.levelLabel,
    required this.levelProgress,
    required this.nextTargetLabel,
    required this.icon,
    required this.color,
    required this.completedCount,
    required this.baseCount,
    required this.nextTargetCount,
  });

  /// Remaining exchanges needed to reach the next level, or 0 if already top tier.
  int get remainingForNext {
    if (topRated || nextTargetCount <= baseCount) return 0;
    final delta = nextTargetCount - completedCount;
    return delta < 0 ? 0 : delta;
  }

  /// Short subtitle like "50 more to Level 2" or "Top tier achieved".
  String get progressSubtitle {
    if (topRated) return 'Top tier achieved';
    final remaining = remainingForNext;
    final nextLabel = levelLabel == 'Level 1'
        ? 'Level 2'
        : levelLabel == 'Level 2'
            ? 'Level 3'
            : 'X360 Top Rated';
    if (remaining == 0) return 'Next: $nextLabel';
    return '$remaining more to $nextLabel';
  }
}

class ProfileAnalyticsData {
  final int totalChats;
  final int unreadMessages;
  final int requestsPending;
  final int requestsAccepted;
  final int requestsRejected;
  final int requestsCompleted;
  final int requestsSent;
  final int projectsExchanged; // alias of completed for convenience if tracked on user
  final int profileVisits;
  final int level; // 1,2,3
  final bool topRated; // >= 1000 completed
  final String levelLabel; // "Level 1", "Level 2", "Level 3", or "X360 Top Rated"
  final String profileImageUrl;
  final double levelProgress; // 0..1 progress within current level range
  final String nextTargetLabel; // Human label for next milestone

  const ProfileAnalyticsData({
    required this.totalChats,
    required this.unreadMessages,
    required this.requestsPending,
    required this.requestsAccepted,
    required this.requestsRejected,
    required this.requestsCompleted,
    required this.requestsSent,
    required this.projectsExchanged,
    required this.profileVisits,
    required this.level,
    required this.topRated,
    required this.levelLabel,
    required this.profileImageUrl,
    required this.levelProgress,
    required this.nextTargetLabel,
  });
}

class ProfileAnalyticsRepository {
  final FirebaseFirestore _db;
  ProfileAnalyticsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static ProfileLevelInfo computeLevelInfo(int completedExchanges) {
    final int completed = completedExchanges < 0 ? 0 : completedExchanges;
    int level = 1;
    bool topRated = false;
    String levelLabel = 'Level 1';
    IconData icon = Icons.emoji_events_outlined;
    Color color = Colors.grey;

    if (completed >= 1000) {
      topRated = true;
      level = 3;
      levelLabel = 'X360 Top Rated';
      icon = Icons.workspace_premium;
      color = Colors.purpleAccent;
    } else if (completed >= 500) {
      level = 3;
      levelLabel = 'Level 3';
      icon = Icons.military_tech;
      color = Colors.amber;
    } else if (completed >= 50) {
      level = 2;
      levelLabel = 'Level 2';
      icon = Icons.emoji_events;
      color = Colors.blueAccent;
    }

    int base = 0;
    int nextTarget = 50;
    String nextTargetLabel = 'Level 2 at 50 completed';
    if (levelLabel == 'Level 2') {
      base = 50;
      nextTarget = 500;
      nextTargetLabel = 'Level 3 at 500 completed';
    } else if (levelLabel == 'Level 3') {
      base = 500;
      nextTarget = 1000;
      nextTargetLabel = 'X360 Top Rated at 1000 completed';
    } else if (levelLabel == 'X360 Top Rated') {
      base = 1000;
      nextTarget = 1000;
      nextTargetLabel = 'Top tier achieved';
    }
    final int denom = (nextTarget - base) <= 0 ? 1 : (nextTarget - base);
    final double levelProgress = ((completed - base) / denom).clamp(0.0, 1.0);

    return ProfileLevelInfo(
      level: level,
      topRated: topRated,
      levelLabel: levelLabel,
      levelProgress: levelProgress,
      nextTargetLabel: nextTargetLabel,
      icon: icon,
      color: color,
      completedCount: completed,
      baseCount: base,
      nextTargetCount: nextTarget,
    );
  }

  Future<ProfileAnalyticsData> load(String userId) async {
    // Fetch in parallel where possible
    final userDocF = _db.collection('users').doc(userId).get();
    final chatsSnapF = _db.collection('users').doc(userId).collection('chats').get();
    final requestsSnapF = _db
        .collection('users')
        .doc(userId)
        .collection('requests')
        .orderBy('timestamp', descending: true)
        .get();

    final userDoc = await userDocF;
    final chatsSnap = await chatsSnapF;
    final requestsSnap = await requestsSnapF;

    final String profileImageUrl = (userDoc.data()?['profileImageUrl'] ?? '').toString();

    final int projectsExchanged = (userDoc.data()?['projectsExchanged'] ?? 0) is int
        ? (userDoc.data()?['projectsExchanged'] ?? 0) as int
        : int.tryParse((userDoc.data()?['projectsExchanged'] ?? '0').toString()) ?? 0;

    final int totalChats = chatsSnap.docs.length;

    // Count unread messages across chats
    int unreadMessages = 0;
    for (final chat in chatsSnap.docs) {
      final msgs = await chat.reference
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('seen', isEqualTo: false)
          .get();
      unreadMessages += msgs.docs.length;
    }

    int requestsPending = 0;
    int requestsAccepted = 0;
    int requestsRejected = 0;
    int requestsCompleted = 0;
    int requestsSent = 0; // Active sent: excludes completed
    for (final doc in requestsSnap.docs) {
      final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
      final fromUserId = (doc.data()['fromUserId'] ?? '').toString();
      final isOutgoing = (doc.data()['isOutgoing'] ?? false) == true;
      if ((isOutgoing || fromUserId == userId) && status != 'completed') {
        // count only active sent (not completed)
        requestsSent++;
      }
      if (status == 'accepted') {
        requestsAccepted++;
      } else if (status == 'rejected') {
        requestsRejected++;
      } else if (status == 'completed') {
        requestsCompleted++;
      } else {
        requestsPending++;
      }
    }

    // Profile visits: try field first, then subcollection fallback
    int profileVisits = 0;
    try {
      final pvField = userDoc.data()?['profileVisits'] ?? userDoc.data()?['profileVisitsCount'];
      if (pvField is int) profileVisits = pvField;
      if (profileVisits == 0) {
        final visitsSnap = await _db.collection('users').doc(userId).collection('visits').get();
        profileVisits = visitsSnap.docs.length;
      }
    } catch (_) {
      // ignore
    }

    // Compute a stable completed-exchanges count
    final int computedExchanged = requestsCompleted > projectsExchanged ? requestsCompleted : projectsExchanged;

    // Use shared static level computation (single source of truth)
    final levelInfo = computeLevelInfo(computedExchanged);

    // Persist the computed projectsExchanged to the user's document so it is available elsewhere
    try {
      await _db
          .collection('users')
          .doc(userId)
          .set({'projectsExchanged': computedExchanged}, SetOptions(merge: true));
    } catch (_) {
      // Ignore persistence failure; analytics can still be shown
    }

    return ProfileAnalyticsData(
      totalChats: totalChats,
      unreadMessages: unreadMessages,
      requestsPending: requestsPending,
      requestsAccepted: requestsAccepted,
      requestsRejected: requestsRejected,
      requestsCompleted: requestsCompleted,
      requestsSent: requestsSent,
      projectsExchanged: computedExchanged,
      profileVisits: profileVisits,
      level: levelInfo.level,
      topRated: levelInfo.topRated,
      levelLabel: levelInfo.levelLabel,
      profileImageUrl: profileImageUrl,
      levelProgress: levelInfo.levelProgress,
      nextTargetLabel: levelInfo.nextTargetLabel,
    );
  }
}

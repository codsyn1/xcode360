import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_payments_state.dart';

class AdminPaymentsCubit extends Cubit<AdminPaymentsState> {
  final FirebaseFirestore _db;
  AdminPaymentsCubit({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(const AdminPaymentsState());

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  void init() {
    emit(state.copyWith(loading: true, usersLoading: true, error: null, message: null));
    // Pending payments
    _sub?.cancel();
    _sub = _db
        .collection('payments')
        .where('status', isEqualTo: 'pending')
        // NOTE: Removing orderBy to avoid Firestore composite index requirement.
        // We'll sort by createdAt on the client side instead.
        .snapshots()
        .listen((snap) {
      final items = snap.docs.map((d) {
        final data = d.data();
        return AdminPaymentItem(
          id: d.id,
          userId: (data['userId'] ?? '').toString(),
          tier: (data['tier'] ?? 'monthly').toString(),
          amountUSD: (data['amountUSD'] is num) ? (data['amountUSD'] as num).toDouble() : 0.0,
          bankReference: (data['bankReference'] ?? '').toString(),
          createdAt: (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0),
          status: (data['status'] ?? 'pending').toString(),
        );
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(state.copyWith(loading: false, pending: items));
    }, onError: (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    });

    // All users list
    _usersSub?.cancel();
    _usersSub = _db
        .collection('users')
        .orderBy('fullName', descending: false)
        .snapshots()
        .listen((snap) {
      final users = snap.docs.map((d) {
        final data = d.data();
        final plan = (data['plan'] ?? 'Free').toString();
        DateTime? activeUntil;
        final ts = data['proActiveUntil'];
        if (ts is Timestamp) {
          activeUntil = ts.toDate();
        } else if (ts is DateTime) activeUntil = ts;
        return AdminUserItem(
          id: d.id,
          name: (data['fullName'] ?? data['name'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          username: (data['username'] ?? '').toString(),
          plan: plan,
          proActiveUntil: activeUntil,
        
          userPin: (data['userPin'] ?? '').toString(),

          jobTitle: (data['jobTitle'] ?? '').toString().isEmpty ? null : (data['jobTitle'] ?? '').toString(),
          signupCategory: (data['category'] ?? '').toString().isEmpty ? null : (data['category'] ?? '').toString(),
          country: (data['country'] ?? '').toString().isEmpty ? null : (data['country'] ?? '').toString(),
          city: (data['city'] ?? '').toString().isEmpty ? null : (data['city'] ?? '').toString(),
          profileImageUrl: (data['profileImageUrl'] ?? '').toString().isEmpty ? null : (data['profileImageUrl'] ?? '').toString(),
          proSince: (data['proSince'] is Timestamp) ? (data['proSince'] as Timestamp).toDate() : null,
          createdAt: (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : null,
        );
      }).toList();
      
      // Calculate analytics data
      final analytics = _calculateAnalytics(users);
      
      final q = state.searchQuery.trim();
      final filtered = q.isEmpty
          ? users
          : users.where((u) => u.userPin.contains(q) || u.email.toLowerCase().contains(q.toLowerCase()) || u.username.toLowerCase().contains(q.toLowerCase())).toList();
      emit(state.copyWith(
        usersLoading: false, 
        users: users, 
        filteredUsers: filtered,
        totalUsers: analytics['totalUsers'],
        freeUsers: analytics['freeUsers'],
        proUsers: analytics['proUsers'],
        countryStats: analytics['countryStats'],
        cityStats: analytics['cityStats'],
      ));
    }, onError: (e) {
      emit(state.copyWith(usersLoading: false, error: e.toString()));
    });
  }

  Future<void> approve(AdminPaymentItem item) async {
    emit(state.copyWith(processing: true, error: null, message: null));
    try {
      final now = DateTime.now();
      final until = _addOneCalendarMonth(now);

      // 1) Update user plan
      await _db.collection('users').doc(item.userId).set({
        'plan': 'Pro',
        'proSince': Timestamp.fromDate(now),
        'proActiveUntil': Timestamp.fromDate(until),
        'proAutoRenew': true,
      }, SetOptions(merge: true));

      // 2) Mark payment approved
      await _db.collection('payments').doc(item.id).update({
        'status': 'approved',
        'adminProcessedAt': FieldValue.serverTimestamp(),
      });

      emit(state.copyWith(processing: false, message: 'Approved and user upgraded to Pro'));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  Future<void> reject(AdminPaymentItem item) async {
    emit(state.copyWith(processing: true, error: null, message: null));
    try {
      await _db.collection('payments').doc(item.id).update({
        'status': 'rejected',
        'adminProcessedAt': FieldValue.serverTimestamp(),
      });
      emit(state.copyWith(processing: false, message: 'Payment rejected'));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  Future<void> setUserFree(String userId) async {
    emit(state.copyWith(processing: true, error: null, message: null));
    try {
      await _db.collection('users').doc(userId).set({
        'plan': 'Free',
        'proSince': null,
        'proActiveUntil': null,
        'proAutoRenew': null,
      }, SetOptions(merge: true));
      emit(state.copyWith(processing: false, message: 'User set to Free'));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  Future<void> setUserPro(String userId, {bool autoRenew = true}) async {
    emit(state.copyWith(processing: true, error: null, message: null));
    try {
      final now = DateTime.now();
      final until = _addOneCalendarMonth(now);
      await _db.collection('users').doc(userId).set({
        'plan': 'Pro',
        'proSince': Timestamp.fromDate(now),
        'proActiveUntil': Timestamp.fromDate(until),
        'proAutoRenew': autoRenew,
      }, SetOptions(merge: true));
      emit(state.copyWith(processing: false, message: 'User upgraded to Pro'));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  Future<void> deleteUser(String userId) async {
    emit(state.copyWith(processing: true, error: null, message: null));
    try {
      // Delete user from users collection
      await _db.collection('users').doc(userId).delete();
      
      // Delete all payments associated with this user
      final paymentsSnapshot = await _db
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in paymentsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete user's authentication (this would need Firebase Admin SDK on backend)
      // For now, we'll just mark the user as deleted in Firestore
      // Note: In a real app, you'd use Firebase Admin SDK to delete the auth user
      
      emit(state.copyWith(processing: false, message: 'User deleted successfully'));
    } catch (e) {
      emit(state.copyWith(processing: false, error: e.toString()));
    }
  }

  void setSearchQuery(String q) {
    final query = q.trim();
    final filtered = query.isEmpty
        ? state.users
        : state.users.where((u) => u.userPin.contains(query) || u.email.toLowerCase().contains(query.toLowerCase()) || u.username.toLowerCase().contains(query.toLowerCase())).toList();
    emit(state.copyWith(searchQuery: query, filteredUsers: filtered));
  }


  DateTime _addOneCalendarMonth(DateTime d) {
    int y = d.year;
    int m = d.month + 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    final daysInNext = DateTime(y, m + 1, 0).day;
    final day = d.day > daysInNext ? daysInNext : d.day;
    return DateTime(y, m, day, d.hour, d.minute, d.second, d.millisecond, d.microsecond);
  }

  // Calculate analytics data from users list
  Map<String, dynamic> _calculateAnalytics(List<AdminUserItem> users) {
    int totalUsers = users.length;
    int freeUsers = 0;
    int proUsers = 0;
    Map<String, int> countryStats = {};
    Map<String, int> cityStats = {};

    for (var user in users) {
      // Count free vs paid users
      if (user.plan.toLowerCase() == 'free') {
        freeUsers++;
      } else if (user.plan.toLowerCase() == 'pro') {
        proUsers++;
      }
      
      // Count countries
      if (user.country != null && user.country!.isNotEmpty) {
        countryStats[user.country!] = (countryStats[user.country!] ?? 0) + 1;
      }
      
      // Count cities
      if (user.city != null && user.city!.isNotEmpty) {
        cityStats[user.city!] = (cityStats[user.city!] ?? 0) + 1;
      }
    }

    return {
      'totalUsers': totalUsers,
      'freeUsers': freeUsers,
      'proUsers': proUsers,
      'countryStats': countryStats,
      'cityStats': cityStats,
    };
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _usersSub?.cancel();
    return super.close();
  }
}

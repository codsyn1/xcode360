import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_state.dart';
import '../../../../services/notification_service.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final FirebaseFirestore _db;

  SubscriptionCubit({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(const SubscriptionState());

  static const List<Map<String, dynamic>> kFeatures = [
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

  Future<void> init(String userId) async {
    emit(state.copyWith(loading: true, error: null, message: null, userId: userId));
    try {
      final snap = await _db.collection('users').doc(userId).get();
      final data = snap.data() ?? {};
      final plan = (data['plan'] ?? 'Free').toString();
      // Prefer and rely solely on the per-user flag from Firestore
      final bool completed = (data['subscriptionCompleted'] == true);
      // Handle Pro validity and auto-renew
      if (plan.toLowerCase() == 'pro') {
        final ts = data['proActiveUntil'];
        final autoRenew = (data['proAutoRenew'] ?? true) == true;
        DateTime? activeUntil;
        if (ts is Timestamp) {
          activeUntil = ts.toDate();
        } else if (ts is DateTime) activeUntil = ts;
        if (activeUntil == null) {
          // If missing, set to one month from now
          final newUntil = _addOneCalendarMonth(DateTime.now());
          await _db.collection('users').doc(userId).set({
            'proSince': FieldValue.serverTimestamp(),
            'proActiveUntil': Timestamp.fromDate(newUntil),
            'proAutoRenew': true,
            'subscriptionCompleted': true,
          }, SetOptions(merge: true));
          // Ensure subscription marked as completed
          final prefs2 = await SharedPreferences.getInstance();
          await prefs2.setBool('subscriptionCompleted', true);
          emit(state.copyWith(loading: false, plan: 'Pro', features: kFeatures, subscriptionCompleted: true));
          return;
        }
        final now = DateTime.now();
        if (now.isAfter(activeUntil)) {
          if (autoRenew == true) {
            // Auto-renew one more month
            final renewed = _addOneCalendarMonth(activeUntil);
            await _db.collection('users').doc(userId).set({
              'proActiveUntil': Timestamp.fromDate(renewed),
            }, SetOptions(merge: true));
            emit(state.copyWith(loading: false, plan: 'Pro', features: kFeatures, subscriptionCompleted: completed, message: 'Subscription renewed'));
          } else {
            // Downgrade to Free automatically
            await _db.collection('users').doc(userId).set({'plan': 'Free'}, SetOptions(merge: true));
            final prefs3 = await SharedPreferences.getInstance();
            await prefs3.setBool('subscriptionCompleted', true);
            emit(state.copyWith(loading: false, plan: 'Free', features: kFeatures, subscriptionCompleted: true, message: 'Pro expired. Switched to Free'));
          }
        } else {
          // Active Pro: mark completed
          await _db.collection('users').doc(userId).set({'subscriptionCompleted': true}, SetOptions(merge: true));
          final prefs4 = await SharedPreferences.getInstance();
          await prefs4.setBool('subscriptionCompleted', true);
          emit(state.copyWith(loading: false, plan: 'Pro', features: kFeatures, subscriptionCompleted: true));
        }
      } else {
        emit(state.copyWith(loading: false, plan: 'Free', features: kFeatures, subscriptionCompleted: completed));
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString(), features: kFeatures));
    }
  }

  Future<void> upgradeToPro() async {
    if (state.userId == null) return;
    print('🔥 === SUBSCRIPTION CUBIT: UPGRADING TO PRO ===');
    print('🔥 USER ID: ${state.userId}');
    emit(state.copyWith(upgrading: true, error: null, message: null));
    try {
      final now = DateTime.now();
      final until = _addOneCalendarMonth(now);
      await _db.collection('users').doc(state.userId).set({
        'plan': 'Pro',
        'proSince': Timestamp.fromDate(now),
        'proActiveUntil': Timestamp.fromDate(until),
        'proAutoRenew': true,
        'subscriptionCompleted': true,
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('subscriptionCompleted', true);
      
      // Store FCM token for push notifications after subscription completion
      print('🔥 STORING FCM TOKEN AFTER PRO UPGRADE');
      try {
        await NotificationService().storeUserToken(state.userId!);
        NotificationService().listenForTokenRefresh(state.userId!);
        print('✅ FCM token stored after pro upgrade');
      } catch (e) {
        print('❌ Error storing FCM token after pro upgrade: $e');
      }
      
      emit(state.copyWith(upgrading: false, plan: 'Pro', subscriptionCompleted: true, message: 'Plan upgraded to Pro'));
    } catch (e) {
      emit(state.copyWith(upgrading: false, error: e.toString()));
    }
  }

  Future<void> downgradeToFree() async {
    if (state.userId == null) return;
    emit(state.copyWith(upgrading: true, error: null, message: null));
    try {
      await _db.collection('users').doc(state.userId).set({'plan': 'Free'}, SetOptions(merge: true));
      emit(state.copyWith(upgrading: false, plan: 'Free', message: 'Plan downgraded to Free'));
    } catch (e) {
      emit(state.copyWith(upgrading: false, error: e.toString()));
    }
  }

  bool get isPro => state.plan.toLowerCase() == 'pro';

  Future<void> proceedWithFree() async {
    // Ensure plan is Free in Firestore and then instruct UI to navigate
    if (state.userId == null) return;
    print('🔥 === SUBSCRIPTION CUBIT: PROCEEDING WITH FREE ===');
    print('🔥 USER ID: ${state.userId}');
    emit(state.copyWith(upgrading: true, error: null, message: null));
    try {
      await _db.collection('users').doc(state.userId).set({
        'plan': 'Free',
        'proSince': null,
        'proActiveUntil': null,
        'proAutoRenew': null,
        'subscriptionCompleted': true,
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('subscriptionCompleted', true);
      // Also ensure isLoggedIn is set for new users
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', state.userId!);
      
      // Store FCM token for push notifications after subscription completion
      print('🔥 STORING FCM TOKEN AFTER SUBSCRIPTION COMPLETION');
      try {
        await NotificationService().storeUserToken(state.userId!);
        NotificationService().listenForTokenRefresh(state.userId!);
        print('✅ FCM token stored after subscription');
      } catch (e) {
        print('❌ Error storing FCM token after subscription: $e');
      }
      
      emit(state.copyWith(upgrading: false, plan: 'Free', subscriptionCompleted: true, message: 'GO_DASHBOARD'));
    } catch (e) {
      emit(state.copyWith(upgrading: false, error: e.toString()));
    }
  }

  // Adds one calendar month respecting month lengths
  DateTime _addOneCalendarMonth(DateTime d) {
    final year = d.year;
    final month = d.month;
    final day = d.day;
    int nextYear = year;
    int nextMonth = month + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    final newDay = day > daysInNextMonth ? daysInNextMonth : day;
    return DateTime(nextYear, nextMonth, newDay, d.hour, d.minute, d.second, d.millisecond, d.microsecond);
  }
}

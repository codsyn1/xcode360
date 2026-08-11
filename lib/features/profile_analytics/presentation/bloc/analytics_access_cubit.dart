import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsAccessState {
  final bool loading;
  final bool? allowed;
  final String? error;
  const AnalyticsAccessState({this.loading = false, this.allowed, this.error});

  AnalyticsAccessState copyWith({bool? loading, bool? allowed, String? error}) {
    return AnalyticsAccessState(
      loading: loading ?? this.loading,
      allowed: allowed ?? this.allowed,
      error: error,
    );
  }
}

class AnalyticsAccessCubit extends Cubit<AnalyticsAccessState> {
  final FirebaseFirestore _db;
  AnalyticsAccessCubit({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(const AnalyticsAccessState());

  Future<bool> check(String userId) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final plan = (doc.data()?['plan'] ?? '').toString().trim();
      final isPro = plan.toLowerCase() == 'pro';
      emit(state.copyWith(loading: false, allowed: isPro));
      return isPro;
    } catch (e) {
      emit(state.copyWith(loading: false, allowed: false, error: e.toString()));
      return false;
    }
  }
}

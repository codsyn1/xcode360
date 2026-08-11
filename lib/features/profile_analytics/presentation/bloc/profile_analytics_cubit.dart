import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/profile_analytics_repository.dart';
import 'profile_analytics_state.dart';

class ProfileAnalyticsCubit extends Cubit<ProfileAnalyticsState> {
  final ProfileAnalyticsRepository repo;
  ProfileAnalyticsCubit(this.repo) : super(const ProfileAnalyticsState());

  Future<void> load(String userId) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final data = await repo.load(userId);
      emit(state.copyWith(loading: false, data: data, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}

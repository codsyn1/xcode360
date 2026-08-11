import 'package:equatable/equatable.dart';
import '../../data/profile_analytics_repository.dart';

class ProfileAnalyticsState extends Equatable {
  final bool loading;
  final ProfileAnalyticsData? data;
  final String? error;

  const ProfileAnalyticsState({
    this.loading = false,
    this.data,
    this.error,
  });

  ProfileAnalyticsState copyWith({
    bool? loading,
    ProfileAnalyticsData? data,
    String? error,
  }) {
    return ProfileAnalyticsState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, data, error];
}

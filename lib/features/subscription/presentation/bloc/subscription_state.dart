import 'package:equatable/equatable.dart';

class SubscriptionState extends Equatable {
  final bool loading;
  final bool upgrading;
  final String? error;
  final String? message;
  final String? userId;
  final String plan; // 'Free' or 'Pro'
  final List<Map<String, dynamic>> features; // same schema as UI table
  final bool subscriptionCompleted; // after first selection, hide 'Continue with Free'

  const SubscriptionState({
    this.loading = true,
    this.upgrading = false,
    this.error,
    this.message,
    this.userId,
    this.plan = 'Free',
    this.features = const [],
    this.subscriptionCompleted = false,
  });

  SubscriptionState copyWith({
    bool? loading,
    bool? upgrading,
    String? error,
    String? message,
    String? userId,
    String? plan,
    List<Map<String, dynamic>>? features,
    bool? subscriptionCompleted,
  }) {
    return SubscriptionState(
      loading: loading ?? this.loading,
      upgrading: upgrading ?? this.upgrading,
      error: error,
      message: message,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      features: features ?? this.features,
      subscriptionCompleted: subscriptionCompleted ?? this.subscriptionCompleted,
    );
  }

  @override
  List<Object?> get props => [loading, upgrading, error, message, userId, plan, features, subscriptionCompleted];
}

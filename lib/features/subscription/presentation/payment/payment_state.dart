import 'package:equatable/equatable.dart';

class PaymentState extends Equatable {
  final bool loading;
  final bool submitting;
  final String? error;
  final String? message;
  final String? userId;
  final String selectedTier; // monthly, quarterly, semiannual, yearly
  final Map<String, double> pricesUSD; // key -> price

  const PaymentState({
    this.loading = false,
    this.submitting = false,
    this.error,
    this.message,
    this.userId,
    this.selectedTier = 'monthly',
    this.pricesUSD = const {
      'monthly': 1.00,
    },
  });

  PaymentState copyWith({
    bool? loading,
    bool? submitting,
    String? error,
    String? message,
    String? userId,
    String? selectedTier,
    Map<String, double>? pricesUSD,
  }) {
    return PaymentState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: error,
      message: message,
      userId: userId ?? this.userId,
      selectedTier: selectedTier ?? this.selectedTier,
      pricesUSD: pricesUSD ?? this.pricesUSD,
    );
  }

  @override
  List<Object?> get props => [loading, submitting, error, message, userId, selectedTier, pricesUSD];
}

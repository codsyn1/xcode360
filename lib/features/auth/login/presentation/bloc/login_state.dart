import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool loading;
  final String? error;
  final String identifier; // email or username
  final String password;
  final String? userId;

  const LoginState({
    this.loading = false,
    this.error,
    this.identifier = '',
    this.password = '',
    this.userId,
  });

  LoginState copyWith({
    bool? loading,
    String? error,
    String? identifier,
    String? password,
    String? userId,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      error: error,
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      userId: userId,
    );
  }

  @override
  List<Object?> get props => [loading, error, identifier, password, userId];
}

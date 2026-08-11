import 'package:equatable/equatable.dart';

class UsersState extends Equatable {
  final bool loading;
  final List<Map<String, dynamic>> users;
  final String? error;

  const UsersState({
    this.loading = false,
    this.users = const [],
    this.error,
  });

  UsersState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? users,
    String? error,
  }) {
    return UsersState(
      loading: loading ?? this.loading,
      users: users ?? this.users,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, users, error];
}

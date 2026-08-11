import 'package:equatable/equatable.dart';

class SignupState extends Equatable {
  final bool loading;
  final bool submitted;
  final String? error;
  final String? profileImagePath;
  final String? coverImagePath;
  final String? userId;
  final String? profileUrl;
  final String? coverUrl;

  const SignupState({
    this.loading = false,
    this.submitted = false,
    this.error,
    this.profileImagePath,
    this.coverImagePath,
    this.userId,
    this.profileUrl,
    this.coverUrl,
  });

  SignupState copyWith({
    bool? loading,
    bool? submitted,
    String? error,
    String? profileImagePath,
    String? coverImagePath,
    String? userId,
    String? profileUrl,
    String? coverUrl,
  }) {
    return SignupState(
      loading: loading ?? this.loading,
      submitted: submitted ?? this.submitted,
      error: error,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      userId: userId ?? this.userId,
      profileUrl: profileUrl ?? this.profileUrl,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        submitted,
        error,
        profileImagePath,
        coverImagePath,
        userId,
        profileUrl,
        coverUrl,
      ];
}

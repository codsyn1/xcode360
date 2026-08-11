import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final String? message;
  final String? error;
  final bool showComingSoon;

  const ProfileState({this.message, this.error, this.showComingSoon = false});

  ProfileState copyWith({String? message, String? error, bool? showComingSoon}) {
    return ProfileState(
      message: message,
      error: error,
      showComingSoon: showComingSoon ?? this.showComingSoon,
    );
  }

  @override
  List<Object?> get props => [message, error, showComingSoon];
}

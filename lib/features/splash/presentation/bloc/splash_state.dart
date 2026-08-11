import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashChecking extends SplashState {
  const SplashChecking();
}

class SplashAuthed extends SplashState {
  final String userId;
  const SplashAuthed(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SplashGuest extends SplashState {
  const SplashGuest();
}

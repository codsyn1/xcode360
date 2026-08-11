import 'package:equatable/equatable.dart';

abstract class AppState extends Equatable {
  const AppState();
  @override
  List<Object?> get props => [];
}

class AppUnknown extends AppState {
  const AppUnknown();
}

class AppUnauthed extends AppState {
  const AppUnauthed();
}

class AppAuthed extends AppState {
  final String userId;
  const AppAuthed(this.userId);
  @override
  List<Object?> get props => [userId];
}

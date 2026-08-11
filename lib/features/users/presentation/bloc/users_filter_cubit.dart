import 'package:flutter_bloc/flutter_bloc.dart';

class UsersFilterState {
  final String? country;
  final bool onlineOnly;
  final String? level;
  const UsersFilterState({this.country, this.onlineOnly = false, this.level});

  UsersFilterState copyWith({String? country, bool? onlineOnly, String? level}) {
    return UsersFilterState(
      country: country ?? this.country,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      level: level ?? this.level,
    );
  }
}

class UsersFilterCubit extends Cubit<UsersFilterState> {
  UsersFilterCubit() : super(const UsersFilterState());

  void setCountry(String? value) => emit(state.copyWith(country: value));
  void setOnlineOnly(bool value) => emit(state.copyWith(onlineOnly: value));
  void setLevel(String? value) => emit(state.copyWith(level: value));
}

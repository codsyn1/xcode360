import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/users_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final UsersRepository repo;
  StreamSubscription? _sub;
  UsersCubit(this.repo) : super(const UsersState());

  void start({String? subcategory}) {
    emit(state.copyWith(loading: true));
    _sub?.cancel();
    _sub = repo.usersStream(subcategory: subcategory).listen((users) {
      emit(state.copyWith(loading: false, users: users, error: null));
    }, onError: (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

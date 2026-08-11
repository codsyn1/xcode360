import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/login_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginRepository repo;
  LoginCubit(this.repo) : super(const LoginState());

  void setIdentifier(String v) => emit(state.copyWith(identifier: v, error: null));
  void setPassword(String v) => emit(state.copyWith(password: v, error: null));

  Future<void> submit() async {
    if (state.identifier.trim().isEmpty || state.password.isEmpty) {
      emit(state.copyWith(error: 'Please enter email/username and password'));
      return;
    }
    emit(state.copyWith(loading: true, error: null));
    try {
      final res = await repo.login(identifier: state.identifier.trim(), password: state.password);
      emit(state.copyWith(loading: false, userId: res.userId));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Email login is restricted to admin only')) {
        emit(state.copyWith(loading: false, error: 'Email login is restricted to admin only. Use your username.'));
      } else {
        emit(state.copyWith(loading: false, error: 'Invalid email/username or password'));
      }
    }
  }
}

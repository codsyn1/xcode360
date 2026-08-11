import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashInitial());

  Future<void> checkSession() async {
    emit(const SplashChecking());
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userId = prefs.getString('userId');
    await Future.delayed(const Duration(seconds: 2));
    if (isLoggedIn && userId != null && userId.isNotEmpty) {
      emit(SplashAuthed(userId));
    } else {
      emit(const SplashGuest());
    }
  }
}

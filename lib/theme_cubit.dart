import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getBool('isLightMode') ?? false;
    emit(isLight ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLightMode', newMode == ThemeMode.light);
  }
}

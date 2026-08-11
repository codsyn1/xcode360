import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import '../../../services/notification_service.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppUnknown());

  Future<void> loadSession() async {
    print('🔥 === APP CUBIT: LOADING SESSION ===');
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userId = prefs.getString('userId') ?? '';
    print('🔥 IS LOGGED IN: $isLoggedIn');
    print('🔥 USER ID: $userId');
    
    if (isLoggedIn && userId.isNotEmpty) {
      print('🔥 USER IS LOGGED IN - STORING FCM TOKEN');
      // Store FCM token for push notifications when session loads
      await NotificationService().storeUserToken(userId);
      
      // Listen for token refresh
      NotificationService().listenForTokenRefresh(userId);
      
      print('🔥 SESSION LOADED SUCCESSFULLY');
      emit(AppAuthed(userId));
    } else {
      print('🔥 USER IS NOT LOGGED IN');
      emit(const AppUnauthed());
    }
  }

  Future<void> logIn(String userId) async {
    print('🔥 === APP CUBIT: LOGGING IN ===');
    print('🔥 USER ID: $userId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
    
    // Store FCM token for push notifications
    print('🔥 STORING FCM TOKEN ON LOGIN');
    await NotificationService().storeUserToken(userId);
    
    // Listen for token refresh
    NotificationService().listenForTokenRefresh(userId);
    
    print('🔥 LOGIN SUCCESSFUL');
    emit(AppAuthed(userId));
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    
    // Clear FCM token when user logs out to prevent conflicts
    if (userId.isNotEmpty) {
      await NotificationService().clearUserToken(userId);
    }
    
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    emit(const AppUnauthed());
  }
}

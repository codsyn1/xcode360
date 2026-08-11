import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavIdle());

  void goToSettings() => emit(const NavToSettings());
  void goToProfile(String userId) => emit(NavToProfile(userId));
  void goToCommunities(String userId, {bool showAppBar = true}) => emit(NavToCommunities(userId, showAppBar: showAppBar));

  void reset() => emit(const NavIdle());
}

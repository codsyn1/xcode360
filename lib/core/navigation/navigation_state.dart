import 'package:equatable/equatable.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();
  @override
  List<Object?> get props => [];
}

class NavIdle extends NavigationState {
  const NavIdle();
}

class NavToSettings extends NavigationState {
  const NavToSettings();
}

class NavToProfile extends NavigationState {
  final String userId;
  const NavToProfile(this.userId);
  @override
  List<Object?> get props => [userId];
}

class NavToCommunities extends NavigationState {
  final String userId;
  final bool showAppBar;
  const NavToCommunities(this.userId, {this.showAppBar = true});
  @override
  List<Object?> get props => [userId, showAppBar];
}

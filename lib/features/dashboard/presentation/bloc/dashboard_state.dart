import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final bool loading;
  final String? userId;
  final String? userName;
  final String? userPlan;
  final String? userImageUrl;
  final String? userJobTitle;
  final String? userEmail;
  final String? userCoverImageUrl;
  final String? userBio;
  final String? userWebsite;
  final List<String> userSkills;
  final String? userCountry;
  final String? userCity;
  final String? userPin;
  final bool isAdmin;
  final int selectedIndex;
  final String? error;

  const DashboardState({
    this.loading = false,
    this.userId,
    this.userName,
    this.userPlan,
    this.userImageUrl,
    this.userJobTitle,
    this.userEmail,
    this.userCoverImageUrl,
    this.userBio,
    this.userWebsite,
    this.userSkills = const [],
    this.userCountry,
    this.userCity,
    this.userPin,
    this.isAdmin = false,
    this.selectedIndex = 0,
    this.error,
  });

  DashboardState copyWith({
    bool? loading,
    String? userId,
    String? userName,
    String? userPlan,
    String? userImageUrl,
    String? userJobTitle,
    String? userEmail,
    String? userCoverImageUrl,
    String? userBio,
    String? userWebsite,
    List<String>? userSkills,
    String? userCountry,
    String? userCity,
    String? userPin,
    bool? isAdmin,
    int? selectedIndex,
    String? error,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPlan: userPlan ?? this.userPlan,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      userJobTitle: userJobTitle ?? this.userJobTitle,
      userEmail: userEmail ?? this.userEmail,
      userCoverImageUrl: userCoverImageUrl ?? this.userCoverImageUrl,
      userBio: userBio ?? this.userBio,
      userWebsite: userWebsite ?? this.userWebsite,
      userSkills: userSkills ?? this.userSkills,
      userCountry: userCountry ?? this.userCountry,
      userCity: userCity ?? this.userCity,
      userPin: userPin ?? this.userPin,
      isAdmin: isAdmin ?? this.isAdmin,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        userId,
        userName,
        userPlan,
        userImageUrl,
        userJobTitle,
        userEmail,
        userCoverImageUrl,
        userBio,
        userWebsite,
        userSkills,
        userCountry,
        userCity,
        userPin,
        isAdmin,
        selectedIndex,
        error,
      ];
}

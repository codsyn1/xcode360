import 'package:flutter_bloc/flutter_bloc.dart';

class UsersCardUIState {
  final double screenWidth;
  final int maxBioLines;
  final bool showOnlinePill;
  final bool hideAvatarOnlineDot;
  final bool proBadgeAboveButtonLeft;
  // Responsive sizing
  final double horizontalCoverHeightFactor;
  final double horizontalAvatarSizeFactor;
  final double verticalCoverHeightFactor;
  final double verticalAvatarSizeFactor;
  final double verticalMinHeight;
  final double verticalMaxHeight;
  // Placement flags
  final bool showVerifiedNextToName;
  final bool showProChipNearButton;
  final bool onlinePillAtCenterLeft;
  final bool onlinePillAtRight;
  final bool showLocationAboveBio;

  const UsersCardUIState({
    this.screenWidth = 0,
    this.maxBioLines = 2,
    this.showOnlinePill = true,
    this.hideAvatarOnlineDot = true,
    this.proBadgeAboveButtonLeft = false,
    this.horizontalCoverHeightFactor = 0.24,
    this.horizontalAvatarSizeFactor = 0.26,
    this.verticalCoverHeightFactor = 0.24,
    this.verticalAvatarSizeFactor = 0.26,
    this.verticalMinHeight = 280,
    this.verticalMaxHeight = 430,
    this.showVerifiedNextToName = true,
    this.showProChipNearButton = false,
    this.onlinePillAtCenterLeft = false,
    this.onlinePillAtRight = true,
    this.showLocationAboveBio = true,
  });

  UsersCardUIState copyWith({
    double? screenWidth,
    int? maxBioLines,
    bool? showOnlinePill,
    bool? hideAvatarOnlineDot,
    bool? proBadgeAboveButtonLeft,
    double? horizontalCoverHeightFactor,
    double? horizontalAvatarSizeFactor,
    double? verticalCoverHeightFactor,
    double? verticalAvatarSizeFactor,
    double? verticalMinHeight,
    double? verticalMaxHeight,
    bool? showVerifiedNextToName,
    bool? showProChipNearButton,
    bool? onlinePillAtCenterLeft,
    bool? onlinePillAtRight,
    bool? showLocationAboveBio,
  }) {
    return UsersCardUIState(
      screenWidth: screenWidth ?? this.screenWidth,
      maxBioLines: maxBioLines ?? this.maxBioLines,
      showOnlinePill: showOnlinePill ?? this.showOnlinePill,
      hideAvatarOnlineDot: hideAvatarOnlineDot ?? this.hideAvatarOnlineDot,
      proBadgeAboveButtonLeft: proBadgeAboveButtonLeft ?? this.proBadgeAboveButtonLeft,
      horizontalCoverHeightFactor: horizontalCoverHeightFactor ?? this.horizontalCoverHeightFactor,
      horizontalAvatarSizeFactor: horizontalAvatarSizeFactor ?? this.horizontalAvatarSizeFactor,
      verticalCoverHeightFactor: verticalCoverHeightFactor ?? this.verticalCoverHeightFactor,
      verticalAvatarSizeFactor: verticalAvatarSizeFactor ?? this.verticalAvatarSizeFactor,
      verticalMinHeight: verticalMinHeight ?? this.verticalMinHeight,
      verticalMaxHeight: verticalMaxHeight ?? this.verticalMaxHeight,
      showVerifiedNextToName: showVerifiedNextToName ?? this.showVerifiedNextToName,
      showProChipNearButton: showProChipNearButton ?? this.showProChipNearButton,
      onlinePillAtCenterLeft: onlinePillAtCenterLeft ?? this.onlinePillAtCenterLeft,
      onlinePillAtRight: onlinePillAtRight ?? this.onlinePillAtRight,
      showLocationAboveBio: showLocationAboveBio ?? this.showLocationAboveBio,
    );
  }
}

class UsersCardUICubit extends Cubit<UsersCardUIState> {
  UsersCardUICubit() : super(const UsersCardUIState());

  void setScreenWidth(double w) {
    int bioLines;
    double hCover = 0.24;
    double hAvatar = 0.26;
    double vCover = 0.24;
    double vAvatar = 0.26;
    double vMin = 280;
    double vMax = 430;

    if (w < 320) {
      bioLines = 2;
      hCover = 0.20; hAvatar = 0.23; vCover = 0.20; vAvatar = 0.23; vMin = 250; vMax = 330;
    } else if (w < 360) {
      bioLines = 2;
      hCover = 0.21; hAvatar = 0.24; vCover = 0.21; vAvatar = 0.24; vMin = 260; vMax = 350;
    } else if (w < 420) {
      bioLines = 2;
      hCover = 0.22; hAvatar = 0.25; vCover = 0.22; vAvatar = 0.25; vMin = 270; vMax = 370;
    } else if (w < 500) {
      bioLines = 3;
      hCover = 0.23; hAvatar = 0.26; vCover = 0.23; vAvatar = 0.26; vMin = 285; vMax = 390;
    } else if (w < 650) {
      bioLines = 3;
      hCover = 0.24; hAvatar = 0.26; vCover = 0.24; vAvatar = 0.26; vMin = 300; vMax = 410;
    } else if (w < 800) {
      bioLines = 4;
      hCover = 0.25; hAvatar = 0.27; vCover = 0.25; vAvatar = 0.27; vMin = 320; vMax = 440;
    } else if (w < 1000) {
      bioLines = 4;
      hCover = 0.26; hAvatar = 0.28; vCover = 0.26; vAvatar = 0.28; vMin = 340; vMax = 460;
    } else {
      bioLines = 5;
      hCover = 0.27; hAvatar = 0.29; vCover = 0.27; vAvatar = 0.29; vMin = 360; vMax = 480;
    }

    emit(state.copyWith(
      screenWidth: w,
      maxBioLines: bioLines,
      showOnlinePill: true,
      hideAvatarOnlineDot: true,
      proBadgeAboveButtonLeft: false,
      horizontalCoverHeightFactor: hCover,
      horizontalAvatarSizeFactor: hAvatar,
      verticalCoverHeightFactor: vCover,
      verticalAvatarSizeFactor: vAvatar,
      verticalMinHeight: vMin,
      verticalMaxHeight: vMax,
      showVerifiedNextToName: true,
      showProChipNearButton: false,
      onlinePillAtCenterLeft: false,
      onlinePillAtRight: true,
      showLocationAboveBio: true,
    ));
  }
}

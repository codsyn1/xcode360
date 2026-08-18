import 'package:flutter_bloc/flutter_bloc.dart';

class UsersUIConfigState {
  final double screenWidth;
  final bool isHorizontal;
  final double cardWidth;
  final double listHeight;

  const UsersUIConfigState({
    this.screenWidth = 0,
    this.isHorizontal = true,
    this.cardWidth = 280,
    this.listHeight = 340,
  });

  UsersUIConfigState copyWith({
    double? screenWidth,
    bool? isHorizontal,
    double? cardWidth,
    double? listHeight,
  }) {
    return UsersUIConfigState(
      screenWidth: screenWidth ?? this.screenWidth,
      isHorizontal: isHorizontal ?? this.isHorizontal,
      cardWidth: cardWidth ?? this.cardWidth,
      listHeight: listHeight ?? this.listHeight,
    );
  }
}

class UsersUIConfigCubit extends Cubit<UsersUIConfigState> {
  UsersUIConfigCubit() : super(const UsersUIConfigState());

  void setScreenWidth(double w) {
    // Reverted behavior: use vertical list layout for mobile/tablet
    // and the previous, simpler width buckets.
    const bool horizontal = false; // always vertical list

    // Previous buckets
    double cardW;
    double listH;
    if (w < 340) {
      cardW = w * 0.82; // very small phones
      listH = 300;
    } else if (w < 400) {
      cardW = w * 0.78;
      listH = 320;
    } else if (w < 500) {
      cardW = w * 0.7;
      listH = 330;
    } else if (w < 700) {
      cardW = 340;
      listH = 340;
    } else if (w < 900) {
      cardW = 380;
      listH = 360;
    } else {
      // For larger screens, still provide sane defaults
      cardW = 400;
      listH = 380;
    }

    emit(state.copyWith(
      screenWidth: w,
      isHorizontal: horizontal,
      cardWidth: cardW,
      listHeight: listH,
    ));
  }
}

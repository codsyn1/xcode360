import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState());

  void onHireMePressed() {
    // Set flag so UI can reflect "Coming Soon" directly on the button
    if (!state.showComingSoon) {
      emit(state.copyWith(showComingSoon: true));
    }
  }
}

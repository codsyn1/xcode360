import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/signup_repository.dart';
import 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  final SignupRepository repo;
  SignupCubit(this.repo) : super(const SignupState());

  void setProfilePath(String? path) => emit(state.copyWith(profileImagePath: path));
  void setCoverPath(String? path) => emit(state.copyWith(coverImagePath: path));

  Future<void> submit({
    required String fullName,
    required String jobTitle,
    required String email,
    required String password,
    required String username,
    required String mobile,
    required String website,
    required List<String> skills,
    required String? country,
    required String city,
    required String bio,
    required String? experienceLevel,
    required String? category,
    required String? subcategory,
    String? profileImagePath,
    String? coverImagePath,
  }) async {
    emit(state.copyWith(loading: true, submitted: true, error: null));
    try {
      final result = await repo.createUserAndUpload(
        fullName: fullName,
        jobTitle: jobTitle,
        email: email,
        password: password,
        username: username,
        mobile: mobile,
        website: website,
        skills: skills,
        country: country,
        city: city,
        bio: bio,
        experienceLevel: experienceLevel,
        category: category,
        subcategory: subcategory,
        profileImagePath: profileImagePath ?? state.profileImagePath,
        coverImagePath: coverImagePath ?? state.coverImagePath,
      );
      emit(state.copyWith(
        loading: false,
        userId: result.$1,
        profileUrl: result.$2,
        coverUrl: result.$3,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}

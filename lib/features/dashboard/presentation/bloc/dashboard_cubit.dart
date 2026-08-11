import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final FirebaseFirestore _db;

  DashboardCubit({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(const DashboardState(loading: true));

  Future<void> init(String userId, {int selectedIndex = 0}) async {
    emit(state.copyWith(loading: true, userId: userId, selectedIndex: selectedIndex));
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data() ?? {};

      String nameVal = (data['fullName'] ?? data['name'] ?? 'User').toString();
      String planVal = (data['plan'] ?? 'Free').toString();
      String? imageVal = data['profileImageUrl'];
      String? jobVal = data['jobTitle'];
      String? emailVal = data['email'];
      String? coverVal = data['coverImageUrl'];
      String? bioVal = data['bio'];
      String? webVal = data['website'];
      List<String> skillsVal = List<String>.from(data['skills'] ?? []);
      String countryVal = (data['country'] ?? '').toString();
      String cityVal = (data['city'] ?? '').toString();

      String? computedPin = data['userPin']?.toString();
      if (computedPin == null || computedPin.isEmpty) {
        final millis = DateTime.now().millisecondsSinceEpoch;
        final generatedPin = ((millis % 900000) + 100000).toString();
        await _db.collection('users').doc(userId).set({'userPin': generatedPin}, SetOptions(merge: true));
        computedPin = generatedPin;
      }

      final emailLower = (emailVal ?? '').toLowerCase();
      final isAdmin = (data['isAdmin'] == true) || ((data['username'] ?? '').toString().toLowerCase() == 'xcode360') || emailLower == 'jehangir.ceo@xcode360.com' || userId == 'RLux0lxO4IM1GeSFqHUbmaf9eu52';

      emit(state.copyWith(
        loading: false,
        userName: nameVal,
        userPlan: planVal,
        userImageUrl: imageVal,
        userJobTitle: jobVal,
        userEmail: emailVal,
        userCoverImageUrl: coverVal,
        userBio: bioVal,
        userWebsite: webVal,
        userSkills: skillsVal,
        userCountry: countryVal,
        userCity: cityVal,
        userPin: computedPin,
        isAdmin: isAdmin,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        userName: 'User',
        userPlan: 'Free',
        userImageUrl: null,
        userJobTitle: null,
        userEmail: null,
        userCoverImageUrl: null,
        userBio: null,
        userWebsite: null,
        userSkills: const [],
        userCountry: '',
        userCity: '',
        error: e.toString(),
      ));
    }
  }

  void setSelectedIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }
}

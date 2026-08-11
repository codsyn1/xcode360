import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  SettingsCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker(),
        super(SettingsState.initial());

  Future<void> init() async {
    emit(state.copyWith(loading: true, message: null, error: null));
    try {
      await _ensureAuthenticated();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        emit(state.copyWith(loading: false, error: 'User not logged in'));
        return;
      }
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data() ?? {};
      // Ensure we are signed in as this user to satisfy per-user Storage rules
      await _ensureSignedInAsUser(userId, (data['email'] ?? '').toString(), (data['password'] ?? '').toString());
      // Normalize category and subcategory against available map
      String? cat = (data['category'] as String?);
      String? sub = (data['subcategory'] as String?);
      final keys = state.categories.keys.toList();
      if (cat == null || !keys.contains(cat)) {
        cat = null;
        sub = null;
      } else {
        final subs = state.categories[cat] ?? const [];
        if (sub == null || !subs.contains(sub)) {
          sub = null;
        }
      }

      emit(state.copyWith(
        loading: false,
        userId: userId,
        fullName: (data['fullName'] ?? '').toString(),
        jobTitle: (data['jobTitle'] ?? '').toString(),
        country: (data['country'] ?? '').toString(),
        city: (data['city'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        username: (data['username'] ?? '').toString(),
        userPin: (data['userPin'] ?? '').toString(),
        website: (data['website'] ?? '').toString(),
        bio: (data['bio'] ?? '').toString(),
        skills: (data['skills'] is List)
            ? List<String>.from((data['skills'] as List).map((e) => e.toString()))
            : const <String>[],
        profileImageUrl: (data['profileImageUrl'] ?? '').toString(),
        coverImageUrl: (data['coverImageUrl'] ?? '').toString(),
        category: cat,
        subcategory: sub,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  // Local field updates
  void setWebsite(String v) => emit(state.copyWith(website: v));
  void setBio(String v) => emit(state.copyWith(bio: v));
  void setNewPassword(String v) => emit(state.copyWith(newPassword: v));
  void setJobTitle(String v) => emit(state.copyWith(jobTitle: v));
  void setSkills(List<String> v) => emit(state.copyWith(skills: v));
  void setUserPin(String v) => emit(state.copyWith(userPin: v));
  void setCategory(String? v) {
    // Reset subcategory if category changes
    emit(state.copyWith(category: v, subcategory: null));
  }
  void setSubcategory(String? v) => emit(state.copyWith(subcategory: v));

  // Image picking helpers
  Future<void> pickProfileImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) emit(state.copyWith(localProfileImagePath: picked.path));
    } catch (e) {
      emit(state.copyWith(message: null, error: 'Failed to pick profile image'));
    }
  }

  Future<void> pickCoverImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) emit(state.copyWith(localCoverImagePath: picked.path));
    } catch (e) {
      emit(state.copyWith(message: null, error: 'Failed to pick cover image'));
    }
  }

  Future<void> _ensureAuthenticated() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await _auth.signInAnonymously();
      }
    } catch (_) {
      // Ignore; Storage/Firestore may still work if rules allow
    }
  }

  // Ensure the FirebaseAuth user matches the profile being edited.
  Future<void> _ensureSignedInAsUser(String userId, String email, String password) async {
    try {
      final current = _auth.currentUser;
      if (current?.uid == userId) return;
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // Fallback to anonymous if credentials are not available
        await _ensureAuthenticated();
      }
    } catch (_) {
      // Ignore; if sign-in fails, Storage will return a clear rules error which we surface
    }
  }

  Future<String?> _uploadIfNeeded(String? localPath, String folder, String uid) async {
    if (localPath == null || localPath.isEmpty) return null;
    try {
      await _ensureAuthenticated();
      final file = File(localPath);
      if (!await file.exists()) return null;
      final name = '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final ref = _storage.ref().child(name);
      // Infer simple content type
      String ext = file.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      final metadata = SettableMetadata(contentType: contentType);
      final upload = await ref.putFile(file, metadata);
      return await upload.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // Re-throw to be handled upstream with readable code
      throw Exception('[${e.plugin}/${e.code}] ${e.message ?? 'Upload failed'}');
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<void> saveChanges() async {
    if (state.userId == null) return;
    emit(state.copyWith(saving: true, message: null, error: null));
    try {
      // Ensure we are signed in as this user to satisfy per-user Storage rules
      String email = state.email;
      String password = '';
      try {
        final snap = await _db.collection('users').doc(state.userId).get();
        final d = snap.data();
        if (d != null) {
          email = (d['email'] ?? email).toString();
          password = (d['password'] ?? '').toString();
        }
      } catch (_) {}
      await _ensureSignedInAsUser(state.userId!, email, password);
      String profileUrl = state.profileImageUrl;
      String coverUrl = state.coverImageUrl;

      final uploadFutures = <Future<String?>>[];
      if (state.localProfileImagePath != null) {
        uploadFutures.add(_uploadIfNeeded(state.localProfileImagePath, 'profile_images', state.userId!));
      }
      if (state.localCoverImagePath != null) {
        uploadFutures.add(_uploadIfNeeded(state.localCoverImagePath, 'cover_images', state.userId!));
      }
      if (uploadFutures.isNotEmpty) {
        final results = await Future.wait(uploadFutures);
        int idx = 0;
        if (state.localProfileImagePath != null) {
          profileUrl = results[idx] ?? profileUrl;
          idx++;
        }
        if (state.localCoverImagePath != null) {
          coverUrl = results[idx] ?? coverUrl;
        }
      }

      final update = <String, dynamic>{
        'website': state.website, // optional allowed empty
        'bio': state.bio,
        'jobTitle': state.jobTitle,
        'skills': state.skills,
        'profileImageUrl': profileUrl,
        'coverImageUrl': coverUrl,
        'category': state.category,
        'subcategory': state.subcategory,
        'userPin': state.userPin,
      };

      // Handle password update if provided
      final newPass = state.newPassword.trim();
      if (newPass.isNotEmpty) {
        update['password'] = newPass; // maintain Firestore parity with login flow
        try {
          final user = _auth.currentUser;
          if (user != null) {
            await user.updatePassword(newPass);
          }
        } catch (_) {
          // Ignore auth update errors since app login uses Firestore username/password
        }
      }

      await _db.collection('users').doc(state.userId).update(update);
      emit(state.copyWith(
        saving: false,
        message: 'Profile updated',
        profileImageUrl: profileUrl,
        coverImageUrl: coverUrl,
        localProfileImagePath: null,
        localCoverImagePath: null,
        newPassword: '',
      ));
    } on FirebaseException catch (e) {
      emit(state.copyWith(saving: false, error: '[${e.plugin}/${e.code}] ${e.message ?? 'Unknown Firebase error'}'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}

import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'popup_admin_state.dart';

class PopupAdminCubit extends Cubit<PopupAdminState> {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  PopupAdminCubit({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        super(const PopupAdminState(loading: true));

  Stream<PopupAdminState> listenConfig() {
    return _db.doc('appConfig/popup').snapshots().map((d) {
      final data = d.data();
      final url = data != null ? (data['imageUrl'] ?? '') as String : null;
      final active = data != null ? (data['active'] ?? false) as bool : false;
      return PopupAdminState(loading: false, imageUrl: url, active: active);
    });
  }

  Future<void> refreshOnce() async {
    try {
      final d = await _db.doc('appConfig/popup').get();
      final data = d.data();
      emit(PopupAdminState(
        loading: false,
        imageUrl: data != null ? (data['imageUrl'] ?? '') as String : null,
        active: data != null ? (data['active'] ?? false) as bool : false,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> uploadPopupImage() async {
    try {
      // Ensure Firebase Auth session for Storage rules
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final file = File(picked.path);
      final name = 'popup/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = _storage.ref(name);
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();
      await _db.doc('appConfig/popup').set({'imageUrl': url, 'active': true, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      await refreshOnce();
    } catch (e) {
      if (e is FirebaseException) { emit(state.copyWith(error: '[${e.plugin}/${e.code}] ${e.message}')); } else { emit(state.copyWith(error: e.toString())); }
    }
  }

  Future<void> setActive(bool active) async {
    try {
      await _db.doc('appConfig/popup').set({'active': active}, SetOptions(merge: true));
      await refreshOnce();
    } catch (e) {
      if (e is FirebaseException) { emit(state.copyWith(error: '[${e.plugin}/${e.code}] ${e.message}')); } else { emit(state.copyWith(error: e.toString())); }
    }
  }
}

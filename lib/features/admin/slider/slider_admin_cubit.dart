import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'slider_admin_state.dart';

class SliderAdminCubit extends Cubit<SliderAdminState> {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  SliderAdminCubit({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        super(const SliderAdminState(loading: true));

  Stream<List<SliderImageItem>> listenItems() {
    return _db
        .collection('sliderImages')
        .orderBy('order', descending: false)
        .snapshots(includeMetadataChanges: true)
        .where((snap) => !snap.metadata.isFromCache)
        .map((snap) => snap.docs.map((d) {
              final raw = d.data();
              final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
              final url = (data['url'] ?? '').toString();
              final orderRaw = data['order'];
              final int order = orderRaw is int
                  ? orderRaw
                  : int.tryParse(orderRaw?.toString() ?? '') ?? 0;
              final activeRaw = data['active'];
              final bool active = activeRaw is bool
                  ? activeRaw
                  : (activeRaw?.toString().toLowerCase() == 'true');
              return SliderImageItem(
                id: d.id,
                url: url,
                order: order,
                active: active,
              );
            }).toList());
  }

  Future<void> refreshOnce() async {
    emit(state.copyWith(loading: true));
    try {
      // Try forcing a server read first to avoid stale cache on app start
      QuerySnapshot q;
      try {
        q = await _db
            .collection('sliderImages')
            .orderBy('order')
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        q = await _db.collection('sliderImages').orderBy('order').get();
      }
      final items = q.docs.map((d) {
        final raw = d.data();
        final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final url = (data['url'] ?? '').toString();
        final orderRaw = data['order'];
        final int order = orderRaw is int
            ? orderRaw
            : int.tryParse(orderRaw?.toString() ?? '') ?? 0;
        final activeRaw = data['active'];
        final bool active = activeRaw is bool
            ? activeRaw
            : (activeRaw?.toString().toLowerCase() == 'true');
        return SliderImageItem(
          id: d.id,
          url: url,
          order: order,
          active: active,
        );
      }).toList();
      emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> uploadNewImage({int? order}) async {
    try {
      // clear any previous error
      emit(state.copyWith(error: null));
      // Ensure Firebase Auth session for Storage rules
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final file = File(picked.path);
      final name = 'slider/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = _storage.ref(name);
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      // Sometimes getDownloadURL can immediately throw object-not-found due to
      // eventual consistency. Retry a few times before surfacing the error.
      String url;
      int attempts = 0;
      FirebaseException? lastErr;
      while (true) {
        try {
          url = await task.ref.getDownloadURL();
          break;
        } on FirebaseException catch (e) {
          lastErr = e;
          if (e.code == 'object-not-found' && attempts < 5) {
            attempts++;
            await Future.delayed(const Duration(milliseconds: 300 * 1));
            continue;
          }
          rethrow;
        }
      }
      final docRef = _db.collection('sliderImages').doc();
      await docRef.set({
        'url': url,
        'order': order ?? DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await refreshOnce();
    } catch (e) {
      if (e is FirebaseException) { emit(state.copyWith(error: '[${e.plugin}/${e.code}] ${e.message}')); } else { emit(state.copyWith(error: e.toString())); }
    }
  }

  Future<void> deleteImage(String id) async {
    try {
      await _db.collection('sliderImages').doc(id).delete();
      await refreshOnce();
    } catch (e) {
      if (e is FirebaseException) { emit(state.copyWith(error: '[${e.plugin}/${e.code}] ${e.message}')); } else { emit(state.copyWith(error: e.toString())); }
    }
  }

  Future<void> toggleActive(String id, bool active) async {
    try {
      await _db.collection('sliderImages').doc(id).update({'active': active});
      await refreshOnce();
    } catch (e) {
      if (e is FirebaseException) { emit(state.copyWith(error: '[${e.plugin}/${e.code}] ${e.message}')); } else { emit(state.copyWith(error: e.toString())); }
    }
  }
}

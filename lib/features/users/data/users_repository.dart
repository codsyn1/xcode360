import 'package:cloud_firestore/cloud_firestore.dart';

class UsersRepository {
  final FirebaseFirestore _db;
  UsersRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> usersStream({String? subcategory}) {
    final base = subcategory == null
        ? _db.collection('users')
        : _db.collection('users').where('subcategory', isEqualTo: subcategory);
    return base.snapshots().map((snap) {
      return snap.docs.map((d) {
        final raw = d.data();
        final data = Map<String, dynamic>.from(raw); // clone before mutation
        data['id'] = d.id;
        // normalize for images with fallbacks
        String profile = (data['profileImageUrl'] ?? data['profileUrl'] ?? data['imageUrl'] ?? data['avatarUrl'] ?? '').toString();
        String cover = (data['coverImageUrl'] ?? data['coverUrl'] ?? data['coverPhotoUrl'] ?? '').toString();
        profile = profile.trim();
        cover = cover.trim();
        if (profile.toLowerCase() == 'null') profile = '';
        if (cover.toLowerCase() == 'null') cover = '';
        data['profileImageUrl'] = profile;
        data['coverImageUrl'] = cover;
        return data;
      }).toList();
    });
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'support_chat_state.dart';

class SupportChatCubit extends Cubit<SupportChatState> {
  final FirebaseFirestore _db;
  SupportChatCubit({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(const SupportChatState());

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  late String _ticketId;

  Future<void> init({required String userId, required String category}) async {
    emit(state.copyWith(loading: true, error: null, userId: userId, category: category));
    _ticketId = '${userId}_$category';
    await _ensureTicket(userId, category);
    await _loadUserInfo(userId);
    _listenMessages();
  }

  Future<void> _ensureTicket(String userId, String category) async {
    final docRef = _db.collection('supportTickets').doc(_ticketId);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'userId': userId,
        'category': category,
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _loadUserInfo(String userId) async {
    try {
      final user = await _db.collection('users').doc(userId).get();
      final data = user.data() ?? {};
      final name = (data['fullName'] ?? data['name'] ?? '').toString();
      final pin = (data['userPin'] ?? '').toString();
      emit(state.copyWith(userName: name, userPin: pin));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _listenMessages() {
    _sub?.cancel();
    _sub = _db
        .collection('supportTickets')
        .doc(_ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snap) {
      final msgs = snap.docs.map((d) {
        final data = d.data();
        final ts = data['timestamp'];
        DateTime dt;
        if (ts is Timestamp) {
          dt = ts.toDate();
        } else if (ts is DateTime) dt = ts;
        else dt = DateTime.fromMillisecondsSinceEpoch(0);
        return SupportChatMessage(
          id: d.id,
          senderId: (data['senderId'] ?? '').toString(),
          text: (data['text'] ?? '').toString(),
          timestamp: dt,
          seen: (data['seen'] ?? false) == true,
        );
      }).toList();
      emit(state.copyWith(loading: false, messages: msgs));
    }, onError: (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    });
  }

  Future<void> sendMessage(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    emit(state.copyWith(sending: true));
    try {
      final ticketRef = _db.collection('supportTickets').doc(_ticketId);
      await ticketRef.collection('messages').add({
        'text': t,
        'senderId': state.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });
      await ticketRef.set({
        'lastMessage': t,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      emit(state.copyWith(sending: false));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

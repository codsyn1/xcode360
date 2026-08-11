import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_support_state.dart';

class AdminSupportCubit extends Cubit<AdminSupportState> {
  final FirebaseFirestore _db;
  AdminSupportCubit({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(const AdminSupportState());

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;

  void init() {
    emit(state.copyWith(loading: true, error: null, message: null));
    _ticketsSub?.cancel();
    _ticketsSub = _db
        .collection('supportTickets')
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .listen((snap) async {
      final items = await Future.wait(snap.docs.map((d) async {
        final data = d.data();
        final userId = (data['userId'] ?? '').toString();
        // read user name and pin
        String userName = '';
        String userPin = '';
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          final u = userDoc.data() ?? {};
          userName = (u['fullName'] ?? u['name'] ?? '').toString();
          userPin = (u['userPin'] ?? '').toString();
        } catch (_) {}
        final ts = data['lastTimestamp'];
        DateTime dt;
        if (ts is Timestamp) dt = ts.toDate();
        else if (ts is DateTime) dt = ts;
        else dt = DateTime.fromMillisecondsSinceEpoch(0);
        return SupportTicketItem(
          id: d.id,
          userId: userId,
          userName: userName,
          userPin: userPin,
          category: (data['category'] ?? '').toString(),
          lastMessage: (data['lastMessage'] ?? '').toString(),
          lastTimestamp: dt,
        );
      }).toList());

      // compute display list: apply category filter and then deduplicate by userId (keep latest lastTimestamp)
      final cat = state.selectedCategory.trim();
      final List<SupportTicketItem> filteredByCategory = cat.isEmpty
          ? items
          : items.where((t) => t.category == cat).toList();

      // Deduplicate by userId: keep the ticket with most recent lastTimestamp
      final Map<String, SupportTicketItem> byUser = {};
      for (final t in filteredByCategory) {
        final existing = byUser[t.userId];
        if (existing == null || t.lastTimestamp.isAfter(existing.lastTimestamp)) {
          byUser[t.userId] = t;
        }
      }
      final display = byUser.values.toList()
        ..sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));

      emit(state.copyWith(loading: false, tickets: items, filteredTickets: display));
    }, onError: (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    });
  }

  void setCategoryFilter(String category) {
    final cat = category.trim();
    final filteredByCategory = cat.isEmpty
        ? state.tickets
        : state.tickets.where((t) => t.category == cat).toList();

    // Deduplicate by userId: keep most recent
    final Map<String, SupportTicketItem> byUser = {};
    for (final t in filteredByCategory) {
      final existing = byUser[t.userId];
      if (existing == null || t.lastTimestamp.isAfter(existing.lastTimestamp)) {
        byUser[t.userId] = t;
      }
    }
    final display = byUser.values.toList()
      ..sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));

    emit(state.copyWith(selectedCategory: cat, filteredTickets: display));
  }

  void selectTicket(SupportTicketItem ticket) {
    emit(state.copyWith(selectedTicket: ticket, messagesLoading: true, messages: []));
    _messagesSub?.cancel();
    _messagesSub = _db
        .collection('supportTickets')
        .doc(ticket.id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snap) {
      final all = snap.docs.map((d) => SupportMessage.fromDoc(d));
      // Deduplicate by message id (should already be unique, but guard against duplicates)
      final Map<String, SupportMessage> unique = { for (final m in all) m.id: m };
      final msgs = unique.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      emit(state.copyWith(messagesLoading: false, messages: msgs));
    }, onError: (e) {
      emit(state.copyWith(messagesLoading: false, error: e.toString()));
    });
  }

  Future<void> sendAdminMessage(String text) async {
    final t = state.selectedTicket;
    if (t == null || text.trim().isEmpty) return;
    try {
      final msg = {
        'text': text.trim(),
        'senderId': 'admin',
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      };
      final docRef = _db.collection('supportTickets').doc(t.id);
      await docRef.collection('messages').add(msg);
      await docRef.set({
        'lastMessage': text.trim(),
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      emit(state.copyWith(message: 'Message sent'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _ticketsSub?.cancel();
    _messagesSub?.cancel();
    return super.close();
  }
}

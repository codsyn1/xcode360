import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AdminSupportState extends Equatable {
  final bool loading;
  final bool messagesLoading;
  final bool sidebarOpen;
  final String? error;
  final String? message;
  final List<SupportTicketItem> tickets;
  final List<SupportTicketItem> filteredTickets;
  final String selectedCategory; // '' = all
  final SupportTicketItem? selectedTicket;
  final List<SupportMessage> messages;

  const AdminSupportState({
    this.loading = false,
    this.messagesLoading = false,
    this.sidebarOpen = false,
    this.error,
    this.message,
    this.tickets = const [],
    this.filteredTickets = const [],
    this.selectedCategory = '',
    this.selectedTicket,
    this.messages = const [],
  });

  AdminSupportState copyWith({
    bool? loading,
    bool? messagesLoading,
    bool? sidebarOpen,
    String? error,
    String? message,
    List<SupportTicketItem>? tickets,
    List<SupportTicketItem>? filteredTickets,
    String? selectedCategory,
    SupportTicketItem? selectedTicket,
    List<SupportMessage>? messages,
  }) {
    return AdminSupportState(
      loading: loading ?? this.loading,
      messagesLoading: messagesLoading ?? this.messagesLoading,
      sidebarOpen: sidebarOpen ?? this.sidebarOpen,
      error: error,
      message: message,
      tickets: tickets ?? this.tickets,
      filteredTickets: filteredTickets ?? this.filteredTickets,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        messagesLoading,
        sidebarOpen,
        error,
        message,
        tickets,
        filteredTickets,
        selectedCategory,
        selectedTicket,
        messages,
      ];
}

class SupportTicketItem extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userPin;
  final String category; // Live Chat, General Inquiries, etc
  final String lastMessage;
  final DateTime lastTimestamp;

  const SupportTicketItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPin,
    required this.category,
    required this.lastMessage,
    required this.lastTimestamp,
  });

  @override
  List<Object?> get props => [id, userId, userName, userPin, category, lastMessage, lastTimestamp];
}

class SupportMessage extends Equatable {
  final String id;
  final String senderId; // userId or 'admin'
  final String text;
  final DateTime timestamp;
  final bool seen;

  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.seen,
  });

  factory SupportMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['timestamp'];
    DateTime dt;
    if (ts is Timestamp) dt = ts.toDate();
    else if (ts is DateTime) dt = ts;
    else dt = DateTime.fromMillisecondsSinceEpoch(0);
    return SupportMessage(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      timestamp: dt,
      seen: (data['seen'] ?? false) == true,
    );
  }

  @override
  List<Object?> get props => [id, senderId, text, timestamp, seen];
}

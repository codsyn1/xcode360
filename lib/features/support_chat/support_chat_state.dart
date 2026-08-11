import 'package:equatable/equatable.dart';

class SupportChatMessage extends Equatable {
  final String id;
  final String senderId; // userId or 'admin'
  final String text;
  final DateTime timestamp;
  final bool seen;

  const SupportChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.seen,
  });

  @override
  List<Object?> get props => [id, senderId, text, timestamp, seen];
}

class SupportChatState extends Equatable {
  final bool loading;
  final bool sending;
  final String? error;
  final String userId;
  final String category;
  final String userName;
  final String userPin;
  final List<SupportChatMessage> messages;

  const SupportChatState({
    this.loading = false,
    this.sending = false,
    this.error,
    this.userId = '',
    this.category = '',
    this.userName = '',
    this.userPin = '',
    this.messages = const [],
  });

  SupportChatState copyWith({
    bool? loading,
    bool? sending,
    String? error,
    String? userId,
    String? category,
    String? userName,
    String? userPin,
    List<SupportChatMessage>? messages,
  }) {
    return SupportChatState(
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: error,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      userName: userName ?? this.userName,
      userPin: userPin ?? this.userPin,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [loading, sending, error, userId, category, userName, userPin, messages];
}

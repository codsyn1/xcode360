library chat_list_state.dart;

import 'package:equatable/equatable.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object> get props => [];
}

class ChatListInitial extends ChatListState {
  const ChatListInitial();
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListLoaded extends ChatListState {
  final List<Map<String, dynamic>> chats;
  final String searchQuery;
  final String? activeAgencyId;
  final String? activeAgencyName;
  final String? activeAgencyLogo;

  const ChatListLoaded({
    required this.chats,
    required this.searchQuery,
    this.activeAgencyId,
    this.activeAgencyName,
    this.activeAgencyLogo,
  });

  @override
  List<Object> get props => [chats, searchQuery, activeAgencyId ?? '', activeAgencyName ?? '', activeAgencyLogo ?? ''];
}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError({required this.message});

  @override
  List<Object> get props => [message];
}

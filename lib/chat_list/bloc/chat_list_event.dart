library chat_list_event.dart;

import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object> get props => [];
}

class LoadChatsEvent extends ChatListEvent {
  const LoadChatsEvent();
}

class RefreshChatsEvent extends ChatListEvent {
  const RefreshChatsEvent();
}

class UpdateSearchQueryEvent extends ChatListEvent {
  final String searchQuery;

  const UpdateSearchQueryEvent({required this.searchQuery});

  @override
  List<Object> get props => [searchQuery];
}

class ClearSearchEvent extends ChatListEvent {
  const ClearSearchEvent();
}

class SwitchToAgencyChatEvent extends ChatListEvent {
  final String? agencyId;
  final String? agencyName;
  final String? agencyLogo;

  const SwitchToAgencyChatEvent({
    this.agencyId,
    this.agencyName,
    this.agencyLogo,
  });

  @override
  List<Object> get props => [agencyId ?? '', agencyName ?? '', agencyLogo ?? ''];
}

library chat_list_bloc.dart;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';
import '../services/chat_firebase_service.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  ChatFirebaseService _firebaseService;

  ChatListBloc() : _firebaseService = ChatFirebaseService(userId: ''), super(const ChatListInitial()) {
    on<LoadChatsEvent>(_onLoadChats);
    on<RefreshChatsEvent>(_onRefreshChats);
    on<UpdateSearchQueryEvent>(_onUpdateSearchQuery);
    on<ClearSearchEvent>(_onClearSearch);
    on<SwitchToAgencyChatEvent>(_onSwitchToAgencyChat);
  }

  void setUserId(String userId) {
    _firebaseService = ChatFirebaseService(userId: userId);
  }

  Future<void> _onLoadChats(LoadChatsEvent event, Emitter<ChatListState> emit) async {
    emit(const ChatListLoading());
    try {
      final chats = await _firebaseService.getSortedChats();
      emit(ChatListLoaded(chats: chats, searchQuery: ''));
    } catch (e) {
      emit(ChatListError(message: e.toString()));
    }
  }

  Future<void> _onRefreshChats(RefreshChatsEvent event, Emitter<ChatListState> emit) async {
    emit(const ChatListLoading());
    try {
      final chats = await _firebaseService.getSortedChats();
      emit(ChatListLoaded(chats: chats, searchQuery: ''));
    } catch (e) {
      emit(ChatListError(message: e.toString()));
    }
  }

  void _onUpdateSearchQuery(UpdateSearchQueryEvent event, Emitter<ChatListState> emit) {
    final currentState = state;
    if (currentState is ChatListLoaded) {
      emit(ChatListLoaded(
        chats: currentState.chats,
        searchQuery: event.searchQuery,
        activeAgencyId: currentState.activeAgencyId,
        activeAgencyName: currentState.activeAgencyName,
        activeAgencyLogo: currentState.activeAgencyLogo,
      ));
    }
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<ChatListState> emit) {
    final currentState = state;
    if (currentState is ChatListLoaded) {
      emit(ChatListLoaded(
        chats: currentState.chats,
        searchQuery: '',
        activeAgencyId: currentState.activeAgencyId,
        activeAgencyName: currentState.activeAgencyName,
        activeAgencyLogo: currentState.activeAgencyLogo,
      ));
    }
  }

  void _onSwitchToAgencyChat(SwitchToAgencyChatEvent event, Emitter<ChatListState> emit) {
    final currentState = state;
    if (currentState is ChatListLoaded) {
      // If agencyId is null, switch back to chat list mode
      if (event.agencyId == null) {
        emit(ChatListLoaded(
          chats: currentState.chats,
          searchQuery: currentState.searchQuery,
          activeAgencyId: null,
          activeAgencyName: null,
          activeAgencyLogo: null,
        ));
      } else {
        // Switch to agency chat mode
        emit(ChatListLoaded(
          chats: currentState.chats,
          searchQuery: currentState.searchQuery,
          activeAgencyId: event.agencyId,
          activeAgencyName: event.agencyName,
          activeAgencyLogo: event.agencyLogo,
        ));
      }
    }
  }
}

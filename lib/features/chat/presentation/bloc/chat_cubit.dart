import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repo;
  late String _currentUserId;
  late String _profileUserId;
  ChatCubit(this.repo) : super(const ChatState());

  Future<void> init({required String currentUserId, required String profileUserId}) async {
    _currentUserId = currentUserId;
    _profileUserId = profileUserId;
    await Future.wait([
      _loadPlan(),
      _loadSentExchangeCount(),
      repo.markIncomingMessagesAsSeen(_currentUserId, _profileUserId),
    ]);
  }

  Future<void> _loadPlan() async {
    emit(state.copyWith(planLoading: true));
    final plan = await repo.getUserPlan(_currentUserId);
    emit(state.copyWith(planLoading: false, currentUserPlan: plan));
  }

  Future<void> _loadSentExchangeCount() async {
    emit(state.copyWith(countLoading: true));
    final count = await repo.getActiveSentExchangeCount(_currentUserId, _profileUserId);
    emit(state.copyWith(countLoading: false, sentExchangeCount: count));
  }

  void toggleEmojiPicker() {
    emit(state.copyWith(showEmojiPicker: !state.showEmojiPicker));
  }

  Future<void> refreshExchangeCount() => _loadSentExchangeCount();

  Future<void> sendMessage(String text) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true));
    try {
      await repo.sendMessage(currentUserId: _currentUserId, profileUserId: _profileUserId, text: text);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      emit(state.copyWith(sending: false));
    }
  }
}

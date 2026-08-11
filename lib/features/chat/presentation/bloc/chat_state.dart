import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final bool planLoading;
  final bool countLoading;
  final bool sending;
  final String currentUserPlan;
  final int sentExchangeCount;
  final bool showEmojiPicker;
  final String? error;

  const ChatState({
    this.planLoading = false,
    this.countLoading = false,
    this.sending = false,
    this.currentUserPlan = 'Free',
    this.sentExchangeCount = 0,
    this.showEmojiPicker = false,
    this.error,
  });

  ChatState copyWith({
    bool? planLoading,
    bool? countLoading,
    bool? sending,
    String? currentUserPlan,
    int? sentExchangeCount,
    bool? showEmojiPicker,
    String? error,
  }) {
    return ChatState(
      planLoading: planLoading ?? this.planLoading,
      countLoading: countLoading ?? this.countLoading,
      sending: sending ?? this.sending,
      currentUserPlan: currentUserPlan ?? this.currentUserPlan,
      sentExchangeCount: sentExchangeCount ?? this.sentExchangeCount,
      showEmojiPicker: showEmojiPicker ?? this.showEmojiPicker,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        planLoading,
        countLoading,
        sending,
        currentUserPlan,
        sentExchangeCount,
        showEmojiPicker,
        error,
      ];
}

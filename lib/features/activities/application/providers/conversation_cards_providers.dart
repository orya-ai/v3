import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; // For ListEquality
import '../../data/models/conversation_card_item.dart';

const _uuid = Uuid();

// 1. Card Data Model & Provider for initial questions
final conversationQuestionsProvider = Provider<List<ConversationCardItem>>((ref) {
  final questions = [
    "What’s something you’re proud of that you rarely get to talk about?",
    "If you could relive one ordinary day exactly as it happened, which day would you choose and why?",
    "What topic could you happily research for the rest of your life?",
    "What’s a belief you held five years ago that you’ve since revised?",
    "Who outside your family has influenced you most, and how did they earn that influence?",
    "What’s a small act of kindness someone showed you that you still remember?",
    "When do you feel most like the “real” you?",
    "What’s a fear you’re actively working on overcoming right now?",
    "What does “home” feel like to you?",
    "Which fictional character do you relate to most, and what does that say about you?",
    "If time and money were no object, what problem in the world would you tackle first?",
    "What song or piece of art has moved you unexpectedly?",
    "What do you think your 80-year-old self would thank you for doing today?",
    "What’s one assumption people often make about you that isn’t true?",
    "Which conversation in your life changed your mind the most?",
    "How do you recharge when the world feels overwhelming?",
    "What role does spirituality (in any form) play in your life right now?",
    "What’s a habit you admire in others but struggle to maintain yourself?",
    "If a close friend described you in three adjectives, what do you hope they’d choose—and why?",
    "What’s the best compliment you’ve ever received?",
    "When have you felt most connected to nature?",
    "What’s an unpopular opinion you hold—about something trivial?",
    "Who knows you best, and what do they “get” that most people miss?",
    "What question do you wish people asked you more often?",
    "Looking back a year from now, what story do you hope we’ll be telling about tonight?",
  ];

  return questions.map((q) => ConversationCardItem(id: _uuid.v4(), question: q)).toList();
});

// 2. Card Stack State
class CardStackState {
  final List<ConversationCardItem> cardItems;
  final int currentCardIndex; // Index of the card considered 'top'

  const CardStackState({
    required this.cardItems,
    this.currentCardIndex = 0,
  });

  CardStackState copyWith({
    List<ConversationCardItem>? cardItems,
    int? currentCardIndex,
  }) {
    return CardStackState(
      cardItems: cardItems ?? this.cardItems,
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is CardStackState &&
      runtimeType == other.runtimeType &&
      const ListEquality().equals(cardItems, other.cardItems) &&
      currentCardIndex == other.currentCardIndex;

  @override
  int get hashCode => const ListEquality().hash(cardItems) ^ currentCardIndex.hashCode;
}

// 3. Card Stack Notifier
class CardStackNotifier extends StateNotifier<CardStackState> {
  final Ref _ref;
  CardStackNotifier(this._ref) : super(const CardStackState(cardItems: [])) {
    _initializeStack();
  }

  void _initializeStack() {
    final initialQuestions = _ref.read(conversationQuestionsProvider);
    state = CardStackState(cardItems: List.from(initialQuestions), currentCardIndex: 0);
  }

  void swipeTopCard() {
    if (state.cardItems.isEmpty || state.currentCardIndex >= state.cardItems.length) {
      // No cards left to swipe or index out of bounds
      return;
    }
    // In a real app, you might remove the card or mark it as swiped.
    // For now, we'll just advance the index to simulate the next card appearing.
    // If you want to actually remove, you'd do:
    // final newItems = List<ConversationCardItem>.from(state.cardItems);
    // newItems.removeAt(state.currentCardIndex);
    // state = state.copyWith(cardItems: newItems);
    // If removing, ensure currentCardIndex logic is robust (e.g., doesn't exceed new length)

    // For this phase, let's assume swiping advances to the next card if available.
    // The actual removal/management of the list will be refined in Phase 3.
    if (state.currentCardIndex < state.cardItems.length -1) {
         state = state.copyWith(currentCardIndex: state.currentCardIndex + 1);
    } else {
        // Last card was swiped, handle 'all cards swiped' state (Phase 4)
        // For now, we can just signify no more cards by setting index beyond list or clearing list.
        // Let's keep the items but advance index to signify it's 'done' for now.
        state = state.copyWith(currentCardIndex: state.cardItems.length); 
    }
  }

  void resetStack() {
    _initializeStack();
  }

  ConversationCardItem? get topCard {
    if (state.cardItems.isNotEmpty && state.currentCardIndex < state.cardItems.length) {
      return state.cardItems[state.currentCardIndex];
    }
    return null;
  }
}

// 4. StateNotifierProvider for the CardStackNotifier
final cardStackControllerProvider = StateNotifierProvider<CardStackNotifier, CardStackState>((ref) {
  return CardStackNotifier(ref);
});

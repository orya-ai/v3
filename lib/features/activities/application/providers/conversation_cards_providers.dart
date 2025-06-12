import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; // For ListEquality
import '../../data/models/conversation_card_item.dart';

const _uuid = Uuid();

// 1. Card Data Model & Provider for initial questions
final conversationQuestionsProvider = Provider<List<ConversationCardItem>>((ref) {
  return List.generate(
    25,
    (index) => ConversationCardItem(
      id: _uuid.v4(),
      question: 'Placeholder Question ${index + 1}: What is your favorite color?',
    ),
  );
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

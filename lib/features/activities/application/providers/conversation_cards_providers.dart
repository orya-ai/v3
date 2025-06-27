import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; // For ListEquality
import '../../data/models/conversation_card_item.dart';

const _uuid = Uuid();

// 1. Enum for question categories
enum ConversationCategory {
  Basic,
  IceBreakers,
  Deep,
  Deepest,
}

// Extension to get a display-friendly name for the enum
extension ConversationCategoryExtension on ConversationCategory {
  String get name {
    switch (this) {
      case ConversationCategory.Basic:
        return 'Basic';
      case ConversationCategory.IceBreakers:
        return 'Ice Breakers';
      case ConversationCategory.Deep:
        return 'Deep';
      case ConversationCategory.Deepest:
        return 'Deepest';
    }
  }
}

// 2. Provider to hold the currently selected category, defaulting to 'Deep'
final selectedCategoryProvider = StateProvider<ConversationCategory>((ref) => ConversationCategory.Deep);

// 3. Provider for all question sets
final allQuestionsProvider = Provider<Map<ConversationCategory, List<String>>>((ref) {
  return {
    ConversationCategory.Basic: [
      "Where did you grow up, and what’s one thing that place taught you about life?",
      "What do you spend most of your time doing on a typical weekday?",
      "Which three words would close friends use to describe you?",
      "What personal value do you refuse to compromise on?",
      "What topic could you talk about for hours without getting bored?",
      "Which accomplishment makes you feel the proudest so far?",
      "What’s a challenge you’re actively working to overcome right now?",
      "How do you usually recharge when you’re stressed?",
      "Who has influenced your outlook on life the most, and how?",
      "What kind of environments make you feel most alive?",
      "How do you prefer to learn something new—books, videos, hands-on, or conversation?",
      "What’s one regret that has shaped you in a positive way?",
      "If you had an extra free day each week, how would you spend it?",
      "What’s the last thing that genuinely made you laugh out loud?",
      "How do you decide whether to say “yes” or “no” to new opportunities?",
      "What would your ideal weekend look like from start to finish?",
      "Which global issue do you care about most, and why?",
      "What’s a fear you’ve faced that changed you afterward?",
      "How do you measure personal success?",
      "What everyday habit or ritual feels essential to your well-being?",
      "What book, movie, or podcast has shifted your perspective recently?",
      "When do you feel most like yourself—morning, afternoon, or night?",
      "What’s on your short “bucket list” for the next five years?",
      "How would you like people to remember you after a brief encounter?",
      "What question do you wish people asked you when they first meet you?",
    ],
    ConversationCategory.IceBreakers: [
      "What’s your go-to “comfort” movie or TV show?",
      "Which smell instantly transports you back to childhood?",
      "If you could master any skill overnight, what would it be?",
      "What song never fails to lift your mood?",
      "What’s the most memorable meal you’ve ever eaten?",
      "Which three apps could you not live without?",
      "If you had a free plane ticket anywhere tomorrow, where would you go?",
      "What minor super-power would improve your average Tuesday?",
      "What’s a fun fact about your hometown?",
      "Which book or podcast have you recommended most lately?",
      "What tiny daily ritual makes you unexpectedly happy?",
      "If you could invite any fictional character to dinner, who would it be?",
      "What’s the best piece of advice you’ve ever received?",
      "What hobby would you dive into if time and money weren’t an issue?",
      "What’s your favorite way to recharge after a long week?",
      "Which emoji do you use most often, and why?",
      "What surprising talent or party trick do you have?",
      "What’s the last photo you snapped on your phone?",
      "If you could instantly learn one language, which would you pick?",
      "What small act of kindness did you witness (or give) recently?",
      "What was your first job, and what did it teach you?",
      "Which season best matches your personality, and why?",
      "What’s your favorite thing about the city or town you live in now?",
      "If today were a movie title, what would it be?",
      "What goal—big or small—has you excited right now?",
    ],
    ConversationCategory.Deep: [
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
    ],
    ConversationCategory.Deepest: [
      "What childhood wound still echoes in your life today, and how have you tried to heal it?",
      "When have you felt truly seen—and when have you felt painfully invisible?",
      "What belief about yourself do you secretly fear is true, yet desperately hope is not?",
      "Describe a moment you realized you were wrong about someone you love. What shifted inside you?",
      "If you could press “erase” on one memory, knowing it would change who you are, would you do it—and which one?",
      "What’s the most difficult forgiveness you’ve ever offered—or withheld?",
      "Which of your parents’ traits do you most worry about repeating, and how do you grapple with that?",
      "Tell me about a time you felt unconditional love. What made it feel that way?",
      "What regret still stings, and what lesson does it keep trying to teach you?",
      "When did you first confront the reality of your own mortality, and how did it alter your choices?",
      "What secret ambition have you protected from the world because failure would feel unbearable?",
      "How has your definition of “home” evolved with loss or change?",
      "Describe the hardest boundary you ever set. What did it cost you—and what did it save?",
      "What does emotional safety look like for you, and when have you felt it most and least?",
      "If you could ask one person (living or dead) a single honest question, who would it be and what would you ask?",
      "What aspect of your identity felt non-negotiable until life forced you to rethink it?",
      "When have you been most tempted to give up on yourself—and what pulled you back?",
      "Which relationship ending taught you the deepest lesson about love, and what was it?",
      "What story about your family do you keep retelling, and why do you think it still holds power?",
      "Describe a promise you made to yourself that you still struggle to keep.",
      "If you knew with certainty no one would judge you, what truth would you speak aloud tonight?",
      "What emotion do you find hardest to sit with, and how does it usually show up?",
      "When did you last experience genuine awe, and how did it change your perspective afterward?",
      "What part of your life feels “unfinished,” and what needs to happen for it to feel complete?",
      "Looking back from the end of your life, what single risk do you think you’ll be happiest you took—or saddest you avoided?",
    ],
  };
});

// 4. Provider that generates card items based on the selected category
final conversationQuestionsProvider = Provider<List<ConversationCardItem>>((ref) {
  final random = Random();
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final allQuestions = ref.watch(allQuestionsProvider);
  final questions = allQuestions[selectedCategory] ?? [];

  return questions.map((q) {
    final rotation = (random.nextDouble() * 1.5 + 1.5) * (random.nextBool() ? 1 : -1) * (pi / 180);
    final offset = Offset(
      (random.nextDouble() * 2 + 4) * (random.nextBool() ? 1 : -1),
      (random.nextDouble() * 2 + 4) * (random.nextBool() ? 1 : -1),
    );

    return ConversationCardItem(
      id: _uuid.v4(),
      question: q,
      rotation: rotation,
      offset: offset,
    );
  }).toList();
});


// 5. Card Stack State
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

// 6. Card Stack Notifier
class CardStackNotifier extends StateNotifier<CardStackState> {
  final Ref _ref;
  CardStackNotifier(this._ref) : super(const CardStackState(cardItems: [])) {
    // Listen to the selectedCategoryProvider to reset the stack when the category changes.
    _ref.listen(selectedCategoryProvider, (_, __) {
      resetStack();
    });
    _initializeStack();
  }

  void _initializeStack() {
    final initialQuestions = _ref.read(conversationQuestionsProvider);
    state = CardStackState(cardItems: List.from(initialQuestions), currentCardIndex: 0);
  }

  void swipeTopCard() {
    if (state.cardItems.isEmpty || state.currentCardIndex >= state.cardItems.length) {
      return;
    }
    
    if (state.currentCardIndex < state.cardItems.length - 1) {
         state = state.copyWith(currentCardIndex: state.currentCardIndex + 1);
    } else {
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

// 7. StateNotifierProvider for the CardStackNotifier
final cardStackControllerProvider = StateNotifierProvider<CardStackNotifier, CardStackState>((ref) {
  return CardStackNotifier(ref);
});
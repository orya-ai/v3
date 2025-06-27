import 'dart:math';
import 'dart:ui'; // For lerpDouble and Offset.lerp
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import '../application/providers/conversation_cards_providers.dart';
import './widgets/conversation_card_widget.dart';
import 'package:go_router/go_router.dart'; // Import go_router

class ConversationCardsPage extends ConsumerStatefulWidget {
  const ConversationCardsPage({super.key});

  static const String routeName = '/conversation-cards';

  @override
  ConsumerState<ConversationCardsPage> createState() => _ConversationCardsPageState();
}

enum SwipeDirection { left, right, up, down }

class _ConversationCardsPageState extends ConsumerState<ConversationCardsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  Offset _dragPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_animationController)
      ..addListener(() {
        setState(() {
          _dragPosition = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _animationController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final dragThresholdX = screenSize.width * 0.4;
    final dragThresholdY = screenSize.height * 0.3; // Threshold for vertical swipe
    final velocity = details.velocity.pixelsPerSecond;

    // Check for horizontal swipe
    if (_dragPosition.dx.abs() > dragThresholdX || velocity.dx.abs() > 1000) {
      if (_dragPosition.dx > 0) {
        _triggerSwipeAnimation(SwipeDirection.right);
      } else {
        _triggerSwipeAnimation(SwipeDirection.left);
      }
    // Check for vertical swipe
    } else if (_dragPosition.dy.abs() > dragThresholdY || velocity.dy.abs() > 1000) {
      if (_dragPosition.dy > 0) {
        _triggerSwipeAnimation(SwipeDirection.down);
      } else {
        _triggerSwipeAnimation(SwipeDirection.up);
      }
    } else {
      _triggerSnapBackAnimation();
    }
  }

  void _triggerSwipeAnimation(SwipeDirection direction) {
    final screenSize = MediaQuery.of(context).size;
    double endX = _dragPosition.dx;
    double endY = _dragPosition.dy;

    switch (direction) {
      case SwipeDirection.left:
        endX = -screenSize.width * 1.5;
        break;
      case SwipeDirection.right:
        endX = screenSize.width * 1.5;
        break;
      case SwipeDirection.up:
        endY = -screenSize.height * 1.5;
        break;
      case SwipeDirection.down:
        endY = screenSize.height * 1.5;
        break;
    }

    _animation = Tween<Offset>(begin: _dragPosition, end: Offset(endX, endY))
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward(from: 0).whenComplete(() {
      HapticFeedback.mediumImpact(); // Add haptic feedback
      ref.read(cardStackControllerProvider.notifier).swipeTopCard();
      _animationController.reset();
      setState(() {
        _dragPosition = Offset.zero;
      });
    });
  }

  void _triggerSnapBackAnimation() {
    _animation = Tween<Offset>(begin: _dragPosition, end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cardStackState = ref.watch(cardStackControllerProvider);
    final cardStackNotifier = ref.read(cardStackControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Starters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryButtons(context, ref),
            Expanded(
              child: cardStackState.cardItems.isEmpty || cardStackState.currentCardIndex >= cardStackState.cardItems.length
                  ? _buildAllCardsSwipedView(cardStackNotifier)
                  : GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Stack(
                        alignment: Alignment.center,
                        children: _buildCardStack(context, cardStackState),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButtons(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ConversationCategory.values.map((category) {
          final isSelected = category == selectedCategory;
          return ElevatedButton(
            onPressed: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
              foregroundColor: isSelected ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            child: Text(category.name),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildCardStack(BuildContext context, CardStackState cardStackState) {
    final cardItems = cardStackState.cardItems;
    final topIndex = cardStackState.currentCardIndex;
    final screenWidth = MediaQuery.of(context).size.width;
    List<Widget> cards = [];

    const double cardVerticalPeekingOffset = 10.0;
    const double cardScaleDecrement = 0.04;
    const int desiredUnderlyingCardCount = 4;
    final int visibleStackDepth = (desiredUnderlyingCardCount + 1);

    // Show up to (desiredUnderlyingCardCount) underlying cards to create a visible stack
    final renderCount = (cardItems.length - topIndex).clamp(0, visibleStackDepth);

    // Use the defined swipe threshold for a more accurate progress value
    final dragThreshold = screenWidth * 0.4;
    final dragProgress = (_dragPosition.dx.abs() / dragThreshold).clamp(0.0, 1.0);

    for (int i = 0; i < renderCount; i++) {
      final cardModelIndex = topIndex + i;
      final currentCardModel = cardItems[cardModelIndex];
      final isTopCard = i == 0;

      if (isTopCard) {
        // The top card is controlled by the user's drag gesture
        final rotationAngle = _dragPosition.dx / screenWidth * (pi / 12); // Approx +/- 15 degrees at full drag
        cards.add(ConversationCardWidget(
          key: ValueKey(currentCardModel.id),
          cardItem: currentCardModel,
          position: _dragPosition,
          angle: rotationAngle,
          scale: 1.0, // Top card is always at full scale
        ));
      } else {
        // --- Resting State for the current card (at stack depth i) ---
        final restingRotation = currentCardModel.rotation; // Pre-calculated random rotation
        final restingBaseOffset = currentCardModel.offset; // Pre-calculated random X/Y jitter
        final restingStackOffsetY = i * cardVerticalPeekingOffset;
        final restingOffset = Offset(restingBaseOffset.dx, restingBaseOffset.dy + restingStackOffsetY);
        final restingScale = 1.0 - (i * cardScaleDecrement);

        // --- Target State for the current card (animates to become the card at stack depth i-1) ---
        double targetRotation;
        Offset targetOffset;
        double targetScale;

        if (i == 1) { // This card is becoming the new top card (stack depth 0)
          targetRotation = 0.0; // Top card has no rotation
          targetOffset = Offset.zero; // Top card has no offset
          targetScale = 1.0; // Top card is full scale
        } else {
          // This card is moving one step up to replace the card that was at stack depth (i-1)
          final cardModelForTargetState = cardItems[topIndex + i - 1];
          targetRotation = cardModelForTargetState.rotation;
          final targetBaseOffset = cardModelForTargetState.offset;
          final targetStackOffsetY = (i - 1) * cardVerticalPeekingOffset;
          targetOffset = Offset(targetBaseOffset.dx, targetBaseOffset.dy + targetStackOffsetY);
          targetScale = 1.0 - ((i - 1) * cardScaleDecrement);
        }

        // Interpolate between resting and target states based on drag progress
        final lerpRotation = lerpDouble(restingRotation, targetRotation, dragProgress)!;
        final lerpOffset = Offset.lerp(restingOffset, targetOffset, dragProgress)!;
        final lerpScale = lerpDouble(restingScale, targetScale, dragProgress)!;

        cards.add(ConversationCardWidget(
          key: ValueKey(currentCardModel.id),
          cardItem: currentCardModel,
          position: lerpOffset,
          angle: lerpRotation,
          scale: lerpScale,
        ));
      }
    }
    // Reverse the list so the top card is rendered last (on top)
    return cards.reversed.toList();
  }

  Widget _buildAllCardsSwipedView(CardStackNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'You\'ve seen all the cards!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              notifier.resetStack();
              setState(() {
                _dragPosition = Offset.zero;
                _animationController.reset();
              });
            },
            child: const Text('Start Over'),
          ),
        ],
      ),
    );
  }
}

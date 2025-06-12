import 'dart:math';
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
    final dragThreshold = screenSize.width * 0.4;

    if (_dragPosition.dx.abs() > dragThreshold) {
      _triggerSwipeAnimation();
    } else {
      _triggerSnapBackAnimation();
    }
  }

  void _triggerSwipeAnimation() {
    final screenSize = MediaQuery.of(context).size;
    final endX = _dragPosition.dx > 0 ? screenSize.width * 1.5 : -screenSize.width * 1.5;
    final endY = _dragPosition.dy;

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
        leading: BackButton(onPressed: () => context.pop()), // Use context.pop() for go_router
        title: const Text('Conversation Cards'),
      ),
      body: Center(
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
    );
  }

  List<Widget> _buildCardStack(BuildContext context, CardStackState cardStackState) {
    final cards = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width;

    // Only render the top two cards for performance
    final renderCount = (cardStackState.cardItems.length - cardStackState.currentCardIndex).clamp(0, 2);

    for (int i = 0; i < renderCount; i++) {
      final cardIndex = cardStackState.currentCardIndex + i;
      final cardItem = cardStackState.cardItems[cardIndex];
      final isTopCard = i == 0;

      if (isTopCard) {
        final rotationAngle = _dragPosition.dx / screenWidth * (pi / 12);
        cards.add(ConversationCardWidget(
          key: ValueKey(cardItem.id),
          cardItem: cardItem,
          position: _dragPosition,
          angle: rotationAngle,
        ));
      } else {
        // Card underneath
        final dragProgress = (_dragPosition.dx.abs() / screenWidth).clamp(0.0, 1.0);
        final scale = (0.95 + (dragProgress * 0.05)).clamp(0.95, 1.0);
        final offset = Offset(0, -10 + 10 * dragProgress);

        cards.add(ConversationCardWidget(
          key: ValueKey(cardItem.id),
          cardItem: cardItem,
          scale: scale,
          position: offset,
        ));
      }
    }
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

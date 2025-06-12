import 'package:flutter/material.dart';
import '../../data/models/conversation_card_item.dart';

class ConversationCardWidget extends StatelessWidget {
  final ConversationCardItem cardItem;
  final Offset position;
  final double angle;
  final double scale;

  const ConversationCardWidget({
    super.key,
    required this.cardItem,
    this.position = Offset.zero,
    this.angle = 0,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: position,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: _buildCardContent(context),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = cardWidth * (3.5 / 2.5);
    final bool isTopCard = scale > 0.99; // Top card is at scale 1.0, others are smaller

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: isTopCard
            ? [
                // A sharper, closer shadow for edge definition
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                // A softer, more diffuse shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                // A single, more subtle shadow for underlying cards
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Text(
          cardItem.question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

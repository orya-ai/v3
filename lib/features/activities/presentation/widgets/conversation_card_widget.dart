import 'package:flutter/material.dart';

class ConversationCardWidget extends StatelessWidget {
  final String questionText;

  const ConversationCardWidget({
    super.key,
    required this.questionText,
  });

  @override
  Widget build(BuildContext context) {
    // Approximate dimensions for a card-like feel on a typical phone screen
    // These can be adjusted based on testing and desired look
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85; // Card takes up 85% of screen width
    final cardHeight = cardWidth * (3.5 / 2.5); // Standard playing card aspect ratio (approx)

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4), // changes position of shadow
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Text(
          questionText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20.0, // Adjust as needed
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

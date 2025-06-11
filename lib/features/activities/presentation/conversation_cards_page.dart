import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './widgets/conversation_card_widget.dart'; // Import the card widget

class ConversationCardsPage extends ConsumerWidget {
  const ConversationCardsPage({super.key});

  static const String routeName = '/conversation-cards'; // Or your preferred route name

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Cards'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ConversationCardWidget(
              questionText: 'What\'s a skill you\'d love to learn and why?',
            ),
            SizedBox(height: 20), // Add some spacing if displaying multiple cards vertically for now
            // You can uncomment this to see a second card, though they will just stack vertically for now.
            // ConversationCardWidget(
            //   questionText: 'If you could travel anywhere, where would you go first?',
            // ),
          ],
        ),
      ),
    );
  }
}

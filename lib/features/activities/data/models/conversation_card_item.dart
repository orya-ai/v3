import 'package:flutter/foundation.dart';

@immutable
class ConversationCardItem {
  final String id;
  final String question;

  const ConversationCardItem({
    required this.id,
    required this.question,
  });

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ConversationCardItem &&
      runtimeType == other.runtimeType &&
      id == other.id &&
      question == other.question;

  @override
  int get hashCode => id.hashCode ^ question.hashCode;

  ConversationCardItem copyWith({
    String? id,
    String? question,
  }) {
    return ConversationCardItem(
      id: id ?? this.id,
      question: question ?? this.question,
    );
  }
}

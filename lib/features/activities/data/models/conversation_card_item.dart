import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class ConversationCardItem {
  final String id;
    final String question;
  final double rotation; // In radians
  final Offset offset;

    const ConversationCardItem({
    required this.id,
    required this.question,
    required this.rotation,
    required this.offset,
  });

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ConversationCardItem &&
      runtimeType == other.runtimeType &&
            id == other.id &&
      question == other.question &&
      rotation == other.rotation &&
      offset == other.offset;

  @override
    int get hashCode => id.hashCode ^ question.hashCode ^ rotation.hashCode ^ offset.hashCode;

    ConversationCardItem copyWith({
    String? id,
    String? question,
    double? rotation,
    Offset? offset,
  }) {
        return ConversationCardItem(
      id: id ?? this.id,
      question: question ?? this.question,
      rotation: rotation ?? this.rotation,
      offset: offset ?? this.offset,
    );
  }
}

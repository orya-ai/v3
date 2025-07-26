import 'package:cloud_firestore/cloud_firestore.dart';

class Quest {
  final String title;
  final String points;
  final DateTime completedAt;

  Quest({
    required this.title,
    required this.points,
    required this.completedAt,
  });

  factory Quest.fromFirestore(Map<String, dynamic> data) {
    return Quest(
      title: data['title'] ?? '',
      points: data['points'] ?? '0',
      completedAt: (data['completedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'points': points,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}

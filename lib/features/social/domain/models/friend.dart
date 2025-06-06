import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final DateTime connectedSince;
  final bool isOnline;

  Friend({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.connectedSince,
    this.isOnline = false,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      connectedSince: (json['connectedSince'] as Timestamp).toDate(),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'connectedSince': Timestamp.fromDate(connectedSince),
      'isOnline': isOnline,
    };
  }

  Friend copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? photoUrl,
    DateTime? connectedSince,
    bool? isOnline,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      connectedSince: connectedSince ?? this.connectedSince,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

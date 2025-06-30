import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}

class FriendRequest {
  final String id;
  final String senderId;
  final String recipientId;
  final String senderDisplayName;
  final String? senderPhotoUrl;
  final DateTime createdAt;
  final FriendRequestStatus status;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.senderDisplayName,
    this.senderPhotoUrl,
    required this.createdAt,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => FriendRequestStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'senderDisplayName': senderDisplayName,
      'senderPhotoUrl': senderPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? senderDisplayName,
    String? senderPhotoUrl,
    DateTime? createdAt,
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

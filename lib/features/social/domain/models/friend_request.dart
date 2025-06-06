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
  final DateTime timestamp;
  final FriendRequestStatus status;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.senderDisplayName,
    this.senderPhotoUrl,
    required this.timestamp,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
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
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
    };
  }

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? senderDisplayName,
    String? senderPhotoUrl,
    DateTime? timestamp,
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}

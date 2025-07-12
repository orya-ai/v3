import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String emailLowercase;
  final String displayNameLowercase;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailLowercase,
    required this.displayNameLowercase,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'emailLowercase': emailLowercase,
      'displayNameLowercase': displayNameLowercase,
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      emailLowercase: data['emailLowercase'] ?? '',
      displayNameLowercase: data['displayNameLowercase'] ?? '',
    );
  }
}

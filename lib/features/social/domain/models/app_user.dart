class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String emailLowercase;
  final String displayNameLowercase;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    String? emailLowercase,
    String? displayNameLowercase,
  }) : emailLowercase = emailLowercase ?? email.toLowerCase(),
       displayNameLowercase = displayNameLowercase ?? displayName.toLowerCase();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      emailLowercase: json['email_lowercase'] as String?,
      displayNameLowercase: json['displayName_lowercase'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'email_lowercase': emailLowercase,
      'displayName': displayName,
      'displayName_lowercase': displayNameLowercase,
      'photoUrl': photoUrl,
    };
  }
}

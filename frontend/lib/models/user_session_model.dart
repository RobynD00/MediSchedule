
/// Represents an authenticated user session containing user metadata and JWT token.
class UserSession {
  final String uid;
  final String email;
  final String name;
  final String token;
  final bool isVerified;

  UserSession({
    required this.uid,
    required this.email,
    required this.name,
    required this.token,
    required this.isVerified,
  });

  /// Factory constructor to create a [UserSession] from JSON response map.
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      token: json['token'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }

  /// Converts the session instance into a JSON map for local storage persistence.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'token': token,
      'isVerified': isVerified,
    };
  }
}

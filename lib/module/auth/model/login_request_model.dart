/// The body of `POST /auth/login`.
///
/// The route's body is strict — anything beyond `email`, `password` and
/// `rememberMe` may be refused with a 400 — so nothing else goes out.
class LoginRequestModel {
  final String email;
  final String password;

  /// Asks for a 30-day refresh token instead of the default 7 days.
  final bool rememberMe;

  LoginRequestModel({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
    if (rememberMe) 'rememberMe': true,
  };

  Map<String, dynamic> toMap() => toJson();
}

class LoginResponse {
  final String userId;
  final String accessToken;
  final String refreshToken;
  final String name;
  final String email;
  final String role;
  final String preferredLanguage;

  LoginResponse({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.name,
    required this.email,
    required this.role,
    required this.preferredLanguage,
  });

  factory LoginResponse.fromMap(Map<String, dynamic> map) {
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : <String, dynamic>{};
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;

    return LoginResponse(
      userId: (user['_id'] ?? user['id'] ?? '').toString(),
      accessToken: (data['accessToken'] ?? data['access_token'] ?? '')
          .toString(),
      refreshToken: (data['refreshToken'] ?? data['refresh_token'] ?? '')
          .toString(),
      name:
          (user['fullName'] ??
                  user['name'] ??
                  user['username'] ??
                  user['firstName'] ??
                  '')
              .toString(),
      email: (user['email'] ?? '').toString(),
      role: (user['role'] ?? '').toString(),
      preferredLanguage: (user['preferredLanguage'] ?? 'en').toString(),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? '',
    );
  }
}

class SignupModel {
  final String username;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String preferredLanguage;
  final String? lastName;

  SignupModel({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    this.preferredLanguage = 'en',
    this.lastName,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username.trim(),
      'phoneNumber': phoneNumber.trim(),
      'email': email.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
      'preferredLanguage': preferredLanguage.trim().isEmpty
          ? 'en'
          : preferredLanguage.trim(),
    };

    if ((lastName ?? '').trim().isNotEmpty) {
      map['lastName'] = lastName!.trim();
    }

    return map;
  }
}

class SignupResponse {
  final bool success;
  final String message;
  final SignupResponseData? data;

  const SignupResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SignupResponse.fromMap(Map<String, dynamic> map) {
    final dataMap = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : null;

    return SignupResponse(
      success: map['success'] == true,
      message: (map['message'] ?? '').toString(),
      data: dataMap == null ? null : SignupResponseData.fromMap(dataMap),
    );
  }
}

class SignupResponseData {
  final String accessToken;
  final String? expiresAt;
  final SignupUser? user;

  const SignupResponseData({
    required this.accessToken,
    this.expiresAt,
    this.user,
  });

  factory SignupResponseData.fromMap(Map<String, dynamic> map) {
    final userMap = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : null;

    return SignupResponseData(
      accessToken: (map['accessToken'] ?? '').toString(),
      expiresAt: map['expiresAt']?.toString(),
      user: userMap == null ? null : SignupUser.fromMap(userMap),
    );
  }
}

class SignupUser {
  final String id;
  final String role;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String preferredLanguage;
  final String avatarUrl;

  const SignupUser({
    required this.id,
    required this.role,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.preferredLanguage,
    required this.avatarUrl,
  });

  factory SignupUser.fromMap(Map<String, dynamic> map) {
    return SignupUser(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      firstName: (map['firstName'] ?? '').toString(),
      lastName: (map['lastName'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phoneNumber: (map['phoneNumber'] ?? '').toString(),
      preferredLanguage: (map['preferredLanguage'] ?? 'en').toString(),
      avatarUrl: (map['avatarUrl'] ?? '').toString(),
    );
  }
}

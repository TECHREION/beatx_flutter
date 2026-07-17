class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequest(
      currentPassword: json['currentPassword'] ?? '',
      newPassword: json['newPassword'] ?? '',
      confirmPassword: json['confirmPassword'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

class ChangePasswordResponse {
  final bool status;
  final String message;
  final Object? data;
  final DateTime? timestamp;
  final String path;
  final ChangePasswordMetadata metadata;

  const ChangePasswordResponse({
    required this.status,
    required this.message,
    this.data,
    this.timestamp,
    required this.path,
    required this.metadata,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : <String, dynamic>{};

    return ChangePasswordResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'],
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()),
      path: (json['path'] ?? '').toString(),
      metadata: ChangePasswordMetadata.fromJson(metadata),
    );
  }
}

class ChangePasswordMetadata {
  final String duration;

  const ChangePasswordMetadata({required this.duration});

  factory ChangePasswordMetadata.fromJson(Map<String, dynamic> json) {
    return ChangePasswordMetadata(
      duration: (json['duration'] ?? '').toString(),
    );
  }
}

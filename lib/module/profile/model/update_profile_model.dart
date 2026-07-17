import 'dart:typed_data';

import 'package:app_pigeon/app_pigeon.dart';

class UserUpdateProfile {
  final String fullName;
  final String email;
  final String phoneNumber;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? imageUrl;

  const UserUpdateProfile({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.imageBytes,
    this.imageName,
    this.imageUrl,
  });

  factory UserUpdateProfile.empty() {
    return const UserUpdateProfile(fullName: '', email: '', phoneNumber: '');
  }

  factory UserUpdateProfile.fromUser(ProfileUserData user) {
    return UserUpdateProfile(
      fullName: user.name,
      email: user.email,
      phoneNumber: '',
      imageUrl: user.avatar,
    );
  }

  UserUpdateProfile copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    Uint8List? imageBytes,
    String? imageName,
    String? imageUrl,
    bool clearImage = false,
  }) {
    return UserUpdateProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageBytes: clearImage ? null : imageBytes ?? this.imageBytes,
      imageName: clearImage ? null : imageName ?? this.imageName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Future<Map<String, dynamic>> toFormMap() async {
    final phone = phoneNumber.trim();

    return {
      'name': fullName.trim(),
      if (phone.isNotEmpty) 'phoneNumber': phone,
      if (imageBytes != null)
        'avatar': MultipartFile.fromBytes(
          imageBytes!,
          filename: imageName ?? 'profile.jpg',
        ),
    };
  }
}

class UpdateProfileResponse {
  final bool status;
  final String message;
  final ProfileUserData data;
  final DateTime? timestamp;
  final String path;
  final Metadata metadata;

  const UpdateProfileResponse({
    required this.status,
    required this.message,
    required this.data,
    this.timestamp,
    required this.path,
    required this.metadata,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : <String, dynamic>{};

    return UpdateProfileResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: ProfileUserData.fromJson(data),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()),
      path: (json['path'] ?? '').toString(),
      metadata: Metadata.fromJson(metadata),
    );
  }
}

class ProfileUserData {
  final String id;
  final String email;
  final String name;
  final String role;
  final String provider;
  final bool isVerified;
  final Settings settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;
  final String? avatar;
  final String? avatarKey;
  final List<String> favoriteArtists;
  final List<String> favoriteGenres;

  const ProfileUserData({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.provider,
    required this.isVerified,
    required this.settings,
    this.createdAt,
    this.updatedAt,
    required this.version,
    this.avatar,
    this.avatarKey,
    required this.favoriteArtists,
    required this.favoriteGenres,
  });

  factory ProfileUserData.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] is Map
        ? Map<String, dynamic>.from(json['settings'] as Map)
        : <String, dynamic>{};

    return ProfileUserData(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      isVerified: json['isVerified'] == true,
      settings: Settings.fromJson(settings),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      version: json['__v'] is int ? json['__v'] as int : 0,
      avatar: json['avatar']?.toString(),
      avatarKey: json['avatarKey']?.toString(),
      favoriteArtists: List<String>.from(json['favoriteArtists'] ?? []),
      favoriteGenres: List<String>.from(json['favoriteGenres'] ?? []),
    );
  }
}

class Settings {
  final String language;
  final String theme;
  final bool enablePasscode;
  final bool allowSms;
  final bool allowEmailNotification;
  final bool trackSearchHistory;
  final bool sendUsageData;
  final bool wifiOnlyMode;

  const Settings({
    required this.language,
    required this.theme,
    required this.enablePasscode,
    required this.allowSms,
    required this.allowEmailNotification,
    required this.trackSearchHistory,
    required this.sendUsageData,
    required this.wifiOnlyMode,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      language: (json['language'] ?? 'en').toString(),
      theme: (json['theme'] ?? 'dark').toString(),
      enablePasscode: json['enablePasscode'] == true,
      allowSms: json['allowSms'] == true,
      allowEmailNotification: json['allowEmailNotification'] == true,
      trackSearchHistory: json['trackSearchHistory'] == true,
      sendUsageData: json['sendUsageData'] == true,
      wifiOnlyMode: json['wifiOnlyMode'] == true,
    );
  }
}

class Metadata {
  final String duration;

  const Metadata({required this.duration});

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(duration: (json['duration'] ?? '').toString());
  }
}

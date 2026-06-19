import 'dart:typed_data';

import 'package:app_pigeon/app_pigeon.dart';

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      name: (map['name'] ?? map['fullName'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
      isVerified: map['isVerified'] == true,
    );
  }

  ProfileModel toProfileModel() => ProfileModel(
    fullName: name,
    email: email,
    phoneNumber: '',
  );
}

class ProfileModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? imageUrl;

  const ProfileModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.imageBytes,
    this.imageName,
    this.imageUrl,
  });

  ProfileModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    Uint8List? imageBytes,
    String? imageName,
    String? imageUrl,
    bool clearImage = false,
  }) {
    return ProfileModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageBytes: clearImage ? null : imageBytes ?? this.imageBytes,
      imageName: clearImage ? null : imageName ?? this.imageName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Future<Map<String, dynamic>> toFormMap() async {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      if (imageBytes != null)
        'avatar': MultipartFile.fromBytes(
          imageBytes!,
          filename: imageName ?? 'profile.jpg',
        ),
      if ((imageUrl ?? '').trim().isNotEmpty) 'imageUrl': imageUrl!.trim(),
    };
  }
}

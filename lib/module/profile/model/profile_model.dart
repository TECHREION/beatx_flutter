import 'dart:typed_data';

import 'package:app_pigeon/app_pigeon.dart';

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

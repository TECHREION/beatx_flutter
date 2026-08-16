import 'dart:typed_data';

import 'package:app_pigeon/app_pigeon.dart';

import 'profile_model.dart';

/// What `PATCH /users/profile` is sent: the name, and the avatar when the
/// user picked a new one.
///
/// Goes out as multipart, since the avatar is a file. [imageUrl] is the
/// avatar already on the account — it is what the screen shows until a new
/// image is picked, and is never uploaded.
class UserUpdateProfile {
  const UserUpdateProfile({
    this.fullName = '',
    this.email = '',
    this.imageBytes,
    this.imageName,
    this.imageUrl,
  });

  final String fullName;

  /// Shown on the form and never sent — the backend does not take an email
  /// change through this endpoint.
  final String email;

  final Uint8List? imageBytes;
  final String? imageName;
  final String? imageUrl;

  factory UserUpdateProfile.empty() => const UserUpdateProfile();

  factory UserUpdateProfile.fromProfile(UserProfileModel user) {
    return UserUpdateProfile(
      fullName: user.name,
      email: user.email,
      imageUrl: user.avatar,
    );
  }

  UserUpdateProfile copyWith({
    String? fullName,
    String? email,
    Uint8List? imageBytes,
    String? imageName,
    String? imageUrl,
    bool clearImage = false,
  }) {
    return UserUpdateProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      imageBytes: clearImage ? null : imageBytes ?? this.imageBytes,
      imageName: clearImage ? null : imageName ?? this.imageName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// The multipart body. Only what the backend takes goes in: it rejects
  /// properties it does not know, so the email on the form is left out.
  FormData toFormData() {
    final name = fullName.trim();
    final bytes = imageBytes;

    return FormData.fromMap({
      if (name.isNotEmpty) 'name': name,
      if (bytes != null)
        'avatar': MultipartFile.fromBytes(
          bytes,
          filename: _filename,
          // Without this dio sends application/octet-stream, which an upload
          // filtering on image mime types turns away.
          contentType: DioMediaType('image', _extension),
        ),
    });
  }

  String get _filename {
    final picked = imageName?.trim() ?? '';
    return picked.isEmpty ? 'avatar.jpg' : picked;
  }

  /// The picked file's extension, normalised to what a mime type expects.
  String get _extension {
    final name = _filename.toLowerCase();
    final dot = name.lastIndexOf('.');

    return switch (dot == -1 ? '' : name.substring(dot + 1)) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      'heif' => 'heif',
      'gif' => 'gif',
      _ => 'jpeg',
    };
  }
}

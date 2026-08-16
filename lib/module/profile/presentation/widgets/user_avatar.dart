import 'dart:typed_data';

import 'package:flutter/material.dart';

/// The user's picture, falling back to the first letter of their name.
///
/// [imageBytes] is a picture picked on the edit screen but not saved yet, and
/// takes precedence over the [avatarUrl] on the account.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.radius,
    required this.initial,
    this.avatarUrl,
    this.imageBytes,
    this.fontSize,
  });

  final double radius;
  final String initial;
  final String? avatarUrl;
  final Uint8List? imageBytes;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    final ImageProvider? image = imageBytes != null
        ? MemoryImage(imageBytes!)
        : url.isEmpty
        ? null
        : NetworkImage(url);

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF222222),
      backgroundImage: image,
      // A picture that fails to load should leave the initial behind it
      // showing rather than an empty circle.
      onBackgroundImageError: image == null ? null : (_, _) {},
      child: image == null
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? radius * 0.7,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

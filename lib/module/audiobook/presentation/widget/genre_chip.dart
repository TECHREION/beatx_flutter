import 'package:flutter/material.dart';

import '../../model/genre_model.dart';

class AudiobookGenreChip extends StatelessWidget {
  const AudiobookGenreChip({super.key, required this.genre});

  final GenreModel genre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: genre.isSelected
            ? const Color(0xFF40DDEB)
            : const Color(0xFF202020),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        genre.title,
        style: TextStyle(
          color: genre.isSelected
              ? const Color(0xFF0E1112)
              : const Color(0xFFAAA5AD),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

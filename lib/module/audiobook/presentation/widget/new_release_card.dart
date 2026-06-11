import 'package:flutter/material.dart';

import '../../model/audiobook_model.dart';

class NewReleaseCard extends StatelessWidget {
  const NewReleaseCard({super.key, required this.book, this.onTap});

  final AudiobookModel book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 212,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 0.82,
                child: Image.asset(
                  book.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(
                        color: Color(0xFF202020),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white38,
                          size: 54,
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFAAA5AD),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

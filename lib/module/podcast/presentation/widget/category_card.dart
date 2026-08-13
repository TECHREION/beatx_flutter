import 'package:flutter/material.dart';

import '../../model/podcast_home_model.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category});

  final TopCategory category;

  static const _tints = [
    Color(0xFF4D314F),
    Color(0xFF176064),
    Color(0xFF4E563B),
    Color(0xFF2E3A6E),
    Color(0xFF6B3A2E),
  ];

  @override
  Widget build(BuildContext context) {
    final tint = _tints[category.name.hashCode.abs() % _tints.length];

    return SizedBox(
      height: 152,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: tint),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white30,
                size: 30,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  if (category.podcastCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${category.podcastCount} podcasts',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

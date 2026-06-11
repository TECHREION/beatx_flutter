import 'package:flutter/material.dart';

import '../../model/podcast_model.dart';

class FeaturedPodcastCard extends StatelessWidget {
  const FeaturedPodcastCard({super.key, required this.podcast});

  final PodcastModel podcast;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.79,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              podcast.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFF202020),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white38,
                  size: 58,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.46, 1],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    podcast.badge,
                    style: const TextStyle(
                      color: Color(0xFFBD89FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    podcast.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    podcast.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFBD89FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    podcast.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE5E1EA),
                      fontSize: 13,
                      height: 1.22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 51,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded, size: 25),
                      label: const Text('LISTEN NOW'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF40DDEB),
                        foregroundColor: const Color(0xFF111315),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

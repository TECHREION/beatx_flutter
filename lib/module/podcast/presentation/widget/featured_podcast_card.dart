import 'package:flutter/material.dart';

import '../../../audiobook/presentation/widget/book_cover.dart';
import '../../model/podcast_home_model.dart';

class FeaturedPodcastCard extends StatelessWidget {
  const FeaturedPodcastCard({
    super.key,
    required this.podcast,
    this.onListenNow,
    this.isLoading = false,
  });

  final FeaturedPodcast podcast;
  final VoidCallback? onListenNow;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.79,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BookCover(
              url: podcast.coverUrl ?? '',
              placeholderIcon: Icons.graphic_eq_rounded,
              iconSize: 58,
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
                  if (podcast.genre.name.isNotEmpty)
                    Text(
                      podcast.genre.name.toUpperCase(),
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
                    podcast.totalEpisodes > 0
                        ? '${podcast.totalEpisodes} episodes'
                        : '',
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
                      onPressed: isLoading ? null : onListenNow,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF111315),
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 25),
                      label: const Text('LISTEN NOW'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF40DDEB),
                        foregroundColor: const Color(0xFF111315),
                        disabledBackgroundColor: const Color(
                          0xFF40DDEB,
                        ).withValues(alpha: 0.6),
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

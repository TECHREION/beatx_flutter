import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../core/common/widget/app_header.dart';
import '../../controller/audiobook_controller.dart';
import '../../model/audiobook_model.dart';
import 'audiobook_detail_screen.dart';
import 'audiobook_new_releases_screen.dart';
import '../widget/bestseller_tile.dart';
import '../widget/continue_listening_card.dart';
import '../widget/genre_chip.dart';
import '../widget/new_release_card.dart';
import '../widget/promo_banner.dart';

class AudiobookScreen extends StatelessWidget {
  const AudiobookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AudiobookController());

    return Scaffold(
        backgroundColor: const Color(0xFF080909),
        body: Stack(
          children: [
            const _AudiobookGlow(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    sliver: SliverList.list(
                      children: [
                        const AppHeader(title: 'Audiobook', notificationBadge: '3'),
                        const SizedBox(height: 30),
                        const Text(
                          'RESUME JOURNEY',
                          style: TextStyle(
                            color: Color(0xFFBD89FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _SectionTitle(title: 'Continue Listening'),
                        const SizedBox(height: 20),
                        Obx(
                          () => ContinueListeningCard(
                            book: controller.continueListening.value,
                            onResume: () => _openDetails(
                              context,
                              controller.continueListening.value,
                            ),
                            onDetails: () => _openDetails(
                              context,
                              controller.continueListening.value,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => ContinueListeningCard(
                            book: controller.queuedBook.value,
                            compact: true,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Obx(
                          () => Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: [
                              for (final genre in controller.genres)
                                AudiobookGenreChip(genre: genre),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: 'New Releases',
                          onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AudiobookNewReleasesScreen(
                                  books: controller.newReleases,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 318,
                          child: Obx(
                            () => ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: controller.newReleases.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) => NewReleaseCard(
                                book: controller.newReleases[index],
                                onTap: () => _openDetails(
                                  context,
                                  controller.newReleases[index],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Bestsellers'),
                        const SizedBox(height: 14),
                        Obx(
                          () => Column(
                            children: [
                              for (final book in controller.bestsellers) ...[
                                BestsellerTile(book: book),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const PromoBanner(),
                        const SizedBox(height: 82),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  }

  void _openDetails(BuildContext context, AudiobookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AudiobookDetailScreen(book: book)),
    );
  }
}

class _AudiobookGlow extends StatelessWidget {
  const _AudiobookGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -78,
      left: 40,
      right: -36,
      child: Container(
        height: 318,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFFB334D7).withValues(alpha: 0.96),
              const Color(0xFF5125B8).withValues(alpha: 0.6),
              const Color(0xFF0C1515).withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0, 0.39, 0.75, 1],
          ),
        ),
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title: title)),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            'View All',
            style: TextStyle(
              color: Color(0xFF9BFF4D),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

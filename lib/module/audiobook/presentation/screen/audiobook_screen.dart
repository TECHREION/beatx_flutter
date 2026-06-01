import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/audiobook_controller.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF202020),
      ),
      child: Scaffold(
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
                        const _AudiobookHeader(),
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
                        const _SectionHeader(title: 'New Releases'),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 306,
                          child: Obx(
                            () => ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: controller.newReleases.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) => NewReleaseCard(
                                book: controller.newReleases[index],
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
      ),
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
        height: 306,
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

class _AudiobookHeader extends StatelessWidget {
  const _AudiobookHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/image/1.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Audiobook',
          style: TextStyle(
            color: Color(0xFF40DDEB),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        const _HeaderIcon(icon: Icons.search_rounded),
        const SizedBox(width: 11),
        const _HeaderIcon(icon: Icons.notifications_rounded, badge: '3'),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.badge});

  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
        if (badge != null)
          Positioned(
            right: 1,
            top: -3,
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE93657),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
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
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title: title)),
        const Text(
          'View All',
          style: TextStyle(
            color: Color(0xFF9BFF4D),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

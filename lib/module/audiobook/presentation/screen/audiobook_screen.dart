import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/common/widget/app_header.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../controller/audiobook_controller.dart';
import '../../model/audiobook_model.dart';
import '../widget/bestseller_tile.dart';
import '../widget/continue_listening_card.dart';
import '../widget/genre_chip.dart';
import '../widget/new_release_card.dart';
import '../widget/promo_banner.dart';
import 'audiobook_detail_screen.dart';
import 'audiobook_new_releases_screen.dart';

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
            child: Column(
              children: [
                const AppHeader(title: 'Audiobook', notificationBadge: '3'),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.fetchHome,
                    backgroundColor: const Color(0xFF202020),
                    color: const Color(0xFF40DDEB),
                    child: Obx(
                      () => CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [_buildBody(context, controller)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildBody(BuildContext context, AudiobookController controller) {
  if (controller.isLoading.value) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator(color: Color(0xFF40DDEB))),
    );
  }

  if (controller.errorMessage.isNotEmpty) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _AudiobookMessage(
        message: controller.errorMessage.value,
        onRetry: controller.fetchHome,
      ),
    );
  }

  if (controller.home.value.isEmpty) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: _AudiobookMessage(message: 'No audiobooks available yet.'),
    );
  }

  return _buildContent(context, controller);
}

Widget _buildContent(BuildContext context, AudiobookController controller) {
  final currentBook = controller.currentBook;
  final queuedBook = controller.queuedBook;
  final newReleases = controller.newReleases;
  final bestsellers = controller.bestsellers;

  return SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSizes.screenHorizontalPadding,
      30,
      AppSizes.screenHorizontalPadding,
      28,
    ),
    sliver: SliverList.list(
      children: [
        if (currentBook != null) ...[
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
          ContinueListeningCard(
            book: currentBook,
            onResume: () => _openDetails(context, currentBook),
            onDetails: () => _openDetails(context, currentBook),
          ),
          const SizedBox(height: 24),
        ],
        if (queuedBook != null) ...[
          GestureDetector(
            onTap: () => _openDetails(context, queuedBook),
            child: ContinueListeningCard(book: queuedBook, compact: true),
          ),
          const SizedBox(height: 18),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final genre in controller.genres)
              AudiobookGenreChip(
                label: genre,
                isSelected: genre == controller.selectedGenre.value,
                onTap: () => controller.selectGenre(genre),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'New Releases',
          onViewAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AudiobookNewReleasesScreen(
                  books: controller.home.value.newReleases,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        if (newReleases.isEmpty)
          const _EmptySection(message: 'No releases in this genre.')
        else
          SizedBox(
            height: 318,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: newReleases.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) => NewReleaseCard(
                book: newReleases[index],
                onTap: () => _openDetails(context, newReleases[index]),
              ),
            ),
          ),
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Bestsellers'),
        const SizedBox(height: 14),
        if (bestsellers.isEmpty)
          const _EmptySection(message: 'No bestsellers yet.')
        else
          for (final book in bestsellers) ...[
            BestsellerTile(
              book: book,
              onTap: () => _openDetails(context, book.toAudiobook()),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 8),
        const PromoBanner(),
        const SizedBox(height: 82),
      ],
    ),
  );
}

void _openDetails(BuildContext context, Audiobook book) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AudiobookDetailScreen(book: book)),
  );
}

class _AudiobookMessage extends StatelessWidget {
  const _AudiobookMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFAAA5AD),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF40DDEB),
                foregroundColor: const Color(0xFF111315),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF77727A),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
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

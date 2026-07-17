import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../controller/explore_controller.dart';

class ExploreScreen extends StatelessWidget {
  ExploreScreen({super.key});

  final ExploreController controller = Get.put(ExploreController());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0B0B0C),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: Stack(
          children: [
            const _ExploreGlow(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ExploreHeader(onBack: () => Navigator.maybePop(context)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenHorizontalPadding,
                      10,
                      AppSizes.screenHorizontalPadding,
                      0,
                    ),
                    child: _SearchField(onChanged: controller.updateSearch),
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.screenHorizontalPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _SectionHeader(
                              title: 'Browse Genres',
                              actionColor: Color(0xFF9BFF4D),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        Obx(
                          () => SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.screenHorizontalPadding,
                            ),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final item = controller.genres[index];
                                return _GenreTile(
                                  title: item.title,
                                  image: item.image,
                                );
                              }, childCount: controller.genres.length),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.84,
                                  ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 30)),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.screenHorizontalPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _SectionHeader(
                              title: 'Recent Searches',
                              action: 'Clear all',
                              actionColor: Colors.white54,
                              onActionTap: controller.clearRecentSearches,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        Obx(() {
                          if (controller.recentTracks.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSizes.screenHorizontalPadding,
                                  18,
                                  AppSizes.screenHorizontalPadding,
                                  0,
                                ),
                                child: Text(
                                  'No recent searches',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            );
                          }

                          return SliverList.builder(
                            itemCount: controller.recentTracks.length,
                            itemBuilder: (context, index) {
                              final track = controller.recentTracks[index];
                              return _RecentTrackTile(
                                image: track.image,
                                title: track.title,
                                artist: track.artist,
                                duration: track.duration,
                              );
                            },
                          );
                        }),
                        const SliverToBoxAdapter(child: SizedBox(height: 34)),
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

class _ExploreGlow extends StatelessWidget {
  const _ExploreGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -128,
      left: 32,
      child: Container(
        width: 310,
        height: 310,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF8044FF).withValues(alpha: 0.78),
              const Color(0xFF121833).withValues(alpha: 0.35),
              Colors.transparent,
            ],
            stops: const [0, 0.46, 1],
          ),
        ),
      ),
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.1),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          const Text(
            'Explore',
            style: TextStyle(
              color: Color(0xFF40DDEB),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, letterSpacing: 0),
      cursorColor: const Color(0xFF40DDEB),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1B1B1D),
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
        suffixIcon: const Icon(Icons.mic_rounded, color: Colors.white70),
        hintText: 'Artists, songs, or podcasts',
        hintStyle: const TextStyle(
          color: Colors.white60,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    this.title,
    this.action,
    this.actionColor,
    this.onActionTap,
  });

  final String? title;
  final String? action;
  final Color? actionColor;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            action ?? '',
            style: TextStyle(
              color: actionColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({required this.title, required this.image});

  final String title;
  final String image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ArtworkImage(asset: image),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.64),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTrackTile extends StatelessWidget {
  const _RecentTrackTile({
    required this.image,
    required this.title,
    required this.artist,
    required this.duration,
  });

  final String image;
  final String title;
  final String artist;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final isNew = duration == 'NEW';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 60,
              height: 60,
              child: _ArtworkImage(asset: image),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$artist - Single',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                duration,
                style: TextStyle(
                  color: isNew
                      ? const Color(0xFF9BFF4D)
                      : const Color(0xFF40DDEB),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.more_vert_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtworkImage extends StatelessWidget {
  const _ArtworkImage({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF40DDEB), Color(0xFF32185F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      ],
    );
  }
}

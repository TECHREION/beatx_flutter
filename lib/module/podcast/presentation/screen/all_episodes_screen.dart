import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/app_back_button.dart';
import '../../../../core/common/widget/load_more.dart';
import '../../../../core/common/widget/mini_player_host.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../controller/podcast_category_controller.dart';
import '../../model/podcast_home_model.dart';
import 'episode_details_screen.dart';
import 'podcast_category_screen.dart';

/// "See all activity": the latest episodes from every show, newest first.
///
/// There is no route for every episode at once, so shows are paged (20 at a
/// time) and the newest few episodes of each are listed; scrolling on loads
/// the next shows' episodes below.
class AllEpisodesScreen extends StatefulWidget {
  const AllEpisodesScreen({super.key});

  @override
  State<AllEpisodesScreen> createState() => _AllEpisodesScreenState();
}

class _AllEpisodesScreenState extends State<AllEpisodesScreen> {
  static const _accent = Color(0xFFBD89FF);

  late final String _tag = 'all-episodes-${identityHashCode(this)}';
  late final PodcastCategoryController _controller = Get.put(
    PodcastCategoryController(categoryId: '', allPodcasts: true),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<PodcastCategoryController>(tag: _tag);
    super.dispose();
  }

  Future<void> _play(RecentEpisode episode) async {
    await _controller.playEpisode(episode);
    if (mounted && _controller.errorMessage.value.isNotEmpty) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: _controller.errorMessage.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF080909),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.screenHorizontalPadding,
                  10,
                  AppSizes.screenHorizontalPadding,
                  14,
                ),
                child: Row(
                  children: [
                    AppBackButton(),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Recent Episodes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.fetchCategory,
                  color: _accent,
                  backgroundColor: const Color(0xFF202020),
                  child: LoadMoreOnScroll(
                    onLoadMore: _controller.loadMore,
                    child: Obx(() {
                      final c = _controller;
                      final episodes = c.episodes.toList();
                      final waiting =
                          (c.isLoading.value || c.isLoadingEpisodes.value) &&
                          episodes.isEmpty;

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (waiting)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _accent,
                                ),
                              ),
                            )
                          else if (episodes.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _Message(
                                text: c.errorMessage.value.isNotEmpty
                                    ? c.errorMessage.value
                                    : 'No episodes yet.',
                                onRetry: c.errorMessage.value.isNotEmpty
                                    ? c.fetchCategory
                                    : null,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.screenHorizontalPadding,
                              ),
                              sliver: SliverList.separated(
                                itemCount: episodes.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final episode = episodes[index];
                                  return CategoryEpisodeTile(
                                    episode: episode,
                                    isLoading:
                                        c.loadingEpisodeId.value == episode.id,
                                    onTap: () => Get.to<void>(
                                      () => EpisodeDetailsScreen(
                                        episode: episode,
                                      ),
                                    ),
                                    onPlay: () => _play(episode),
                                  );
                                },
                              ),
                            ),
                          SliverLoadMoreFooter(
                            loading: c.isLoadingMore.value,
                            color: _accent,
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          // Room to scroll the last items clear of the mini
                          // player.
                          const SliverMiniPlayerSpacer(),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.podcasts_rounded, color: Colors.white38, size: 44),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}

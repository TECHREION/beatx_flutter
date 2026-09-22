import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/theme/responsive.dart';
import '../../controller/notification_controller.dart';
import '../widget/notification_tile.dart';

/// The notification feed, over `GET /notifications`.
///
/// Tapping a row marks it read; the header marks the lot. There is nothing
/// else to do with a notification here, so the screen is a list and two
/// actions rather than a detail flow.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  static const accent = Color(0xFF40DDEB);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ctrl = NotificationController.instance;
  final _scroll = ScrollController();

  static const accent = NotificationScreen.accent;

  @override
  void initState() {
    super.initState();
    // Asked for on every open, so a first fetch that failed — no token yet,
    // or the network was down — is retried here rather than left as an error
    // the user has to tap "Try again" on. A fetch already running is joined.
    ctrl.fetch();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Pulls the next page in once the list is within a screenful of the end,
  /// so the spinner is rarely the thing the user is looking at.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ctrl.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'Notifications',
              subtitle: 'Everything new across your library',
              icon: Icons.notifications_rounded,
              iconColor: accent,
            ),
            const SizedBox(height: 14),
            _MarkAllRow(ctrl: ctrl),
            const SizedBox(height: 4),
            Expanded(
              child: ContentWidth(
                maxWidth: 720,
                child: RefreshIndicator(
                  onRefresh: ctrl.fetch,
                  color: accent,
                  backgroundColor: LikedPalette.card,
                  child: Obx(() {
                    final items = ctrl.notifications;

                    if (ctrl.isLoading.value && items.isEmpty) {
                      return const _Filled(
                        child: CircularProgressIndicator(color: accent),
                      );
                    }

                    if (items.isEmpty) {
                      return _Filled(
                        child: LikedEmptyState(
                          message: ctrl.errorMessage.value,
                          emptyTitle: "You're all caught up",
                          emptyBody:
                              'New episodes, releases and account updates '
                              'will show up here.',
                          accent: accent,
                          onRetry: ctrl.fetch,
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scroll,
                      // Keeps pull-to-refresh reachable while the list is
                      // short.
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        28 + context.pageInset,
                      ),
                      // One extra row for the paging spinner when there is
                      // more to come.
                      itemCount: items.length + (ctrl.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accent,
                                ),
                              ),
                            ),
                          );
                        }

                        final notification = items[index];
                        return NotificationTile(
                          notification: notification,
                          onTap: () => ctrl.markRead(notification),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The unread count and the mark-all action, sat above the list.
class _MarkAllRow extends StatelessWidget {
  const _MarkAllRow({required this.ctrl});

  final NotificationController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unread = ctrl.unreadCount.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                // Held back until a fetch has come back, so "All caught up"
                // never stands in for "not asked yet".
                !ctrl.hasLoaded.value
                    ? ''
                    : unread == 0
                    ? 'All caught up'
                    : '$unread unread',
                style: const TextStyle(
                  color: LikedPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: unread == 0 ? null : ctrl.markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: NotificationScreen.accent,
                disabledForegroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Mark all read'),
            ),
          ],
        ),
      );
    });
  }
}

/// A full-height, still-scrollable body, so pull-to-refresh works while the
/// list is empty.
class _Filled extends StatelessWidget {
  const _Filled({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }
}

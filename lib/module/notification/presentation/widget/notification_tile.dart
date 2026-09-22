import 'package:flutter/material.dart';

import '../../../../core/common/widget/cache/smart_network_image.dart';
import '../../../../core/common/widget/liked_collection.dart';
import '../../model/notification_model.dart';

/// One row of the feed.
///
/// Unread is carried by three things at once — a tinted card, a brighter
/// title and a dot — rather than colour alone, so the state survives a glance
/// and is not lost on someone who cannot pick the tint out.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  static const _accent = Color(0xFF40DDEB);

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final time = notification.relativeTime;

    return Material(
      color: unread ? _accent.withValues(alpha: 0.07) : LikedPalette.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Leading(notification: notification),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread ? Colors.white : Colors.white70,
                              fontSize: 15,
                              height: 1.25,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LikedPalette.muted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0xFF6A6A78),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The artwork when the notification carries one, and a typed icon when it
/// does not — so a row is never left with an empty square.
class _Leading extends StatelessWidget {
  const _Leading({required this.notification});

  final AppNotification notification;

  static const _size = 46.0;

  @override
  Widget build(BuildContext context) {
    final url = notification.imageUrl;
    final (icon, tint) = _iconFor(notification.type);

    if (url != null) {
      return SmartNetworkImage(
        imageUrl: url,
        height: _size,
        width: _size,
        borderRadius: BorderRadius.circular(13),
        placeholder: _fallback(icon, tint),
        errorWidget: _fallback(icon, tint),
      );
    }
    return _fallback(icon, tint);
  }

  Widget _fallback(IconData icon, Color tint) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: tint, size: 22),
  );

  static (IconData, Color) _iconFor(NotificationType type) => switch (type) {
    NotificationType.podcast => (
      Icons.podcasts_rounded,
      const Color(0xFFBD89FF),
    ),
    NotificationType.audiobook => (
      Icons.menu_book_rounded,
      const Color(0xFFFFB45C),
    ),
    NotificationType.song => (
      Icons.music_note_rounded,
      const Color(0xFF40DDEB),
    ),
    NotificationType.video => (
      Icons.play_circle_fill_rounded,
      const Color(0xFF6BE58A),
    ),
    NotificationType.subscription => (
      Icons.workspace_premium_rounded,
      const Color(0xFFFFD166),
    ),
    NotificationType.system => (Icons.shield_rounded, const Color(0xFF8FA6FF)),
    NotificationType.general => (
      Icons.notifications_rounded,
      const Color(0xFF9BA1B0),
    ),
  };
}

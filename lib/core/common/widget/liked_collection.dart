import 'package:flutter/material.dart';

/// Chrome shared by the liked songs and liked podcasts screens: both are the
/// same layout over a different collection, differing only in accent colour
/// and what a row says.

abstract final class LikedPalette {
  static const background = Color(0xFF0A0A0F);
  static const card = Color(0xFF121218);
  static const chip = Color(0xFF1C1C26);
  static const muted = Color(0xFF8B8B99);
  static const heart = Color(0xFFFF4D6D);
}

/// Back button, heart-marked title and strapline.
class LikedHeader extends StatelessWidget {
  const LikedHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Centred on the screen rather than within the space left over
              // beside the back button, so it does not drift.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: LikedPalette.heart.withValues(alpha: 0.16),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: LikedPalette.heart,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: LikedPalette.card,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LikedPalette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// The count strip sitting above the list.
class LikedSummaryStrip extends StatelessWidget {
  const LikedSummaryStrip({
    super.key,
    required this.icon,
    required this.accent,
    required this.count,
    required this.noun,
    this.onTap,
  });

  final IconData icon;
  final Color accent;

  /// Null until the fetch lands, so the strip never reads "0" when that only
  /// means the count is not in yet.
  final int? count;

  /// Singular form; pluralised against [count].
  final String noun;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? noun : '${noun}s';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: LikedPalette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: accent.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (count != null)
                        TextSpan(
                          text: '$count ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      TextSpan(text: label),
                    ],
                  ),
                  style: const TextStyle(
                    color: LikedPalette.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One entry: position, artwork, captions and the two right-hand controls.
class LikedRowCard extends StatelessWidget {
  const LikedRowCard({
    super.key,
    required this.position,
    required this.playing,
    required this.accent,
    required this.coverUrl,
    required this.fallbackIcon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.busy,
    required this.onUnlike,
    required this.onMore,
    this.onTap,
  });

  final int position;
  final bool playing;
  final Color accent;
  final String coverUrl;
  final IconData fallbackIcon;
  final List<Color> gradient;
  final String title;
  final String subtitle;

  /// Genre or category. The pill is dropped when the payload carried none.
  final String tag;
  final bool busy;
  final VoidCallback onUnlike;
  final VoidCallback onMore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LikedPalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: playing
                ? accent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: LikedPalette.chip,
              ),
              child: playing
                  ? Icon(Icons.equalizer_rounded, color: accent, size: 17)
                  : Center(
                      child: Text(
                        '$position',
                        style: const TextStyle(
                          color: LikedPalette.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 58,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: coverUrl.isEmpty
                      ? Icon(fallbackIcon, color: Colors.white, size: 25)
                      : LikedCover(url: coverUrl, size: 58),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: playing ? accent : Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LikedPalette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  if (tag.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: LikedPalette.chip,
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: LikedPalette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 74,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: busy ? null : onUnlike,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: busy
                          ? const Center(
                              child: SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: LikedPalette.muted,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.favorite_rounded,
                              color: LikedPalette.heart,
                              size: 21,
                            ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onMore,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white38,
                        size: 19,
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

class LikedCover extends StatelessWidget {
  const LikedCover({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // A missing cover should leave the gradient behind it showing rather
      // than punch a grey hole in the row.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const SizedBox.shrink(),
    );
  }
}

/// One entry in a row's overflow sheet.
class LikedAction {
  const LikedAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// The sheet behind a row's overflow button.
abstract final class LikedActionsSheet {
  static void show(
    BuildContext context, {
    required String title,
    required List<LikedAction> actions,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LikedPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final action in actions)
              ListTile(
                onTap: () {
                  Navigator.pop(sheetContext);
                  action.onTap();
                },
                leading: Icon(
                  action.icon,
                  color: LikedPalette.muted,
                  size: 21,
                ),
                title: Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class LikedEmptyState extends StatelessWidget {
  const LikedEmptyState({
    super.key,
    required this.message,
    required this.emptyTitle,
    required this.emptyBody,
    required this.accent,
    required this.onRetry,
  });

  /// The failure that left the list empty, or empty when it is simply empty.
  final String message;
  final String emptyTitle;
  final String emptyBody;
  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = message.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.favorite_border_rounded,
            color: Colors.white24,
            size: 54,
          ),
          const SizedBox(height: 18),
          Text(
            failed ? 'Could not load your likes' : emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            failed ? message : emptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LikedPalette.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (failed) ...[
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: accent,
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Color(0xFF0A0A0F),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

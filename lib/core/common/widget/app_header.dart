import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_sizes.dart';
import '../../../module/home/presentation/screens/explore_screen.dart';
import '../../../module/notification/controller/notification_controller.dart';
import '../../../module/notification/presentation/screen/notification_screen.dart';
import '../../../module/onbording/common/app_logo.dart';
import '../../../module/profile/controller/get_profile_controller.dart';
import '../../../module/profile/presentation/screens/my_profile_screen.dart';
import '../../../module/profile/presentation/widgets/user_avatar.dart';

/// Unified top header for every tab screen.
///
/// - [showLogo] = true  → renders the AppLogo (Listen / Home tab)
/// - [showLogo] = false → renders [title] as the screen name (all other tabs)
/// - [onBack] set → a back button takes the profile avatar's place, for
///   pages pushed on top of a tab (artist profile…)
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.showLogo = false,
    this.title,
    this.onSearchTap,
    this.onNotificationTap,
    this.notificationBadge,
    this.onBack,
    this.showActions = true,
    this.titleTrailing,
  });

  final bool showLogo;
  final String? title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  /// Overrides the live unread count on the bell. Left unset everywhere in
  /// the app — the header reads the count from [NotificationController] — and
  /// exists so a screen with its own source of truth can say otherwise.
  final String? notificationBadge;

  /// Shows a back button in place of the profile avatar.
  final VoidCallback? onBack;

  /// False drops the search and notification buttons, for a page that is
  /// about one thing (an artist's profile…).
  final bool showActions;

  /// Shown right after [title], kept beside it when the title is cut short
  /// (an artist's verified badge…).
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenHorizontalPadding,
        18,
        AppSizes.screenHorizontalPadding,
        0,
      ),
      child: Row(
        children: [
          if (onBack != null)
            _ActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack!,
            )
          else
            const _ProfileAvatar(),
          const SizedBox(width: 12),
          if (showLogo)
            const AppLogo(height: 42, width: 128)
          else
            Flexible(
              // Most of the free width, so a long name keeps more of itself.
              flex: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF40DDEB),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (titleTrailing != null) ...[
                    const SizedBox(width: 6),
                    titleTrailing!,
                  ],
                ],
              ),
            ),
          const Spacer(),
          if (showActions) ...[
            _ActionButton(
              icon: Icons.search_rounded,
              onTap: onSearchTap ?? () => Get.to(() => ExploreScreen()),
            ),
            const SizedBox(width: 12),
            _NotificationButton(
              badge: notificationBadge,
              onTap: onNotificationTap,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Profile Avatar ───────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Get.to(() => const ProfileScreen()),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            gradient: const LinearGradient(
              colors: [Color(0xFFD8E9FF), Color(0xFF1B3147)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Obx(() {
            final user = ProfileController.instance.profile.value;

            // The gradient behind this is the placeholder, so an account with
            // no picture keeps the icon rather than dropping to an initial.
            if (user == null || !user.hasAvatar) {
              return const Icon(
                Icons.person,
                color: Color(0xFF0F1B28),
                size: 25,
              );
            }

            return UserAvatar(
              radius: 21,
              fontSize: 16,
              initial: user.initial,
              avatarUrl: user.avatar,
            );
          }),
        ),
      ),
    );
  }
}

// ─── Notification Button ─────────────────────────────────────────────────────

/// The bell, with the unread count on it.
///
/// Kept as its own widget so the [Obx] around the count rebuilds the badge
/// alone — a notification arriving must not rebuild the avatar, the logo and
/// the search button along with it.
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.badge, required this.onTap});

  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final open = onTap ?? () => Get.to(() => const NotificationScreen());

    // An explicit badge is taken at its word and asks for no controller, so a
    // caller can show a count without the feed being registered at all.
    if (badge != null) {
      return _ActionButton(
        icon: Icons.notifications_rounded,
        badge: badge,
        onTap: open,
      );
    }

    final controller = NotificationController.instance;
    return Obx(
      () => _ActionButton(
        icon: Icons.notifications_rounded,
        badge: controller.badge,
        onTap: open,
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 1,
            top: -2,
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

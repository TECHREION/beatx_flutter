import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_sizes.dart';
import '../../../module/home/presentation/screens/explore_screen.dart';
import '../../../module/onbording/common/app_logo.dart';
import '../../../module/profile/controller/get_profile_controller.dart';
import '../../../module/profile/presentation/screens/my_profile_screen.dart';
import '../../../module/profile/presentation/widgets/user_avatar.dart';

/// Unified top header for every tab screen.
///
/// - [showLogo] = true  → renders the AppLogo (Listen / Home tab)
/// - [showLogo] = false → renders [title] as the screen name (all other tabs)
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.showLogo = false,
    this.title,
    this.onSearchTap,
    this.onNotificationTap,
    this.notificationBadge,
  });

  final bool showLogo;
  final String? title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final String? notificationBadge;

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
          const _ProfileAvatar(),
          const SizedBox(width: 12),
          if (showLogo)
            const AppLogo(height: 42, width: 128)
          else
            Text(
              title ?? '',
              style: TextStyle(
                color: Color(0xFF40DDEB),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          const Spacer(),
          _ActionButton(
            icon: Icons.search_rounded,
            onTap: onSearchTap ?? () => Get.to(() => ExploreScreen()),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.notifications_rounded,
            badge: notificationBadge,
            onTap: onNotificationTap ?? () {},
          ),
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

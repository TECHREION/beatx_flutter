import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_availability_controller.dart';

/// Puts the maintenance notice and announcement above every screen.
///
/// Maintenance is a notice rather than a blocking screen: downloaded songs
/// still play, and the session stays valid for when the server returns.
class AvailabilityBanners extends StatelessWidget {
  const AvailabilityBanners({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = AppAvailabilityController.instance;

    return Obx(() {
      final maintenance = controller.settings.value.maintenanceMode;
      final announcement = controller.visibleAnnouncement;
      final hasBanner = maintenance || announcement != null;

      return Column(
        children: [
          if (hasBanner)
            Material(
              color: const Color(0xFF17171C),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (maintenance)
                      const _Banner(
                        icon: Icons.build_circle_rounded,
                        tint: Color(0xFFFFB45C),
                        text:
                            'BeatX is down for maintenance. You will stay '
                            'signed in, and downloads still play.',
                      ),
                    if (announcement != null)
                      _Banner(
                        icon: Icons.campaign_rounded,
                        tint: const Color(0xFF40DDEB),
                        text: announcement.text,
                        onClose: controller.dismissAnnouncement,
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: hasBanner,
              child: child,
            ),
          ),
        ],
      );
    });
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.tint,
    required this.text,
    this.onClose,
  });

  final IconData icon;
  final Color tint;
  final String text;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, onClose == null ? 16 : 4, 10),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          if (onClose != null)
            // No tooltip: this sits above the Navigator, so there is no Overlay
            // for one to show in, and building it would throw.
            Semantics(
              label: 'Close',
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}

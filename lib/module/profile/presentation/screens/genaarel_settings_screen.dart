import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/profile/controller/settings_controller.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/music_history_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/logout_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/privacy_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final SettingsController controller = SettingsController.instance;

  @override
  void initState() {
    super.initState();
    // Re-read on every visit, so settings changed elsewhere are not left
    // stale behind the screen. A fetch already running is joined.
    controller.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          /// Top Glow
          Positioned(
            top: -100,
            left: 50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepPurple.withValues(alpha: .35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          /// Bottom Glow
          Positioned(
            bottom: -80,
            right: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.cyan.withValues(alpha: .15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .06),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Text(
                        "General Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// GENERAL
                  const Text(
                    "General",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _sectionContainer(
                    child: Obx(() {
                      final settings = controller.settings.value;
                      final loaded = controller.hasLoaded.value;

                      return Column(
                        children: [
                          _settingRow(
                            title: "Language",
                            value: loaded ? settings.languageLabel : "…",
                          ),

                          const SizedBox(height: 18),

                          _settingRow(
                            title: "Theme",
                            value: loaded ? settings.themeLabel : "…",
                          ),

                          const SizedBox(height: 18),

                          _switchRow(
                            title: "Enable Passcode",
                            value: settings.enablePasscode,
                            // Held inert until the real values land, so a flip
                            // cannot save the defaults over them.
                            onChanged: loaded
                                ? (value) => controller.setEnablePasscode(
                                    value,
                                    notifier: SnackbarNotifier(
                                      context: context,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  /// PERSONALIZE
                  const Text(
                    "Personalize",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _sectionContainer(
                    child: Column(
                      children: [
                        _arrowRow(
                          "Music History",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MusicHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _arrowRow(
                          "Privacy",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _arrowRow(
                          "Settings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// NOTIFICATIONS
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _sectionContainer(
                    child: Obx(() {
                      final settings = controller.settings.value;
                      final loaded = controller.hasLoaded.value;

                      return Column(
                        children: [
                          _switchRow(
                            title: "Allow SMS",
                            value: settings.allowSms,
                            onChanged: loaded
                                ? (value) => controller.setAllowSms(
                                    value,
                                    notifier: SnackbarNotifier(
                                      context: context,
                                    ),
                                  )
                                : null,
                          ),

                          const SizedBox(height: 18),

                          _switchRow(
                            title: "Allow Email Notification",
                            value: settings.allowEmailNotification,
                            onChanged: loaded
                                ? (value) =>
                                      controller.setAllowEmailNotification(
                                        value,
                                        notifier: SnackbarNotifier(
                                          context: context,
                                        ),
                                      )
                                : null,
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  /// SIGN OUT
                  const Text(
                    "Sign Out",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Material(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 12),
                            Text(
                              "Sign Out",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const LogoutDialog(),
    );
  }

  Widget _settingRow({required String title, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _arrowRow(String title, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: const Color(0xFF9BFF4D),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

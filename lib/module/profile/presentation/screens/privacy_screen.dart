import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/profile/controller/settings_controller.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/terms_service_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final SettingsController controller = SettingsController.instance;

  @override
  void initState() {
    super.initState();
    controller.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          const _ProfileGlowBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackButton(context),
                      const SizedBox(width: 12),
                      const Text(
                        'Privacy',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Obx(() {
                          final settings = controller.settings.value;
                          final loaded = controller.hasLoaded.value;

                          return Column(
                            children: [
                              ListTile(
                                title: const Text(
                                  'Language',
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      loaded ? settings.languageLabel : '…',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              _switchTile(
                                'Wi-Fi Only Mode',
                                settings.wifiOnlyMode,
                                // Held inert until the real values land, so a
                                // flip cannot save the defaults over them.
                                loaded
                                    ? (value) => controller.setWifiOnlyMode(
                                        value,
                                        notifier: SnackbarNotifier(
                                          context: context,
                                        ),
                                      )
                                    : null,
                              ),
                              _switchTile(
                                'Send Usage Data',
                                settings.sendUsageData,
                                loaded
                                    ? (value) => controller.setSendUsageData(
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
                        _arrowTile('Data Management'),
                        _arrowTile(
                          'Terms & Services',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsServiceScreen(),
                              ),
                            );
                          },
                        ),
                        _arrowTile(
                          'Privacy Policy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool>? onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: const Color(0xFF9BFF4D),
        onChanged: onChanged,
      ),
    );
  }

  Widget _arrowTile(String title, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
    );
  }
}

class _ProfileGlowBackground extends StatelessWidget {
  const _ProfileGlowBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 80,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.deepPurple.withValues(alpha: .2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
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
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton(this.parentContext);

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .06),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(parentContext),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}

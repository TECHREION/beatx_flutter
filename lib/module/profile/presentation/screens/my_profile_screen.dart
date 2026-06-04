import 'package:beatx_flutter/module/profile/presentation/screens/change_password_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/genaarel_settings_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/logout_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/my_profile_details_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/payment_methods_screen.dart';
import 'package:beatx_flutter/module/subscription/presentation/screens/subscription_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          /// Background Glow
          Positioned(
            top: -80,
            left: 40,
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

          Positioned(
            bottom: -100,
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                children: [
                  /// Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .06),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// Profile Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: Color(0xFF222222),
                          child: Text(
                            'I',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Iqbal Hasan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "iqbal@mail.com",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () =>
                              _openScreen(context, const EditProfileScreen()),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  Expanded(
                    child: ListView(
                      children: [
                        _settingTile(
                          icon: Icons.person_outline,
                          title: "Edit Profile",
                          onTap: () =>
                              _openScreen(context, const EditProfileScreen()),
                        ),

                        _settingTile(
                          icon: Icons.workspace_premium_outlined,
                          title: "Subscription",
                          trailingText: "Clarity Free",
                          trailingColor: const Color(0xFFD28DFF),
                          onTap: () =>
                              _openScreen(context, SubscriptionScreen()),
                        ),

                        _settingTile(
                          icon: Icons.credit_card_outlined,
                          title: "Payment Methods",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentMethodsScreen(),
                              ),
                            );
                          },
                        ),

                        _settingTile(
                          icon: Icons.settings_outlined,
                          title: "General Settings",
                          onTap: () => _openScreen(
                            context,
                            const GeneralSettingsScreen(),
                          ),
                        ),

                        _settingTile(
                          icon: Icons.shield_outlined,
                          title: "Account Security",
                          onTap: () => _openScreen(
                            context,
                            const ChangePasswordScreen(),
                          ),
                        ),

                        _settingTile(
                          icon: Icons.logout,
                          title: "Sign Out",
                          titleColor: Colors.red,
                          iconColor: Colors.red,
                          onTap: () => _showLogoutDialog(context),
                        ),

                        const SizedBox(height: 35),

                        const Center(
                          child: Text(
                            "App version 1.0.0.1",
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 16,
                            ),
                          ),
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

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => LogoutDialog(
        onLogout: () {
          Navigator.pop(dialogContext);
          Navigator.maybePop(context);
        },
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    Color titleColor = Colors.white,
    Color iconColor = Colors.white,
    String? trailingText,
    Color trailingColor = Colors.white,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: TextStyle(
                      color: trailingColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

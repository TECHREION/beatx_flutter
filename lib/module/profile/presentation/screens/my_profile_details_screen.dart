import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/auth/presentation/widget/textfield.dart';
import 'package:beatx_flutter/module/profile/controller/use_profile_update_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final EditProfileController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = !Get.isRegistered<EditProfileController>();
    _controller = _ownsController
        ? Get.put(EditProfileController())
        : Get.find<EditProfileController>();

    _controller.fetchProfile().then((_) {
      if (!mounted) return;

      final profile = _controller.profile.value;
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    if (_ownsController && Get.isRegistered<EditProfileController>()) {
      Get.delete<EditProfileController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          /// Purple Glow
          Positioned(
            top: 60,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepPurple.withValues(alpha: .25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          /// Cyan Glow
          Positioned(
            bottom: -80,
            right: -60,
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

          Obx(() {
            if (_controller.isLoadingProfile.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF40DDEB)),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            if (_controller.isLoadingProfile.value) {
              return const SizedBox.shrink();
            }
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .06),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Text(
                          "Edit Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// Profile Image
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Stack(
                          children: [
                            Obx(() {
                              final profile = _controller.profile.value;
                              final name = profile.fullName.trim();

                              return UserAvatar(
                                radius: 42,
                                fontSize: 30,
                                initial: name.isEmpty
                                    ? '?'
                                    : name[0].toUpperCase(),
                                avatarUrl: profile.imageUrl,
                                imageBytes: profile.imageBytes,
                              );
                            }),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222222),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          LabeledTextField(
                            title: 'Full Name',
                            hintText: 'Enter full name',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          LabeledTextField(
                            title: 'Email Address',
                            hintText: 'Enter email address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    RSaveButton(
                      key: const ValueKey('edit-profile-save-button'),
                      height: 62,
                      borderRadius: BorderRadius.circular(35),
                      activeGradient: EditProfileScreen.buttonGradient,
                      buttonStatusNotifier: _controller.processNotifier,
                      saveText: 'Save Changes',
                      doneText: 'Saved',
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      onSaveTap: _saveProfile,
                      onDone: _showSavedMessage,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    _controller.updateProfile(
      fullName: _nameController.text,
      snackbarNotifier: SnackbarNotifier(context: context),
    );
  }

  void _showSavedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile information updated')),
    );
    _controller.processNotifier.setEnabled();
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                _ImageSourceTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    await _controller.pickProfileImage(source);

    // Most often the camera or photo permission was turned down, which is
    // silent otherwise — the avatar simply would not change.
    final error = _controller.pickerError.value;
    if (error.isEmpty || !mounted) return;
    SnackbarNotifier(context: context).notifyError(message: error);
  }
}

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

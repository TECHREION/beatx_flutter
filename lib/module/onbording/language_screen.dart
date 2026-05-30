import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/common/widget/reactive_button/save_button.dart';
import '../../core/localization/app_language_controller.dart';
import '../../core/notifiers/button_status_notifier.dart';
import '../../core/notifiers/snackbar_notifier.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.fromProfile = false});

  final bool fromProfile;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLanguageCode;
  final ProcessStatusNotifier _saveNotifier = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode =
        Get.find<AppLanguageController>().languageCode.value;
  }

  @override
  void dispose() {
    _saveNotifier.dispose();
    super.dispose();
  }

  Future<void> _saveOnboardingLanguage() async {
    await Get.find<AppLanguageController>().changeLanguage(
      _selectedLanguageCode,
      syncBackend: false,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Scaffold()),
    );
  }

  Future<void> _saveProfileLanguage() async {
    _saveNotifier.setLoading();
    final isSynced = await Get.find<AppLanguageController>().changeLanguage(
      _selectedLanguageCode,
    );
    if (!mounted) return;

    final snackbarNotifier = SnackbarNotifier(context: context);
    if (isSynced) {
      snackbarNotifier.notifySuccess(message: 'language.updated'.tr);
    } else {
      snackbarNotifier.notifyError(message: 'language.updateFailed'.tr);
    }
    _saveNotifier.setSuccess();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromProfile) {
      return _buildProfileStyleScreen(context);
    }
    return _buildOnboardingStyleScreen(context);
  }

  Widget _buildOnboardingStyleScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'language.onboardingTitle'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'language.onboardingSubtitle'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF737373),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _LanguageTile(
                imagePath: 'assets/image/e.png',
                title: 'language.english'.tr,
                subtitle: 'language.englishRegion'.tr,
                selected: _selectedLanguageCode == 'en',
                onTap: () => setState(() => _selectedLanguageCode = 'en'),
              ),
              const SizedBox(height: 10),
              _LanguageTile(
                imagePath: 'assets/image/i.png',
                title: 'language.italian'.tr,
                subtitle: 'language.italianRegion'.tr,
                selected: _selectedLanguageCode == 'it',
                onTap: () => setState(() => _selectedLanguageCode = 'it'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveOnboardingLanguage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB6161E),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0x33000000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'language.saveContinue'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStyleScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        surfaceTintColor: const Color(0xFFF3F3F3),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'language.profileTitle'.tr,
          style: const TextStyle(
            color: Color(0xFF151515),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            children: [
              const SizedBox(height: 6),
              _ProfileLanguageTile(
                imagePath: 'assets/image/e.png',
                title: 'language.english'.tr,
                subtitle: 'language.englishRegion'.tr,
                selected: _selectedLanguageCode == 'en',
                onTap: () => setState(() => _selectedLanguageCode = 'en'),
              ),
              const SizedBox(height: 10),
              _ProfileLanguageTile(
                imagePath: 'assets/image/i.png',
                title: 'language.italian'.tr,
                subtitle: 'language.italianRegion'.tr,
                selected: _selectedLanguageCode == 'it',
                onTap: () => setState(() => _selectedLanguageCode = 'it'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: RSaveButton(
                  key: null,
                  width: double.infinity,
                  height: 46,
                  borderRadius: BorderRadius.circular(6),
                  buttonStatusNotifier: _saveNotifier,
                  saveText: 'common.save'.tr,
                  loadingText: 'language.saving'.tr,
                  doneText: 'language.saved'.tr,
                  errorText: 'language.saveFailed'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  disabledBackgroundColor: const Color(0xFFFFC7C7),
                  onSaveTap: _saveProfileLanguage,
                  onDone: () =>
                      Navigator.of(context).pop(_selectedLanguageCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LanguageOptionCard(
      imagePath: imagePath,
      title: title,
      subtitle: subtitle,
      selected: selected,
      onTap: onTap,
      flagWidth: 50,
      flagHeight: 35,
      horizontalPadding: 12,
      verticalPadding: 16,
      titleSize: 20,
      subtitleSize: 16,
    );
  }
}

class _ProfileLanguageTile extends StatelessWidget {
  const _ProfileLanguageTile({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LanguageOptionCard(
      imagePath: imagePath,
      title: title,
      subtitle: subtitle,
      selected: selected,
      onTap: onTap,
      flagWidth: 38,
      flagHeight: 26,
      horizontalPadding: 12,
      verticalPadding: 12,
      titleSize: 15,
      subtitleSize: 12,
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.flagWidth,
    required this.flagHeight,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.titleSize,
    required this.subtitleSize,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final double flagWidth;
  final double flagHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFDBDBDB), width: 1.2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: flagWidth,
                height: flagHeight,
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF141414),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: const Color(0xFF7A7A7A),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SelectionIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF121212), width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

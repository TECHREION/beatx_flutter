import 'package:beatx_flutter/module/onbording/language_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Onboarding1Screen extends StatefulWidget {
  const Onboarding1Screen({super.key});

  @override
  State<Onboarding1Screen> createState() => _Onboarding1ScreenState();
}

class _Onboarding1ScreenState extends State<Onboarding1Screen> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryRed = Color(0xFFD8232A);
  static const Color _softText = Color(0xFF727272);
  static const Color _titleText = Color(0xFF111111);

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LanguageScreen()),
    );
  }

  void _onBack() {
    if (_currentPage == 0) {
      Navigator.maybePop(context);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    _onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      "onboarding.skip".tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _titleText,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: const [
                    _EmergencyPage(),
                    _LanguagePage(),
                    _FeaturesPage(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => _buildDot(index == _currentPage),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _onNext,
                  child: Text(
                    _currentPage == 2
                        ? "onboarding.getStarted".tr
                        : "onboarding.next".tr,
                    style: const TextStyle(
                      fontSize: 18,
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

  static Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 22 : 8,
      decoration: BoxDecoration(
        color: isActive ? _primaryRed : const Color(0xFFF1A0A3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _EmergencyPage extends StatelessWidget {
  const _EmergencyPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Column(
        children: [
          SizedBox(height: 60),
          _SirenVisual(),
          Spacer(),
          Text(
            "onboarding.emergencyTitle".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _Onboarding1ScreenState._titleText,
              height: 1.2,
            ),
          ),
          SizedBox(height: 14),
          Text(
            "onboarding.emergencyBody".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _Onboarding1ScreenState._titleText,
              height: 1.45,
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SirenVisual extends StatelessWidget {
  const _SirenVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 225,
      height: 225,
      decoration: const BoxDecoration(
        color: Color(0xFFF5DFE2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Image(image: AssetImage("assets/image/onboarding1.png")),
      ),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Column(
        children: [
          SizedBox(height: 60),
          SizedBox(
            height: 308,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 8,
                  right: 75,
                  child: _LanguageCard(
                    title: "language.english".tr,
                    body: "onboarding.languageBody".tr,
                    icon: Icons.translate_rounded,
                    iconBg: Color(0xFFE06464),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: -6,
                  child: _FlagAssetBadge(imagePath: "assets/image/UK.png"),
                ),
                Positioned(
                  left: 0,
                  bottom: 18,
                  child: _FlagAssetBadge(imagePath: "assets/image/Italy.png"),
                ),
                Positioned(
                  left: 72,
                  right: 8,
                  bottom: 0,
                  child: _LanguageCard(
                    title: "language.italian".tr,
                    body: "onboarding.languageBody".tr,
                    icon: Icons.chat_bubble_outline_rounded,
                    iconBg: Color(0xFFD93F3F),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Text(
            "onboarding.languageTitle".tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _Onboarding1ScreenState._titleText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 14),
          Text(
            "onboarding.languageBody".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _Onboarding1ScreenState._titleText,
              height: 1.45,
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconBg,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _Onboarding1ScreenState._titleText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _Onboarding1ScreenState._softText,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagAssetBadge extends StatelessWidget {
  const _FlagAssetBadge({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(imagePath, fit: BoxFit.cover),
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  static const List<_FeatureItemData> _items = [
    _FeatureItemData(
      titleKey: "onboarding.feature.aiTitle",
      subtitleKey: "onboarding.feature.aiBody",
      imagePath: "assets/image/1.png",
    ),
    _FeatureItemData(
      titleKey: "onboarding.feature.guidesTitle",
      subtitleKey: "onboarding.feature.guidesBody",
      imagePath: "assets/image/2.png",
    ),
    _FeatureItemData(
      titleKey: "onboarding.feature.historyTitle",
      subtitleKey: "onboarding.feature.historyBody",
      imagePath: "assets/image/3.png",
    ),
    _FeatureItemData(
      titleKey: "onboarding.feature.languageTitle",
      subtitleKey: "onboarding.feature.languageBody",
      imagePath: "assets/image/4.png",
    ),
    _FeatureItemData(
      titleKey: "onboarding.feature.checklistTitle",
      subtitleKey: "onboarding.feature.checklistBody",
      imagePath: "assets/image/5.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "onboarding.keyFeature".tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _Onboarding1ScreenState._titleText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final item in _items) ...[
                    _FeatureRow(item: item),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.item});

  final _FeatureItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1D8DB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(item.imagePath, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleKey.tr,
                  style: const TextStyle(
                    color: _Onboarding1ScreenState._titleText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitleKey.tr,
                  style: const TextStyle(
                    color: _Onboarding1ScreenState._softText,
                    fontSize: 14,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItemData {
  const _FeatureItemData({
    required this.titleKey,
    required this.subtitleKey,
    required this.imagePath,
  });

  final String titleKey;
  final String subtitleKey;
  final String imagePath;
}

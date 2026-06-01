import 'package:beatx_flutter/module/subscription/model/subscription_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/subscription_controller.dart';

class SubscriptionScreen extends StatelessWidget {
  SubscriptionScreen({super.key});

  final SubscriptionController controller = Get.put(SubscriptionController());

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFFB2FF4E), Color(0xFF40DDEB)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFC68BFF), Color(0xFFA56DFF)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          const _SubscriptionBackgroundGlow(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _backButton(context),
                      const SizedBox(width: 12),
                      const Text(
                        'Subscription Plans',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  ShaderMask(
                    shaderCallback: greenGradient.createShader,
                    child: const Text(
                      'ELEVATE YOUR\nSONIC REALITY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Break the limits of standard audio. Immerse yourself in high-fidelity landscapes with the most curated listening experience in the void.',
                    style: TextStyle(
                      color: Colors.white54,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ...List.generate(
                    controller.plans.length,
                    (index) => Obx(
                      () => _planCard(
                        plan: controller.plans[index],
                        isSelected: controller.selectedPlan.value == index,
                        onTap: () => controller.selectPlan(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'Feature Breakdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _featureTable(),
                  const SizedBox(height: 25),
                  _featureImageCard(
                    'Studio Grade',
                    'Hear every nuance exactly as the artist intended in the recording booth.',
                  ),
                  const SizedBox(height: 20),
                  _featureImageCard(
                    'Always Connected',
                    'Download your entire library and listen in the deepest tunnels or highest peaks.',
                  ),
                  const SizedBox(height: 20),
                  _featureImageCard(
                    'Zero Distraction',
                    'No ads, no interruptions. Pure, unfiltered auditory flow 24/7.',
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

  Widget _planCard({
    required SubscriptionPlan plan,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final gradient = plan.isPremium ? purpleGradient : greenGradient;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isSelected || plan.isPremium
                    ? const Color(0xFF8F56FF)
                    : Colors.white.withValues(alpha: .08),
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.isPopular)
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: greenGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'BEST VALUE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                Text(
                  plan.title,
                  style: const TextStyle(color: Colors.white, fontSize: 28),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        plan.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '/month',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Text(
                      plan.buttonText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          _FeatureRow(
            feature: 'Core Features',
            free: 'Free',
            premium: 'Premium',
            isHeader: true,
          ),
          Divider(color: Colors.white12, height: 24),
          _FeatureRow(feature: 'Ad-free', free: '-', premium: 'Yes'),
          SizedBox(height: 12),
          _FeatureRow(feature: 'Offline Mode', free: '-', premium: 'Yes'),
          SizedBox(height: 12),
          _FeatureRow(feature: 'Hi-Fi Audio', free: '-', premium: 'Yes'),
        ],
      ),
    );
  }

  Widget _featureImageCard(String title, String desc) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: const Color(0xFF181818),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .06),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.free,
    required this.premium,
    this.isHeader = false,
  });

  final String feature;
  final String free;
  final String premium;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.white,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
    );

    return Row(
      children: [
        Expanded(flex: 2, child: Text(feature, style: style)),
        Expanded(
          child: Text(free, textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          child: Text(
            premium,
            textAlign: TextAlign.end,
            style: style.copyWith(color: const Color(0xFFC68BFF)),
          ),
        ),
      ],
    );
  }
}

class _SubscriptionBackgroundGlow extends StatelessWidget {
  const _SubscriptionBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.indigo.withValues(alpha: .25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 100,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withValues(alpha: .25),
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

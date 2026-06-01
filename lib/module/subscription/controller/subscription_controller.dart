import 'package:get/get.dart';

import '../model/subscription_model.dart';

class SubscriptionController extends GetxController {
  final selectedPlan = 0.obs;

  final plans = const <SubscriptionPlan>[
    SubscriptionPlan(
      title: 'Free',
      price: 'BDT 0',
      isCurrent: true,
      buttonText: 'Current Plan',
      features: [
        'Ad-supported listening',
        'Offline mode',
        'Hi-Fi Spatial Audio',
      ],
    ),
    SubscriptionPlan(
      title: 'Premium',
      price: 'BDT 200',
      isPremium: true,
      isPopular: true,
      buttonText: 'Upgrade Plan',
      features: [
        'Ad-free experience',
        'Unlimited offline mode',
        'Lossless Hi-Fi Audio',
        'Listen on any device',
      ],
    ),
    SubscriptionPlan(
      title: 'Family',
      price: 'BDT 500',
      buttonText: 'Get Family Plan',
      features: [
        'All Premium features',
        'Kids-only safe app',
        'Up to 6 accounts',
      ],
    ),
    SubscriptionPlan(
      title: 'Student',
      price: 'BDT 100',
      buttonText: 'Verify & Start Student Plan',
      features: [
        'Verified student discount',
        'All Premium features',
        'Hulu & Showtime access',
      ],
    ),
  ];

  void selectPlan(int index) {
    selectedPlan.value = index;
  }
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.title,
    required this.price,
    required this.features,
    required this.buttonText,
    this.isCurrent = false,
    this.isPopular = false,
    this.isPremium = false,
  });

  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final bool isPremium;
  final String buttonText;
}

class FilterChipModel {
  const FilterChipModel({required this.label});

  final String label;
}

class LiveStreamModel {
  const LiveStreamModel({
    required this.markerLabel,
    required this.statusLabel,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
  });

  final String markerLabel;
  final String statusLabel;
  final String title;
  final String subtitle;
  final String ctaLabel;
}

class LiveCountdownModel {
  const LiveCountdownModel({
    required this.title,
    required this.artist,
    required this.image,
    required this.progress,
    required this.remainingLabel,
  });

  final String title;
  final String artist;
  final String image;
  final double progress;
  final String remainingLabel;
}

class EventTicketModel {
  const EventTicketModel({
    required this.image,
    required this.title,
    required this.venue,
    required this.price,
    required this.currency,
    this.tags = const [],
    this.dateLabel,
    this.showPriceLabel = false,
    this.isLarge = false,
  });

  final String image;
  final String title;
  final String venue;
  final String price;
  final String currency;
  final List<String> tags;
  final String? dateLabel;
  final bool showPriceLabel;
  final bool isLarge;
}

class AccessPlanModel {
  const AccessPlanModel({
    required this.name,
    required this.price,
    required this.currency,
    this.period = '/mo',
  });

  final String name;
  final String price;
  final String currency;
  final String period;
}

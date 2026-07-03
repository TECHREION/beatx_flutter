import 'package:get/get.dart';

import '../model/event_ticket_model.dart';

class EventTicketController extends GetxController {
  final selectedCityIndex = 0.obs;
  final selectedGenreIndex = 0.obs;
  final selectedPlanIndex = 1.obs;

  final cities = const <FilterChipModel>[
    FilterChipModel(label: 'ALL CITIES'),
    FilterChipModel(label: 'Dhaka'),
    FilterChipModel(label: 'Chattogram'),
    FilterChipModel(label: 'London'),
  ];

  final genres = const <FilterChipModel>[
    FilterChipModel(label: 'All Genres'),
    FilterChipModel(label: 'Fiction'),
    FilterChipModel(label: 'Non-Fiction'),
    FilterChipModel(label: 'Biography'),
    FilterChipModel(label: 'Mystery'),
    FilterChipModel(label: 'Fantasy'),
    FilterChipModel(label: 'Sci-Fi'),
  ];

  final liveStream = const LiveStreamModel(
    markerLabel: 'Hyper pop Night',
    statusLabel: 'LIVE NOW',
    title: 'The Echo Chamber',
    subtitle: 'Dhaka, Hatirjhil. Featuring Neon-X and Void Soul.',
    ctaLabel: 'Join Stream',
  );

  final countdown = const LiveCountdownModel(
    title: 'The Children Of Bangladeshi',
    artist: 'Jason Laure',
    image: 'assets/image/audiobook_children_bangladesh.png',
    progress: 0.62,
    remainingLabel: '4 HOURS REMAINING',
  );

  final events = const <EventTicketModel>[
    EventTicketModel(
      image: 'assets/image/a3.png',
      title: 'Flok Wind Dreams 2026',
      venue: 'Army Stadium, Dhaka',
      dateLabel: 'Oct 12',
      price: '500.00',
      currency: '৳',
      tags: ['FOLK SONGS', 'LOW AVAILABILITY'],
      showPriceLabel: true,
      isLarge: true,
    ),
    EventTicketModel(
      image: 'assets/image/a1.png',
      title: 'Prism Theory: Live',
      venue: 'Coxbazar, Chattogram',
      price: '250.00',
      currency: '৳',
    ),
    EventTicketModel(
      image: 'assets/image/a2.png',
      title: 'Deep Bass Ritual',
      venue: 'Hatiya, Noakhali',
      price: '250.00',
      currency: '৳',
    ),
  ];

  final plans = const <AccessPlanModel>[
    AccessPlanModel(name: 'SILVER', price: '200', currency: '৳'),
    AccessPlanModel(name: 'PRISM', price: '500', currency: '৳'),
  ];

  void selectCity(int index) => selectedCityIndex.value = index;
  void selectGenre(int index) => selectedGenreIndex.value = index;
  void selectPlan(int index) => selectedPlanIndex.value = index;
}

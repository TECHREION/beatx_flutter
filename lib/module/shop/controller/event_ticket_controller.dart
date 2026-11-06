import 'package:get/get.dart';

import '../model/event_model.dart';
import '../model/shop_model.dart';
import '../services/shop_interface.dart';

class EventTicketController extends GetxController {
  static const pageSize = 20;
  static const _allCities = ShopFilterOption(label: 'ALL CITIES');

  static const types = <ShopFilterOption>[
    ShopFilterOption(label: 'All Types'),
    ShopFilterOption(label: 'Concert', value: 'concert'),
    ShopFilterOption(label: 'Festival', value: 'festival'),
    ShopFilterOption(label: 'Session', value: 'session'),
    ShopFilterOption(label: 'Virtual', value: 'virtual'),
    ShopFilterOption(label: 'Other', value: 'other'),
  ];

  static const sorts = <ShopFilterOption>[
    ShopFilterOption(label: 'Soonest', value: 'date'),
    ShopFilterOption(label: 'Most popular', value: 'popular'),
    ShopFilterOption(label: 'Lowest price', value: 'price'),
    ShopFilterOption(label: 'Newest', value: 'newest'),
  ];

  final cities = <ShopFilterOption>[_allCities].obs;
  final selectedCity = ''.obs;
  final selectedType = ''.obs;
  final selectedSort = 'date'.obs;
  final events = <ShopEvent>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  final total = 0.obs;

  int _page = 1;
  int _generation = 0;

  bool get hasMore => events.length < total.value;

  /// The event to feature at the top while one is live.
  ShopEvent? get liveEvent => events.firstWhereOrNull((event) => event.isLive);

  ShopInterface get _shop => Get.find<ShopInterface>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectCity(String value) {
    selectedCity.value = value;
    load();
  }

  void selectType(String value) {
    selectedType.value = value;
    load();
  }

  void selectSort(String value) {
    selectedSort.value = value;
    load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    isLoading.value = true;
    isLoadingMore.value = false;
    errorMessage.value = '';

    final result = await _shop.getEvents(
      city: selectedCity.value,
      eventType: selectedType.value,
      sort: selectedSort.value,
      page: 1,
      limit: pageSize,
    );
    if (generation != _generation) return;

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      _page = 1;
      events.assignAll(success.data?.items ?? const []);
      total.value = success.data?.total ?? events.length;
      _rememberCities();
    });
    isLoading.value = false;
  }

  /// The API has no list of cities, so the chips are the ones events have
  /// turned up in. Added to rather than replaced, or choosing a city would
  /// remove every other chip.
  void _rememberCities() {
    final known = cities.map((city) => city.value).toSet();
    for (final event in events) {
      if (event.city.isNotEmpty && known.add(event.city)) {
        cities.add(ShopFilterOption(label: event.city, value: event.city));
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    final generation = _generation;
    isLoadingMore.value = true;

    final result = await _shop.getEvents(
      city: selectedCity.value,
      eventType: selectedType.value,
      sort: selectedSort.value,
      page: _page + 1,
      limit: pageSize,
    );
    if (generation != _generation) return;

    result.fold((_) {}, (success) {
      _page++;
      events.addAll(success.data?.items ?? const []);
      total.value = success.data?.total ?? total.value;
      _rememberCities();
    });
    isLoadingMore.value = false;
  }
}

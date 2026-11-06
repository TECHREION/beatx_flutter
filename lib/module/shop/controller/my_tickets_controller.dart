import 'package:get/get.dart';

import '../model/event_model.dart';
import '../services/shop_interface.dart';

class MyTicketsController extends GetxController {
  static const pageSize = 20;

  final tab = 'upcoming'.obs;
  final tickets = <TicketOrder>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  final total = 0.obs;

  int _page = 1;
  int _generation = 0;

  bool get hasMore => tickets.length < total.value;

  ShopInterface get _shop => Get.find<ShopInterface>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectTab(String value) {
    if (tab.value == value) return;
    tab.value = value;
    load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    isLoading.value = true;
    isLoadingMore.value = false;
    errorMessage.value = '';
    tickets.clear();

    final result = await _shop.getTickets(
      tab: tab.value,
      page: 1,
      limit: pageSize,
    );
    if (generation != _generation) return;

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      _page = 1;
      tickets.assignAll(success.data?.items ?? const []);
      total.value = success.data?.total ?? tickets.length;
    });
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    final generation = _generation;
    isLoadingMore.value = true;

    final result = await _shop.getTickets(
      tab: tab.value,
      page: _page + 1,
      limit: pageSize,
    );
    if (generation != _generation) return;

    result.fold((_) {}, (success) {
      _page++;
      tickets.addAll(success.data?.items ?? const []);
      total.value = success.data?.total ?? total.value;
    });
    isLoadingMore.value = false;
  }
}

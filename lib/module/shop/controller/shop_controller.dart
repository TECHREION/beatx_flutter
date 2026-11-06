import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/product_model.dart';
import '../model/shop_model.dart';
import '../services/shop_interface.dart';

class ShopController extends GetxController {
  static const pageSize = 20;
  static const _all = ShopFilterOption(label: 'All Gear');

  final selectedCategory = ''.obs;
  final categories = <ShopFilterOption>[_all].obs;
  final products = <ShopProduct>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  final total = 0.obs;

  int _page = 1;

  /// Bumped by every fresh load, so a slow answer for a category the user has
  /// already left is dropped rather than replacing the grid.
  int _generation = 0;

  bool get hasMore => products.length < total.value;

  final banners = const <PromoBannerModel>[
    PromoBannerModel(
      title: 'Event Tickets',
      subtitle:
          'Minimalist aesthetics for the digital age. Designed by BeatsX Studio.',
      ctaText: 'Explore Live Events',
      accentColor: Color(0xFF3BDDEB),
      image: 'assets/image/genre_shop.png',
    ),
    PromoBannerModel(
      title: 'The Streetwear Capsule',
      subtitle:
          'Minimalist aesthetics for the digital age. Designed by BeatsX Studio.',
      ctaText: 'Explore Apparel',
      accentColor: Color(0xFF3BDDEB),
      image: 'assets/image/Overlay+Shadow (2).png',
      titleColor: Color(0xFF3BDDEB),
      category: 'apparel',
    ),
    PromoBannerModel(
      title: 'Accessory Pack',
      subtitle:
          'Tech-noir inspired everyday carry. From custom cables to holographic stickers.',
      ctaText: 'View More',
      accentColor: Color(0xFF56E768),
      image: 'assets/image/genre_hiphop_soul.png',
      category: 'accessories',
    ),
  ];

  ShopInterface get _shop => Get.find<ShopInterface>();

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
    load();
  }

  Future<void> _loadCategories() async {
    final result = await _shop.getCategories();
    result.fold((_) {}, (success) {
      categories.assignAll([
        _all,
        ...?success.data?.map(ShopFilterOption.fromSlug),
      ]);
    });
  }

  void selectCategory(String value) {
    if (selectedCategory.value == value) return;
    selectedCategory.value = value;
    load();
  }

  /// Loads the first page of the selected category.
  Future<void> load() async {
    final generation = ++_generation;
    isLoading.value = true;
    isLoadingMore.value = false;
    errorMessage.value = '';

    final result = await _shop.getProducts(
      category: selectedCategory.value,
      page: 1,
      limit: pageSize,
    );
    if (generation != _generation) return;

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      _page = 1;
      products.assignAll(success.data?.items ?? const []);
      total.value = success.data?.total ?? products.length;
    });
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    final generation = _generation;
    isLoadingMore.value = true;

    final result = await _shop.getProducts(
      category: selectedCategory.value,
      page: _page + 1,
      limit: pageSize,
    );
    if (generation != _generation) return;

    result.fold((_) {}, (success) {
      _page++;
      products.addAll(success.data?.items ?? const []);
      total.value = success.data?.total ?? total.value;
    });
    isLoadingMore.value = false;
  }
}

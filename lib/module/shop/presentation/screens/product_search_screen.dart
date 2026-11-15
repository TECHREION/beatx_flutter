import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/search_collection.dart';
import '../../../../core/helpers/json_read.dart';
import '../../controller/product_search_controller.dart';
import '../../model/shop_model.dart';
import 'shop_detail_screen.dart';

/// Product search, over `GET /products?q=` — by name, by category, or both.
///
/// Opens on the whole catalogue, so the query and the category chips narrow
/// a list that is already there.
class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  static const accent = Color(0xFF3BDDEB);

  static const _artGradient = [Color(0xFF3BDDEB), Color(0xFF32185F)];

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  // Owned by this page, so leaving it drops the query and the results.
  final controller = ProductSearchController()..onInit();

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = ProductSearchScreen.accent;
    return Scaffold(
      backgroundColor: SearchPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const SearchHeader(
              title: 'Search Shop',
              icon: Icons.storefront_rounded,
              accent: accent,
            ),
            SearchQueryField(
              hint: 'Product name',
              accent: accent,
              onChanged: controller.onQueryChanged,
              onSubmitted: (_) => controller.search(),
              onCleared: controller.clearQuery,
            ),
            const SizedBox(height: 14),
            Obx(
              () => SearchGenreBar(
                accent: accent,
                selectedId: controller.genreId.value,
                onSelected: controller.selectGenre,
                options: controller.categories.toList(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.results.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }

                if (controller.results.isEmpty) {
                  return SearchEmptyState(
                    message: controller.errorMessage.value,
                    query: controller.query.value.trim(),
                    noun: 'products',
                    accent: accent,
                    onRetry: controller.search,
                  );
                }

                return SearchResultsList(
                  itemCount: controller.results.length,
                  isLoadingMore: controller.isLoadingMore.value,
                  accent: accent,
                  onLoadMore: controller.loadMore,
                  itemBuilder: (_, index) {
                    final product = controller.results[index];
                    return SearchResultTile(
                      coverUrl: product.coverUrl ?? '',
                      title: product.title,
                      subtitle: product.artistName,
                      fallbackIcon: Icons.shopping_bag_rounded,
                      gradient: ProductSearchScreen._artGradient,
                      accent: accent,
                      tag: product.category.isEmpty
                          ? ''
                          : ShopFilterOption.fromSlug(product.category).label,
                      meta: product.inStock
                          ? (product.priceDisplay ?? missingDisplay)
                          : 'Sold out',
                      onTap: () =>
                          Get.to(() => ShopDetailScreen(productId: product.id)),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

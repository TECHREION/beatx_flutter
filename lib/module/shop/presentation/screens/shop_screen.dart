import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/common/background_image.dart';
import '../../../../../core/common/widget/app_header.dart';
import '../../../../core/helpers/json_read.dart';
import '../../controller/shop_controller.dart';
import '../../controller/cart_controller.dart';
import '../../model/product_model.dart';
import '../../model/shop_model.dart';
import '../widgets/cart_screen.dart';
import '../widgets/event_tickets_screen.dart';
import '../widgets/shop_common.dart';
import 'shop_detail_screen.dart';
import '../../../../core/theme/responsive.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShopController());
    return AppBackgroundImage(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeader(title: 'Shop'),
              Expanded(
                child: ContentWidth.wide(
                  padded: false,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _BannersSection(controller: controller),
                            const SizedBox(height: 20),
                            _CategoryChipsSection(controller: controller),
                            const _CartBar(),
                            const SizedBox(height: 20),
                            _ProductsSection(controller: controller),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Promo Banners ─────────────────────────────────────────────────────────────

class _BannersSection extends StatelessWidget {
  const _BannersSection({required this.controller});

  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: controller.banners
            .map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: b.category == null
                      ? EventTicketsScreen.open
                      : () => controller.selectCategory(b.category!),
                  child: _PromoBannerCard(banner: b),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PromoBannerCard extends StatelessWidget {
  const _PromoBannerCard({required this.banner});

  final PromoBannerModel banner;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (right half)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              banner.image,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF16161C)),
            ),
          ),
          // Gradient overlay (dark on left, fades to transparent on right)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF13131A),
                  const Color(0xFF13131A).withValues(alpha: 0.92),
                  const Color(0xFF13131A).withValues(alpha: 0.55),
                  Colors.transparent,
                ],
                stops: const [0, 0.35, 0.60, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Text content
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 120, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: banner.titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  banner.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA7A3AA),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        banner.ctaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: banner.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: banner.accentColor,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Chips ────────────────────────────────────────────────────────────

class _CategoryChipsSection extends StatelessWidget {
  const _CategoryChipsSection({required this.controller});

  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Obx(() {
        // Read here: the item builder runs outside this Obx's tracking.
        final selected = controller.selectedCategory.value;
        final categories = controller.categories.toList();
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = selected == cat.value;
            return GestureDetector(
              onTap: () => controller.selectCategory(cat.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3BDDEB)
                      : const Color(0xFF1C1C22),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: const Color(0xFF2E2E38), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat.label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0B0B0C)
                        : const Color(0xFFA7A3AA),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─── Cart Bar ──────────────────────────────────────────────────────────────────

/// The way back to the cart, shown once it has something in it.
class _CartBar extends StatelessWidget {
  const _CartBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = CartController.instance.itemCount;
      if (count == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: GestureDetector(
          onTap: () => Get.to(() => const CartScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF3BDDEB),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    count == 1
                        ? '1 item in your cart'
                        : '$count items in your cart',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Text(
                  'View Cart',
                  style: TextStyle(
                    color: Color(0xFF3BDDEB),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Product Grid ──────────────────────────────────────────────────────────────

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({required this.controller});

  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const ShopLoading();
      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: ShopMessage(
            icon: Icons.cloud_off_rounded,
            message: controller.errorMessage.value,
            onRetry: controller.load,
          ),
        );
      }
      if (controller.products.isEmpty) {
        return const Center(
          child: ShopMessage(
            icon: Icons.storefront_rounded,
            message: 'Nothing here yet. Check back soon.',
          ),
        );
      }
      return Column(
        children: [
          _ProductGridSection(products: controller.products.toList()),
          ShopLoadMore(
            hasMore: controller.hasMore,
            isLoading: controller.isLoadingMore.value,
            onTap: controller.loadMore,
          ),
        ],
      );
    });
  }
}

class _ProductGridSection extends StatelessWidget {
  const _ProductGridSection({required this.products});

  final List<ShopProduct> products;

  Widget _cell(ShopProduct product) => Expanded(
    child: GestureDetector(
      onTap: () => Get.to(() => ShopDetailScreen(productId: product.id)),
      child: _ProductCard(product: product),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cell(products[i]),
            const SizedBox(width: 12),
            if (i + 1 < products.length)
              _cell(products[i + 1])
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < products.length) rows.add(const SizedBox(height: 14));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: rows),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ShopProduct product;

  static const _cardBg = Color(0xFF141417);
  static const _dimText = Color(0xFFA7A3AA);
  static const _teal = Color(0xFF3BDDEB);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImageArea(product: product),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _dimText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.priceDisplay ?? missingDisplay,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
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

class _ProductImageArea extends StatelessWidget {
  const _ProductImageArea({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShopImage(url: product.coverUrl),
          if (!product.inStock)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SOLD OUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          if (product.coinReward > 0)
            Positioned(
              top: 10,
              right: 10,
              child: _CoinBadge(coinPrice: product.coinReward),
            ),
        ],
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coinPrice});

  final int coinPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            '$coinPrice coin',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

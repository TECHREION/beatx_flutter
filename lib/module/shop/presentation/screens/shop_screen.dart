import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/common/background_image.dart';
import '../../../../../core/common/widget/app_header.dart';
import '../../controller/shop_controller.dart';
import '../../model/shop_model.dart';
import '../widgets/event_tickets_screen.dart';
import 'shop_detail_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShopController());
    return AppBackgroundImage(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(title: 'Shop', notificationBadge: '3'),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _BannersSection(banners: controller.banners),
                const SizedBox(height: 20),
                _CategoryChipsSection(controller: controller),
                const SizedBox(height: 20),
                _ProductGridSection(products: controller.products),
                const SizedBox(height: 32),
                _ArtistCollectionsSection(collections: controller.artistCollections),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}


// ─── Promo Banners ─────────────────────────────────────────────────────────────

class _BannersSection extends StatelessWidget {
  const _BannersSection({required this.banners});

  final List<PromoBannerModel> banners;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: banners
            .map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: b.title == 'Event Tickets'
                      ? () => Get.to(() => const EventTicketsScreen())
                      : null,
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
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF16161C)),
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
                    Text(
                      banner.ctaText,
                      style: TextStyle(
                        color: banner.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: banner.accentColor, size: 14),
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
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = controller.categories[index];
          // Only the chip itself is reactive — categories list never changes.
          return Obx(() {
            final isSelected = controller.selectedCategory.value == index;
            return GestureDetector(
              onTap: () => controller.selectCategory(index),
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
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

// ─── Product Grid ──────────────────────────────────────────────────────────────

class _ProductGridSection extends StatelessWidget {
  const _ProductGridSection({required this.products});

  final List<ShopProductModel> products;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.to(() => const ShopDetailScreen()),
                child: _ProductCard(product: products[i]),
              ),
            ),
            const SizedBox(width: 12),
            if (i + 1 < products.length)
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.to(() => const ShopDetailScreen()),
                  child: _ProductCard(product: products[i + 1]),
                ),
              )
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

  final ShopProductModel product;

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
                  product.subtitle,
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
                  '${product.currency}${product.price}',
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

  final ShopProductModel product;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            product.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1E1E25),
              child: const Icon(Icons.image_rounded, color: Colors.white24, size: 40),
            ),
          ),
          // NEW badge – top left
          if (product.isNew)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C518),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Color(0xFF111113),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          // Discount badge – top left (when no NEW)
          if (!product.isNew && product.discountLabel != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF3BDDEB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  product.discountLabel!,
                  style: const TextStyle(
                    color: Color(0xFF0B0B0C),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          // Coin badge – top right
          Positioned(
            top: 10,
            right: 10,
            child: _CoinBadge(coinPrice: product.coinPrice),
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

// ─── Artist Collections Section ────────────────────────────────────────────────

class _ArtistCollectionsSection extends StatelessWidget {
  const _ArtistCollectionsSection({required this.collections});

  final List<ArtistCollectionModel> collections;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Text(
            'CURATED VIBES',
            style: TextStyle(
              color: Color(0xFF3BDDEB),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Artist Collections',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See All Artists',
                  style: TextStyle(
                    color: Color(0xFF3BDDEB),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Experience the visual odyssey of the year. Directed by AudioSoul, starring the Prism collective.',
            style: TextStyle(
              color: Color(0xFFA7A3AA),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Collection cards
          ...collections.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ArtistCollectionCard(collection: c),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistCollectionCard extends StatelessWidget {
  const _ArtistCollectionCard({required this.collection});

  final ArtistCollectionModel collection;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              collection.cover,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF18181E)),
            ),
          ),
          // Dark gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [
                  Color(0xCC000000),
                  Color(0x55000000),
                  Color(0xDD000000),
                ],
                stops: [0.0, 0.45, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF3BDDEB).withValues(alpha: 0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3BDDEB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        collection.genre,
                        style: const TextStyle(
                          color: Color(0xFF3BDDEB),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Artist name
                Text(
                  collection.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${collection.itemCount} Items',
                  style: const TextStyle(
                    color: Color(0xFFA7A3AA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                // Accent progress bar at bottom
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3BDDEB), Color(0xFF342F89)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../shop/presentation/screens/shop_detail_screen.dart';
import '../../model/artist_profile_model.dart';
import 'artist_image.dart';

class ArtistProductGrid extends StatelessWidget {
  const ArtistProductGrid({super.key, required this.products});

  final List<ArtistProductModel> products;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The image is square (as wide as the card); below it go a title of
        // up to two lines, the category and the price. A fixed aspect ratio
        // could not fit that text at every width and text size, so the
        // card's height is the image plus the text's real height.
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        final scaler = MediaQuery.textScalerOf(context);
        final textHeight =
            scaler.scale(13 * 1.3) * 2 + // title, two lines
            scaler.scale(11 * 1.4) + // category
            scaler.scale(15 * 1.4) + // price
            4 +
            8 + // gaps between them
            10 +
            12 + // padding above and below
            2; // rounding slack
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 16,
            mainAxisExtent: cardWidth + textHeight,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              _ProductCard(product: products[index]),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ArtistProductModel product;

  static const _cardBg = Color(0xFF141417);
  static const _dimText = Color(0xFFA7A3AA);
  static const _teal = Color(0xFF3BDDEB);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: product.id.isEmpty
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShopDetailScreen(productId: product.id),
              ),
            ),
      child: _card(),
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(product: product),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
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
                const SizedBox(height: 4),
                Text(
                  product.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _dimText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    // Fixed so the grid's card height matches the app theme.
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${product.currency}${product.price}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    height: 1.4,
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final ArtistProductModel product;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: artistImage(
            product.image,
            fallback: Container(
              color: const Color(0xFF1E1E22),
              child: const Icon(
                Icons.image_rounded,
                color: Colors.white24,
                size: 40,
              ),
            ),
          ),
        ),
        if (product.coinPrice > 0)
          Positioned(
            top: 10,
            right: 10,
            child: _CoinBadge(coinPrice: product.coinPrice),
          ),
      ],
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
            color: const Color(0xFFF5A623).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 4),
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

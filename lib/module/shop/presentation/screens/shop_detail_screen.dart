import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/common/background_image.dart';
import '../../../../core/helpers/json_read.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../controller/cart_controller.dart';
import '../../controller/shop_detail_controller.dart';
import '../../model/product_model.dart';
import '../../model/shop_model.dart';
import '../widgets/cart_screen.dart';
import '../widgets/checkout_screen.dart';
import '../widgets/shop_common.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late final ShopDetailController controller = ShopDetailController(
    widget.productId,
  )..onInit();

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AppBackgroundImage(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: _ShopDetailAppBar(),
        body: Stack(
          children: [
            // Purple radial glow overlay at top (fades to transparent so bg image shows below)
            Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.6),
                  radius: 1.0,
                  colors: [Color(0xFF3B2570), Colors.transparent],
                ),
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: ShopLoading());
              }
              final product = controller.product.value;
              if (product == null) {
                return Center(
                  child: ShopMessage(
                    icon: Icons.cloud_off_rounded,
                    message: controller.errorMessage.value.isEmpty
                        ? 'This product is not available.'
                        : controller.errorMessage.value,
                    onRetry: controller.load,
                  ),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topPad + kToolbarHeight + 8),
                    Center(
                      child: _ProductHeroImage(
                        // A new colour starts its own pictures from the first.
                        key: ValueKey(controller.selectedColor.value?.name),
                        images: product.imagesFor(
                          controller.selectedColor.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TitleRow(product: product),
                          const SizedBox(height: 10),
                          _RatingRow(summary: controller.rating.value),
                          const SizedBox(height: 12),
                          Text(
                            product.description,
                            style: const TextStyle(
                              color: Color(0xFFA7A3AA),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _PriceRow(product: product),
                          const SizedBox(height: 20),
                          _OptionsCard(
                            controller: controller,
                            product: product,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        bottomNavigationBar: _BottomActionBar(controller: controller),
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _ShopDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 4,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      title: const Text(
        'Store',
        style: TextStyle(
          color: Color(0xFF3BDDEB),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Obx(
            () => IconButton(
              tooltip: 'Cart',
              icon: Badge(
                isLabelVisible: CartController.instance.itemCount > 0,
                label: Text('${CartController.instance.itemCount}'),
                backgroundColor: const Color(0xFF3BDDEB),
                textColor: const Color(0xFF0B0B0C),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () => Get.to(() => const CartScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hero Image ───────────────────────────────────────────────────────────────

class _ProductHeroImage extends StatelessWidget {
  const _ProductHeroImage({super.key, required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 340,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E3DA),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: images.length <= 1
              ? ShopImage(
                  url: images.firstOrNull,
                  background: const Color(0xFFE8E3DA),
                  iconColor: Colors.black26,
                )
              : PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (_, index) => ShopImage(
                    url: images[index],
                    background: const Color(0xFFE8E3DA),
                    iconColor: Colors.black26,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Title Row ────────────────────────────────────────────────────────────────

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            product.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
        ),
        if (product.coinReward > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF5A623), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  '${product.coinReward} coin',
                  style: const TextStyle(
                    color: Color(0xFFF5A623),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Rating Row ───────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.averageRating;
    if (average == null) {
      return const Text(
        'No reviews yet',
        style: TextStyle(
          color: Color(0xFFA7A3AA),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      );
    }
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF5A623), size: 20),
        const SizedBox(width: 5),
        Text(
          '${average.toStringAsFixed(1)}/5',
          style: const TextStyle(
            color: Color(0xFF3BDDEB),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          summary.reviewCount == 1
              ? '(1 review)'
              : '(${summary.reviewCount} reviews)',
          style: const TextStyle(
            color: Color(0xFFA7A3AA),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Price Row ────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final color = product.inStock
        ? const Color(0xFF56E768)
        : const Color(0xFFFF6B6B);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            product.priceDisplay ?? missingDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Text(
            product.inStock ? 'IN STOCK' : 'OUT OF STOCK',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Options Card ─────────────────────────────────────────────────────────────

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.controller, required this.product});

  final ShopDetailController controller;
  final ShopProduct product;

  static const _heading = TextStyle(
    color: Color(0xFFA7A3AA),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category breadcrumb
          Text(
            ShopFilterOption.fromSlug(product.category).label,
            style: const TextStyle(
              color: Color(0xFF6A6870),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (product.sizes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('SELECT SIZE', style: _heading),
            const SizedBox(height: 14),
            Obx(
              () => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final size in product.sizes)
                    _SizeButton(
                      label: size.name,
                      isSelected: controller.selectedSize.value == size.name,
                      isAvailable: size.isAvailable,
                      onTap: () => controller.selectSize(size),
                    ),
                ],
              ),
            ),
          ],
          if (product.colors.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text('PRISM COLOR', style: _heading),
            const SizedBox(height: 14),
            Obx(
              () => Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final color in product.colors)
                    _ColorSwatch(
                      color: color.swatch,
                      label: color.name,
                      isSelected:
                          controller.selectedColor.value?.name == color.name,
                      isAvailable: product.isColorAvailable(color),
                      onTap: () => controller.selectColor(color),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Size Button ──────────────────────────────────────────────────────────────

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.label,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1 : 0.35,
      child: GestureDetector(
        onTap: isAvailable ? onTap : null,
        child: isSelected
            ? Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFAA5CE0), Color(0xFF5B6EF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1C1C22),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1C1C22),
                  border: Border.all(
                    color: const Color(0xFF2E2E38),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFA7A3AA),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Color Swatch ─────────────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: isSelected,
      child: Opacity(
        opacity: isAvailable ? 1 : 0.3,
        child: GestureDetector(
          onTap: isAvailable ? onTap : null,
          child: isSelected
              ? Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6CD7), Color(0xFF9B59B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                )
              : Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Bottom Action Bar ────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.controller});

  final ShopDetailController controller;

  void _buyNow(BuildContext context) {
    final problem = controller.selectionProblem;
    if (problem != null) {
      SnackbarNotifier(context: context).notifyError(message: problem);
      return;
    }
    Get.to(() => CheckoutScreen(lines: [controller.toLine()]));
  }

  void _addToCart(BuildContext context) {
    final problem = controller.selectionProblem;
    final notifier = SnackbarNotifier(context: context);
    if (problem != null) {
      notifier.notifyError(message: problem);
      return;
    }
    CartController.instance.add(controller.toLine());
    notifier.notifySuccess(message: 'Added to your cart');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFF0B0B0C),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            // Buy Now
            Expanded(
              child: GestureDetector(
                onTap: () => _buyNow(context),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC5F135), Color(0xFF50DA6A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF0A1F0D),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Buy Now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF0A1F0D),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add to Cart
            Expanded(
              child: GestureDetector(
                onTap: () => _addToCart(context),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF1E1E25),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Add to Cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

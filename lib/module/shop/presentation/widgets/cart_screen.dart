import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/helpers/json_read.dart';
import '../../controller/cart_controller.dart';
import '../../model/cart_model.dart';
import 'checkout_screen.dart';
import 'shop_common.dart';

const _teal = Color(0xFF3BDDEB);
const _dimText = Color(0xFFA7A3AA);

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0C),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _teal),
        title: const Text(
          'Your Cart',
          style: TextStyle(
            color: _teal,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (cart.lines.isEmpty) {
          return const Center(
            child: ShopMessage(
              icon: Icons.shopping_cart_outlined,
              message: 'Your cart is empty.',
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cart.lines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _CartRow(line: cart.lines[index]),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (cart.lines.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Shipping and the final total are worked out at checkout.',
                  style: TextStyle(color: _dimText, fontSize: 12),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Get.to<void>(
                    () => CheckoutScreen(
                      lines: cart.lines.toList(),
                      fromCart: true,
                    ),
                  ),
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
                      ),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        color: Color(0xFF0B0B0C),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final options = [line.size, line.color].whereType<String>().join(' / ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: ShopImage(url: line.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (options.isNotEmpty)
                  Text(
                    options,
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  line.priceDisplay ?? missingDisplay,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Decrease quantity',
            onPressed: () => cart.setQuantity(line, line.quantity - 1),
            icon: Icon(
              line.quantity == 1
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          Text(
            '${line.quantity}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            onPressed: () => cart.setQuantity(line, line.quantity + 1),
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

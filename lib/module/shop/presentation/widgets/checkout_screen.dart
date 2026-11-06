import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/helpers/json_read.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../controller/checkout_controller.dart';
import '../../model/cart_model.dart';
import '../../model/purchase_model.dart';
import '../../services/payment_flow.dart';
import 'purchase_outcome.dart';
import 'shop_common.dart';

const _teal = Color(0xFF3BDDEB);
const _dimText = Color(0xFFA7A3AA);
const _cardBg = Color(0xFF141417);
const _fieldBorder = Color(0xFF3A3844);
const _confirmGradient = LinearGradient(
  colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.lines, this.fromCart = false});

  final List<CartLine> lines;
  final bool fromCart;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final CheckoutController controller = CheckoutController(
    lines: widget.lines,
    fromCart: widget.fromCart,
  )..onInit();

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (controller.isSubmitting.value) return;
    final notifier = SnackbarNotifier(context: context);
    try {
      final attempt = await controller.confirm();
      await completePurchase(attempt: attempt, onSettled: controller.settle);
    } on PurchaseFailure catch (failure) {
      notifier.notifyError(message: failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: Stack(
        children: [
          const _TopGlow(),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _StepHeader(),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _LabeledField(
                                label: 'First Name',
                                controller: controller.firstNameController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledField(
                                label: 'Last Name',
                                controller: controller.lastNameController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Shipping Address',
                          controller: controller.addressController,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _LabeledField(
                                label: 'City',
                                controller: controller.cityController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledField(
                                label: 'Postal Code',
                                controller: controller.postalCodeController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _OrderSummaryCard(controller: controller),
                        const SizedBox(height: 20),
                        Obx(
                          () => _ConfirmButton(
                            enabled: controller.quote.value != null,
                            isBusy: controller.isSubmitting.value,
                            onTap: _confirm,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _SecureNotice(),
                      ],
                    ),
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

// ─── Top Glow ────────────────────────────────────────────────────────────────

class _TopGlow extends StatelessWidget {
  const _TopGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: 20,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You will pay on a secure page after confirming your order.',
                  style: TextStyle(
                    color: _dimText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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

// ─── Step Header ─────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF16414A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            '1',
            style: TextStyle(
              color: _teal,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'SHIPPING DETAILS',
          style: TextStyle(
            color: _teal,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Labeled Field ────────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _dimText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _teal),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Summary Line ────────────────────────────────────────────────────────────

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: isTotal ? Colors.white : _dimText,
      fontSize: isTotal ? 17 : 13,
      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
    );
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: isTotal ? 20 : 14,
      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ─── Order Summary Card ───────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.controller});

  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Obx(() {
        final quote = controller.quote.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.isQuoting.value)
              const ShopLoading()
            else if (quote == null)
              Center(
                child: ShopMessage(
                  icon: Icons.error_outline_rounded,
                  message: controller.quoteError.value,
                  onRetry: controller.loadQuote,
                ),
              )
            else ...[
              for (final item in quote.items) ...[
                _OrderItemRow(item: item),
                const SizedBox(height: 14),
              ],
              const Divider(color: _fieldBorder, height: 1),
              const SizedBox(height: 14),
              _SummaryLine(
                label: 'Sub-total',
                value: quote.subtotalDisplay ?? missingDisplay,
              ),
              const SizedBox(height: 8),
              _SummaryLine(
                label: 'VAT',
                value: quote.vatDisplay ?? missingDisplay,
              ),
              const SizedBox(height: 8),
              _SummaryLine(
                label: 'Shipping Fee',
                value: quote.shippingFeeDisplay ?? missingDisplay,
              ),
              const SizedBox(height: 14),
              const Divider(color: _fieldBorder, height: 1),
              const SizedBox(height: 14),
              _SummaryLine(
                label: 'Total',
                value: quote.totalDisplay ?? missingDisplay,
                isTotal: true,
              ),
              if (quote.coinsAwarded > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'You will earn ${quote.coinsAwarded} coins once paid',
                  style: const TextStyle(
                    color: Color(0xFFF5A623),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        );
      }),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final QuoteLine item;

  @override
  Widget build(BuildContext context) {
    final options = [
      item.size,
      item.color,
    ].where((option) => option.isNotEmpty).join(' / ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 52,
            height: 52,
            child: ShopImage(url: item.image, icon: Icons.album_rounded),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (options.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  options,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                'Quantity: ${item.quantity}',
                style: const TextStyle(
                  color: _dimText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.lineTotalDisplay ?? missingDisplay,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Confirm Button ───────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.enabled,
    required this.isBusy,
    required this.onTap,
  });

  final bool enabled;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled && !isBusy ? onTap : null,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: _confirmGradient,
          ),
          alignment: Alignment.center,
          child: isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF0B0B0C),
                  ),
                )
              : const Text(
                  'Confirm Order',
                  style: TextStyle(
                    color: Color(0xFF0B0B0C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SecureNotice extends StatelessWidget {
  const _SecureNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, color: _dimText, size: 14),
        SizedBox(width: 6),
        Text(
          'ENCRYPTED SECURE TRANSACTION',
          style: TextStyle(
            color: _dimText,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

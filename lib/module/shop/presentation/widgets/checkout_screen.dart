import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/checkout_controller.dart';
import '../../model/checkout_model.dart';
import 'congratulation_screen.dart';

const _teal = Color(0xFF3BDDEB);
const _dimText = Color(0xFFA7A3AA);
const _cardBg = Color(0xFF141417);
const _fieldBorder = Color(0xFF3A3844);
const _confirmGradient = LinearGradient(
  colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CheckoutController());

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
                        const SizedBox(height: 20),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            color: _dimText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PaymentMethodRow(controller: controller),
                        const SizedBox(height: 14),
                        _SavedCard(cardNumber: controller.savedCardNumber),
                        const SizedBox(height: 20),
                        const Divider(color: _fieldBorder, height: 1),
                        const SizedBox(height: 20),
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SummaryLine(label: 'Sub-total', value: '${controller.currency}${controller.subTotal}'),
                        const SizedBox(height: 8),
                        _SummaryLine(label: 'VAT (%)', value: '${controller.currency}0.00'),
                        const SizedBox(height: 8),
                        _SummaryLine(label: 'Shipping Fee', value: '${controller.currency}${controller.shippingFee}'),
                        const SizedBox(height: 12),
                        const Divider(color: _fieldBorder, height: 1),
                        const SizedBox(height: 12),
                        _SummaryLine(
                          label: 'Total',
                          value: '${controller.currency}${controller.total}',
                          isTotal: true,
                        ),
                        const SizedBox(height: 20),
                        _PromoCodeRow(controller: controller.promoCodeController),
                        const SizedBox(height: 24),
                        _OrderSummaryCard(controller: controller),
                        const SizedBox(height: 20),
                        const _ConfirmButton(),
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
                colors: [Colors.blue.withValues(alpha: 0.4), Colors.transparent],
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
                colors: [Colors.purple.withValues(alpha: 0.6), Colors.transparent],
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
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
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
                  'Complete your transaction to unlock premium soundscapes.',
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
          const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
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
            style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w800),
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
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

// ─── Payment Method Row ───────────────────────────────────────────────────────

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({required this.controller});

  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < controller.paymentMethods.length; i++) ...[
          Expanded(
            child: Obx(
              () => _PaymentMethodChip(
                method: controller.paymentMethods[i],
                isSelected: controller.selectedPaymentIndex.value == i,
                onTap: () => controller.selectPaymentMethod(i),
              ),
            ),
          ),
          if (i != controller.paymentMethods.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethodModel method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141417),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? Colors.white : _fieldBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(method.icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              method.label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Saved Card ──────────────────────────────────────────────────────────────

class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.cardNumber});

  final String cardNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fieldBorder),
      ),
      child: Row(
        children: [
          const Text(
            'VISA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cardNumber,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.edit_outlined, color: _dimText, size: 18),
        ],
      ),
    );
  }
}

// ─── Summary Line ────────────────────────────────────────────────────────────

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.isTotal = false});

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

// ─── Promo Code Row ───────────────────────────────────────────────────────────

class _PromoCodeRow extends StatelessWidget {
  const _PromoCodeRow({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Enter promo code',
              hintStyle: const TextStyle(color: _dimText, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: _teal),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C22),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          for (final item in controller.orderItems) ...[
            _OrderItemRow(item: item),
            const SizedBox(height: 14),
          ],
          const Divider(color: _fieldBorder, height: 1),
          const SizedBox(height: 14),
          _SummaryLine(label: 'Sub-total', value: '${controller.currency}${controller.subTotal}'),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VAT (%)', style: TextStyle(color: _dimText, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                'Free',
                style: TextStyle(color: Color(0xFF56E768), fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SummaryLine(label: 'Shipping Fee', value: '${controller.currency}${controller.shippingFee}'),
          const SizedBox(height: 14),
          const Divider(color: _fieldBorder, height: 1),
          const SizedBox(height: 14),
          _SummaryLine(label: 'Total', value: '${controller.currency}${controller.total}', isTotal: true),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final CheckoutOrderItemModel item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            item.image,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 52,
              height: 52,
              color: const Color(0xFF1E1E25),
              child: const Icon(Icons.album_rounded, color: Colors.white24, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                item.tag,
                style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Quantity: ${item.quantity}',
                style: const TextStyle(color: _dimText, fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${item.currency}${item.price}',
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ─── Confirm Button ───────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.dialog(
        const CongratulationScreen(),
        barrierColor: Colors.transparent,
      ),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: _confirmGradient,
        ),
        alignment: Alignment.center,
        child: const Text(
          'Confirm Order',
          style: TextStyle(
            color: Color(0xFF0B0B0C),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
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

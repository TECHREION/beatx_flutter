import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controller/get_profile_controller.dart';
import '../model/cart_model.dart';
import '../model/purchase_model.dart';
import '../presentation/widgets/payment_webview_screen.dart';
import '../services/payment_flow.dart';
import '../services/shop_interface.dart';
import 'cart_controller.dart';

class CheckoutController extends GetxController {
  CheckoutController({
    required this.lines,
    this.fromCart = false,
    Future<void> Function(String url)? openPaymentPage,
  }) : _openPaymentPage = openPaymentPage ?? PaymentWebViewScreen.open;

  final List<CartLine> lines;

  /// Whether a paid order empties the cart (Buy Now leaves it alone).
  final bool fromCart;
  final Future<void> Function(String url) _openPaymentPage;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final postalCodeController = TextEditingController();

  final quote = Rxn<OrderQuote>();
  final isQuoting = true.obs;
  final quoteError = ''.obs;
  final isSubmitting = false.obs;

  /// Kept across a retry after a timeout, and dropped once the server has
  /// answered, so that the next attempt is a new order.
  String? _idempotencyKey;

  /// The order still waiting for payment, so confirming again goes back to
  /// paying for it rather than creating a second one.
  PaymentSession? _unpaid;

  /// The address the key and the unpaid order above were made for.
  Map<String, dynamic>? _attemptAddress;

  ShopInterface get _shop => Get.find<ShopInterface>();

  @override
  void onInit() {
    super.onInit();
    _prefillName();
    loadQuote();
  }

  void _prefillName() {
    if (!Get.isRegistered<ProfileController>()) return;
    final parts = Get.find<ProfileController>().name.trim().split(
      RegExp(r'\s+'),
    );
    firstNameController.text = parts.first;
    lastNameController.text = parts.skip(1).join(' ');
  }

  Future<void> loadQuote() async {
    isQuoting.value = true;
    quoteError.value = '';

    final result = await _shop.quoteOrder(
      lines.map((line) => line.toRequest()).toList(),
    );
    result.fold(
      (failure) => quoteError.value = failure.uiMessage,
      (success) => quote.value = success.data,
    );
    isQuoting.value = false;
  }

  /// Why the form cannot be sent yet, or null.
  String? get formProblem {
    final controllers = {
      'first name': firstNameController,
      'last name': lastNameController,
      'shipping address': addressController,
      'city': cityController,
      'postal code': postalCodeController,
    };
    for (final entry in controllers.entries) {
      if (entry.value.text.trim().isEmpty) {
        return 'Please enter your ${entry.key}.';
      }
    }
    return null;
  }

  /// Creates the order, or returns the one already waiting for payment.
  /// Failures throw a [PurchaseFailure] carrying the message to show.
  Future<PurchaseAttempt> confirm() async {
    final problem = formProblem;
    if (problem != null) throw PurchaseFailure(problem);

    final address = ShippingAddress(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      postalCode: postalCodeController.text.trim(),
    );
    // Editing the address makes this a different order, which must not come
    // back as the earlier one and ship to the old address.
    if (!mapEquals(_attemptAddress, address.toJson())) {
      _idempotencyKey = null;
      _unpaid = null;
    }
    _attemptAddress = address.toJson();

    final unpaid = _unpaid;
    if (unpaid != null) return PurchaseAttempt(session: unpaid);

    isSubmitting.value = true;
    try {
      final key = _idempotencyKey ??= newIdempotencyKey();
      final result = await _shop.createOrder(
        items: lines.map((line) => line.toRequest()).toList(),
        address: address,
        idempotencyKey: key,
      );

      return result.fold(
        (failure) {
          if (!isUncertainFailure(failure)) _idempotencyKey = null;
          throw PurchaseFailure(failure.uiMessage);
        },
        (success) {
          _idempotencyKey = null;
          final created = success.data!;
          final payment = created.payment;
          if (payment == null) {
            return PurchaseAttempt(
              settled: PurchaseOutcome.of(created.purchase),
            );
          }
          final session = PaymentSession(
            redirectUrl: payment.redirectUrl,
            openPage: _openPaymentPage,
            readPurchase: () async {
              final read = await _shop.getOrder(created.purchase.id);
              return read.fold((_) => null, (ok) => ok.data);
            },
          );
          _unpaid = session;
          return PurchaseAttempt(session: session);
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Records how the order ended. Still-pending orders stay open to pay.
  void settle(PurchaseOutcome outcome) {
    if (outcome.status == PurchaseStatus.pending) return;
    _unpaid = null;
    if (outcome.status == PurchaseStatus.paid && fromCart) {
      CartController.instance.clear();
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
    super.onClose();
  }
}

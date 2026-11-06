import 'dart:math' as math;

import 'package:get/get.dart';

import '../model/event_model.dart';
import '../model/purchase_model.dart';
import '../presentation/widgets/payment_webview_screen.dart';
import '../services/payment_flow.dart';
import '../services/shop_interface.dart';

class GetTicketController extends GetxController {
  GetTicketController(
    ShopEvent event, {
    Future<void> Function(String url)? openPaymentPage,
  }) : event = event.obs,
       _openPaymentPage = openPaymentPage ?? PaymentWebViewScreen.open;

  /// The API's limit on one order.
  static const maxPerOrder = 10;

  final Rx<ShopEvent> event;
  final Future<void> Function(String url) _openPaymentPage;

  final selectedTier = Rxn<TicketTier>();
  final quantity = 1.obs;
  final quote = Rxn<TicketQuote>();
  final quoteError = ''.obs;
  final isQuoting = false.obs;
  final isSubmitting = false.obs;

  String? _idempotencyKey;
  PaymentSession? _unpaid;

  /// Only the answer to the latest quote request may be shown: an older one
  /// is for a tier or quantity no longer selected.
  int _quoteRequest = 0;

  ShopInterface get _shop => Get.find<ShopInterface>();

  /// The most this buyer can select right now.
  int get maxQuantity {
    final remaining = selectedTier.value?.remaining ?? maxPerOrder;
    return math.max(1, math.min(maxPerOrder, remaining));
  }

  /// A buy needs a current quote for what is selected.
  bool get canBuy =>
      !isSubmitting.value &&
      !isQuoting.value &&
      quote.value != null &&
      selectedTier.value != null;

  @override
  void onInit() {
    super.onInit();
    _selectFirstAvailableTier();
    _refreshEvent();
  }

  void _selectFirstAvailableTier() {
    final tiers = event.value.tiers;
    selectTier(
      tiers.firstWhereOrNull((tier) => !tier.isSoldOut) ?? tiers.firstOrNull,
    );
  }

  /// The list's copy may be minutes old, and seats change.
  Future<void> _refreshEvent() async {
    final result = await _shop.getEvent(event.value.id);
    result.fold((_) {}, (success) {
      final fresh = success.data;
      if (fresh == null) return;
      event.value = fresh;
      final selectedId = selectedTier.value?.id;
      final same = fresh.tiers.firstWhereOrNull((t) => t.id == selectedId);
      if (same != null && !same.isSoldOut) {
        selectTier(same);
      } else {
        _selectFirstAvailableTier();
      }
    });
  }

  /// A different selection is a different booking: it must not reuse the key
  /// of the last attempt or reopen a booking made for the old selection.
  void _startNewAttempt() {
    _idempotencyKey = null;
    _unpaid = null;
  }

  void selectTier(TicketTier? tier) {
    if (tier?.id != selectedTier.value?.id) _startNewAttempt();
    selectedTier.value = tier;
    if (tier == null) return;
    final allowed = math.min(quantity.value, maxQuantity);
    if (allowed != quantity.value) _startNewAttempt();
    quantity.value = allowed;
    _loadQuote();
  }

  void increment() {
    if (quantity.value < maxQuantity) {
      _startNewAttempt();
      quantity.value++;
      _loadQuote();
    }
  }

  void decrement() {
    if (quantity.value > 1) {
      _startNewAttempt();
      quantity.value--;
      _loadQuote();
    }
  }

  Future<void> _loadQuote() async {
    final request = ++_quoteRequest;
    // Hidden until it matches, so a stale total is never on screen.
    quote.value = null;
    quoteError.value = '';
    isQuoting.value = true;

    final result = await _shop.quoteTicket(
      eventId: event.value.id,
      quantity: quantity.value,
      tierId: selectedTier.value?.id,
    );
    if (request != _quoteRequest) return;

    result.fold(
      (failure) => quoteError.value = failure.uiMessage,
      (success) => quote.value = success.data,
    );
    isQuoting.value = false;
  }

  /// Books the seats, or returns the booking already waiting for payment.
  /// Failures throw a [PurchaseFailure] carrying the message to show.
  Future<PurchaseAttempt> buy() async {
    final unpaid = _unpaid;
    if (unpaid != null) return PurchaseAttempt(session: unpaid);

    isSubmitting.value = true;
    try {
      final key = _idempotencyKey ??= newIdempotencyKey();
      final result = await _shop.buyTicket(
        eventId: event.value.id,
        quantity: quantity.value,
        tierId: selectedTier.value?.id,
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
              final read = await _shop.getTicket(created.purchase.id);
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

  void settle(PurchaseOutcome outcome) {
    if (outcome.status != PurchaseStatus.pending) _unpaid = null;
  }
}

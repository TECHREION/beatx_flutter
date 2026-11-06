import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/purchase_model.dart';
import '../../services/payment_flow.dart';
import 'congratulation_screen.dart';

/// Takes a created purchase through payment and shows how it ended. A purchase
/// left unpaid stays open, for the buyer to come back to.
Future<void> completePurchase({
  required PurchaseAttempt attempt,
  required void Function(PurchaseOutcome) onSettled,
  bool isTicket = false,
}) async {
  final session = attempt.session;
  var outcome = attempt.settled;

  if (session != null) {
    await session.open();
    outcome = await _checking(session);
  }
  outcome ??= const PurchaseOutcome(status: PurchaseStatus.pending);

  while (outcome!.status == PurchaseStatus.pending && session != null) {
    final choice = await Get.dialog<_PendingChoice>(
      const _PendingDialog(),
      barrierDismissible: false,
    );
    if (choice == _PendingChoice.pay) {
      await session.open();
    } else if (choice != _PendingChoice.check) {
      onSettled(outcome);
      return;
    }
    outcome = await _checking(session);
  }

  onSettled(outcome);
  if (outcome.status == PurchaseStatus.paid) {
    await Get.dialog<void>(
      CongratulationScreen(
        coins: outcome.coinsAwarded,
        isTicket: isTicket,
        entryCode: outcome.entryCode,
      ),
      barrierColor: Colors.transparent,
      barrierDismissible: false,
    );
  } else {
    await Get.dialog<void>(_FailedDialog(status: outcome.status));
  }
}

Future<PurchaseOutcome> _checking(PaymentSession session) async {
  Get.dialog<void>(
    const Center(child: CircularProgressIndicator(color: Color(0xFF3BDDEB))),
    barrierDismissible: false,
  );
  try {
    return await session.check();
  } finally {
    Get.back<void>();
  }
}

enum _PendingChoice { pay, check, close }

class _PendingDialog extends StatelessWidget {
  const _PendingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141417),
      title: const Text(
        'Payment not finished',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'We have not received your payment yet. Your items are held for a '
        'short time, so you can go back and finish paying.',
        style: TextStyle(color: Color(0xFFA7A3AA), height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: _PendingChoice.close),
          child: const Text('Close', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Get.back(result: _PendingChoice.check),
          child: const Text(
            'Check Again',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () => Get.back(result: _PendingChoice.pay),
          child: const Text(
            'Continue Payment',
            style: TextStyle(
              color: Color(0xFF3BDDEB),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FailedDialog extends StatelessWidget {
  const _FailedDialog({required this.status});

  final PurchaseStatus status;

  @override
  Widget build(BuildContext context) {
    final expired = status == PurchaseStatus.expired;
    return AlertDialog(
      backgroundColor: const Color(0xFF141417),
      title: Text(
        expired ? 'Payment time ran out' : 'Payment did not go through',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        expired
            ? 'This order was not paid in time, so your items were released. '
                  'You can place it again.'
            : 'The payment was cancelled or declined, and your items were '
                  'released. You can try again.',
        style: const TextStyle(color: Color(0xFFA7A3AA), height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: const Text('OK', style: TextStyle(color: Color(0xFF3BDDEB))),
        ),
      ],
    );
  }
}

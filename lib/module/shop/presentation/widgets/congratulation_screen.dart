import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'event_tickets_screen.dart';
import 'my_tickets_screen.dart';

const _teal = Color(0xFF3BDDEB);
const _dimText = Color(0xFFA7A3AA);
const _green = Color(0xFF56E768);

class CongratulationScreen extends StatelessWidget {
  const CongratulationScreen({
    super.key,
    this.coins = 0,
    this.isTicket = false,
    this.entryCode = '',
  });

  /// What the server says this purchase earned.
  final int coins;
  final bool isTicket;

  /// The ticket's door code, when it has one.
  final String entryCode;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: _CongratulationCard(
                coins: coins,
                isTicket: isTicket,
                entryCode: entryCode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CongratulationCard extends StatelessWidget {
  const _CongratulationCard({
    required this.coins,
    required this.isTicket,
    required this.entryCode,
  });

  final int coins;
  final bool isTicket;
  final String entryCode;

  String get _message {
    final placed = isTicket
        ? 'Your ticket is confirmed'
        : 'Your order has been placed';
    return coins > 0
        ? '$placed and you have received $coins coins'
        : '$placed.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CheckBadge(),
          const SizedBox(height: 28),
          const Text(
            'Congratulations!',
            style: TextStyle(
              color: _teal,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dimText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          if (entryCode.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'ENTRY CODE',
              style: TextStyle(
                color: _dimText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              entryCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
          const SizedBox(height: 28),
          _GoBackButton(
            label: isTicket ? 'Go Back to Events' : 'Go Back to Shop',
            onTap: () => Get.until(
              (route) => isTicket
                  ? route.settings.name == EventTicketsScreen.routeName ||
                        route.isFirst
                  : route.isFirst,
            ),
          ),
          if (isTicket) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Get.until(
                  (route) =>
                      route.settings.name == EventTicketsScreen.routeName ||
                      route.isFirst,
                );
                Get.to<void>(() => const MyTicketsScreen());
              },
              child: const Text(
                'View My Tickets',
                style: TextStyle(color: _teal, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _dot(top: 20, left: 30, size: 20),
          _dot(top: 8, left: 108, size: 6),
          _dot(top: 42, right: 10, size: 16),
          _dot(bottom: 40, left: 0, size: 12),
          _dot(bottom: 8, left: 90, size: 8),
          _dot(bottom: 55, right: 20, size: 6),
          _dot(bottom: 20, right: 60, size: 8),
          Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFF123420),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: _green, width: 3),
              ),
            ),
            child: const Icon(Icons.check_rounded, color: _green, size: 38),
          ),
        ],
      ),
    );
  }

  Widget _dot({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
      ),
    );
  }
}

class _GoBackButton extends StatelessWidget {
  const _GoBackButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white54),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

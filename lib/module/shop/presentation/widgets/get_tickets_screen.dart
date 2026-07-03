import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/event_ticket_model.dart';
import 'checkout_screen.dart';

const _teal = Color(0xFF3BDDEB);
const _violet = Color(0xFFAA5CE0);
const _dimText = Color(0xFFA7A3AA);
const _chipBg = Color(0xFF1C1C22);
const _buyButtonBg = Color(0xFFC9A0F5);
const _buyButtonText = Color(0xFF2E1A47);

class GetTicketScreen extends StatefulWidget {
  const GetTicketScreen({super.key, required this.event});

  final EventTicketModel event;

  @override
  State<GetTicketScreen> createState() => _GetTicketScreenState();
}

class _GetTicketScreenState extends State<GetTicketScreen> {
  int _quantity = 1;

  void _increment() => setState(() => _quantity = (_quantity + 1).clamp(1, 10));
  void _decrement() => setState(() => _quantity = (_quantity - 1).clamp(1, 10));

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _HeroImage(image: event.image),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.tags.isNotEmpty) ...[
                                _TagsRow(tags: event.tags),
                                const SizedBox(height: 14),
                              ],
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, color: _dimText, size: 17),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.dateLabel != null
                                          ? '${event.dateLabel} • ${event.venue}'
                                          : event.venue,
                                      style: const TextStyle(
                                        color: _dimText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (event.showPriceLabel)
                                        const Text(
                                          'STARTING FROM',
                                          style: TextStyle(
                                            color: _dimText,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${event.currency}${event.price}',
                                        style: const TextStyle(
                                          color: _teal,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Select Quantity',
                                        style: TextStyle(
                                          color: _dimText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _QuantityStepper(
                                        quantity: _quantity,
                                        onDecrement: _decrement,
                                        onIncrement: _increment,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              const _BuyButton(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
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
          top: 60,
          left: 70,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.purple.withValues(alpha: 0.55), Colors.transparent],
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
          const Text(
            'Get Ticket',
            style: TextStyle(
              color: _teal,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

// ─── Hero Image ───────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1.05,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1E1E25),
                child: const Icon(Icons.image_rounded, color: Colors.white24, size: 60),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tags Row ─────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tags.length; i++) ...[
          _Tag(label: tags[i], isPrimary: i == 0),
          if (i != tags.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.isPrimary});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? _violet.withValues(alpha: 0.18) : _chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? const Color(0xFFD5B3FF) : Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─── Quantity Stepper ───────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 40,
          child: Text(
            quantity.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 1.4),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ─── Buy Button ─────────────────────────────────────────────────────────────

class _BuyButton extends StatelessWidget {
  const _BuyButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const CheckoutScreen()),
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _buyButtonBg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, color: _buyButtonText, size: 20),
            SizedBox(width: 10),
            Text(
              'Buy Ticket Now',
              style: TextStyle(
                color: _buyButtonText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

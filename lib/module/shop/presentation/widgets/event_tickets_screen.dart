import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/event_ticket_controller.dart';
import '../../model/event_ticket_model.dart';
import 'get_tickets_screen.dart';

const _teal = Color(0xFF3BDDEB);
const _violet = Color(0xFFAA5CE0);
const _dimText = Color(0xFFA7A3AA);
const _cardBg = Color(0xFF141417);
const _chipBg = Color(0xFF1C1C22);
const _chipBorder = Color(0xFF2E2E38);

class EventTicketsScreen extends StatelessWidget {
  const EventTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventTicketController());

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeaderText(),
                    const SizedBox(height: 18),
                    _CityChips(controller: controller),
                    const SizedBox(height: 18),
                    _LiveMapCard(liveStream: controller.liveStream),
                    const SizedBox(height: 16),
                    _CountdownStrip(countdown: controller.countdown),
                    const SizedBox(height: 22),
                    _GenreChips(controller: controller),
                    const SizedBox(height: 22),
                    const _SectionHeader(),
                    const SizedBox(height: 16),
                    for (final event in controller.events) ...[
                      _EventCard(event: event),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    const _AccessPassHeader(),
                    const SizedBox(height: 16),
                    _PlanRow(controller: controller),
                    const SizedBox(height: 18),
                    const _UpgradeButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_rounded, color: _teal, size: 24),
          ),
          const SizedBox(width: 14),
          const Text(
            'Event Ticket',
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

// ─── Header Text ──────────────────────────────────────────────────────────

class _HeaderText extends StatelessWidget {
  const _HeaderText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
            ),
            children: [
              TextSpan(text: 'Live ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Concert', style: TextStyle(color: _teal)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Experience the sound where it lives. Select your dimension and find the nearest sonic surge.',
          style: TextStyle(
            color: _dimText,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── City Chips ─────────────────────────────────────────────────────────────

class _CityChips extends StatelessWidget {
  const _CityChips({required this.controller});

  final EventTicketController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.cities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = controller.cities[index];
          return Obx(() {
            final isSelected = controller.selectedCityIndex.value == index;
            return GestureDetector(
              onTap: () => controller.selectCity(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? _teal : _chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: _chipBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  city.label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0B0B0C) : _dimText,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

// ─── Live Map Card ──────────────────────────────────────────────────────────

class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({required this.liveStream});

  final LiveStreamModel liveStream;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 236,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF15151B)),
            _MapRoadLines(),
            Positioned(
              top: 54,
              left: 46,
              child: _MapMarker(label: liveStream.markerLabel),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4D4D),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          liveStream.statusLabel,
                          style: const TextStyle(
                            color: Color(0xFFFF4D4D),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                liveStream.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                liveStream.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _dimText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            liveStream.ctaLabel,
                            style: const TextStyle(
                              color: Color(0xFF0B0B0C),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bedtime_rounded, color: _teal, size: 16),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Decorative road lines to give the live-map card a map-like texture.
class _MapRoadLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget line({
      required double top,
      required double left,
      required double width,
      required double angle,
      double opacity = 0.35,
    }) {
      return Positioned(
        top: top,
        left: left,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: width,
            height: 2,
            color: const Color(0xFFE07A3F).withValues(alpha: opacity),
          ),
        ),
      );
    }

    return Stack(
      children: [
        line(top: 30, left: -20, width: 220, angle: 0.5),
        line(top: 90, left: 40, width: 260, angle: -0.25),
        line(top: 140, left: -10, width: 200, angle: 0.15),
        line(top: 180, left: 120, width: 240, angle: 0.6),
        line(top: 60, left: 180, width: 180, angle: -0.6),
      ],
    );
  }
}

// ─── Countdown Strip ────────────────────────────────────────────────────────

class _CountdownStrip extends StatelessWidget {
  const _CountdownStrip({required this.countdown});

  final LiveCountdownModel countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  countdown.image,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 46,
                    height: 46,
                    color: const Color(0xFF1E1E25),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white24, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countdown.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countdown.artist,
                      style: const TextStyle(
                        color: _dimText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: countdown.progress,
              minHeight: 4,
              backgroundColor: const Color(0xFF2E2E38),
              valueColor: const AlwaysStoppedAnimation(_violet),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            countdown.remainingLabel,
            style: const TextStyle(
              color: _dimText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Genre Chips ────────────────────────────────────────────────────────────

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.controller});

  final EventTicketController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.genres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = controller.genres[index];
          return Obx(() {
            final isSelected = controller.selectedGenreIndex.value == index;
            return GestureDetector(
              onTap: () => controller.selectGenre(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? _teal : _chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: _chipBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  genre.label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0B0B0C) : _dimText,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Upcoming Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        const Text(
          'Sort by...',
          style: TextStyle(
            color: _dimText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.tune_rounded, color: _teal, size: 18),
      ],
    );
  }
}

// ─── Event Cards ────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventTicketModel event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => GetTicketScreen(event: event)),
      child: event.isLarge ? _LargeEventCard(event: event) : _CompactEventCard(event: event),
    );
  }
}

class _LargeEventCard extends StatelessWidget {
  const _LargeEventCard({required this.event});

  final EventTicketModel event;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Image.asset(
              event.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E1E25)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.3, 0.65, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Row(
              children: [
                for (final tag in event.tags) ...[
                  _EventTag(label: tag, isPrimary: tag == event.tags.first),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: _dimText, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      '${event.dateLabel} • ${event.venue}',
                      style: const TextStyle(
                        color: _dimText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.showPriceLabel)
                            const Text(
                              'STARTING FROM',
                              style: TextStyle(
                                color: _dimText,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          Text(
                            '${event.currency}${event.price}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: _violet,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Get Tickets',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTag extends StatelessWidget {
  const _EventTag({required this.label, required this.isPrimary});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary ? _violet : Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CompactEventCard extends StatelessWidget {
  const _CompactEventCard({required this.event});

  final EventTicketModel event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1.5,
            child: Image.asset(
              event.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1E1E25),
                child: const Icon(Icons.image_rounded, color: Colors.white24, size: 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _dimText, size: 14),
            const SizedBox(width: 4),
            Text(
              event.venue,
              style: const TextStyle(
                color: _dimText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${event.currency}${event.price}',
              style: const TextStyle(
                color: _teal,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _chipBg,
                  border: Border.all(color: _chipBorder),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Access Pass ─────────────────────────────────────────────────────────────

class _AccessPassHeader extends StatelessWidget {
  const _AccessPassHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Infinite Access Pass',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Get priority booking, zero service fees, and access to the VIP Refraction Lounge for all major city events.',
          style: TextStyle(
            color: _dimText,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.controller});

  final EventTicketController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < controller.plans.length; i++) ...[
          Expanded(
            child: Obx(
              () => _PlanCard(
                plan: controller.plans[i],
                isSelected: controller.selectedPlanIndex.value == i,
                onTap: () => controller.selectPlan(i),
              ),
            ),
          ),
          if (i != controller.plans.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final AccessPlanModel plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _violet : _chipBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              plan.name,
              style: TextStyle(
                color: isSelected ? Colors.white : _dimText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${plan.currency}${plan.price}${plan.period}',
              style: TextStyle(
                color: isSelected ? _teal : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [_violet, Color(0xFF5B6EF5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Upgrade Now',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

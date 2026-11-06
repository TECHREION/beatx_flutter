import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/helpers/json_read.dart';
import '../../controller/event_ticket_controller.dart';
import '../../model/event_model.dart';
import '../../model/shop_model.dart';
import 'get_tickets_screen.dart';
import 'my_tickets_screen.dart';
import 'shop_common.dart';

const _teal = Color(0xFF3BDDEB);
const _violet = Color(0xFFAA5CE0);
const _dimText = Color(0xFFA7A3AA);
const _chipBg = Color(0xFF1C1C22);
const _chipBorder = Color(0xFF2E2E38);

class EventTicketsScreen extends StatelessWidget {
  const EventTicketsScreen({super.key});

  /// Lets a finished ticket purchase return to this list.
  static const routeName = '/events';

  /// Opens the list under [routeName].
  static Future<void>? open() =>
      Get.to<void>(() => const EventTicketsScreen(), routeName: routeName);

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
                    Obx(
                      () => _FilterChips(
                        options: controller.cities.toList(),
                        selected: controller.selectedCity.value,
                        onSelect: controller.selectCity,
                      ),
                    ),
                    Obx(() {
                      final live = controller.liveEvent;
                      if (live == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: GestureDetector(
                          onTap: () => _openEvent(live),
                          child: _LiveMapCard(event: live),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    Obx(
                      () => _FilterChips(
                        options: EventTicketController.types,
                        selected: controller.selectedType.value,
                        onSelect: controller.selectType,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(controller: controller),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const ShopLoading();
                      }
                      if (controller.errorMessage.value.isNotEmpty) {
                        return Center(
                          child: ShopMessage(
                            icon: Icons.cloud_off_rounded,
                            message: controller.errorMessage.value,
                            onRetry: controller.load,
                          ),
                        );
                      }
                      if (controller.events.isEmpty) {
                        return const Center(
                          child: ShopMessage(
                            icon: Icons.event_busy_rounded,
                            message: 'No upcoming events match these filters.',
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (index, event)
                              in controller.events.indexed) ...[
                            _EventCard(event: event, isLarge: index == 0),
                            const SizedBox(height: 16),
                          ],
                          ShopLoadMore(
                            hasMore: controller.hasMore,
                            isLoading: controller.isLoadingMore.value,
                            onTap: controller.loadMore,
                          ),
                        ],
                      );
                    }),
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

void _openEvent(ShopEvent event) =>
    Get.to<void>(() => GetTicketScreen(event: event));

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
          const Expanded(
            child: Text(
              'Event Ticket',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _teal,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to<void>(() => const MyTicketsScreen()),
            child: const Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'My Tickets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
              TextSpan(
                text: 'Live ',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Concert',
                style: TextStyle(color: _teal),
              ),
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

// ─── Filter Chips ───────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<ShopFilterOption> options;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selected == option.value;
          return GestureDetector(
            onTap: () => onSelect(option.value),
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
                option.label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0B0B0C) : _dimText,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Live Map Card ──────────────────────────────────────────────────────────

class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({required this.event});

  final ShopEvent event;

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
            Positioned(top: 54, left: 46, child: _MapMarker(label: event.city)),
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
                        const Text(
                          'LIVE NOW',
                          style: TextStyle(
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
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                event.place,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Text(
                            'View Event',
                            style: TextStyle(
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

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.controller});

  final EventTicketController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Upcoming Events',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        PopupMenuButton<String>(
          color: const Color(0xFF1C1C22),
          onSelected: controller.selectSort,
          itemBuilder: (_) => [
            for (final sort in EventTicketController.sorts)
              PopupMenuItem(
                value: sort.value,
                child: Text(
                  sort.label,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
          ],
          child: Obx(
            () => Row(
              children: [
                Text(
                  EventTicketController.sorts
                      .firstWhere(
                        (sort) => sort.value == controller.selectedSort.value,
                      )
                      .label,
                  style: const TextStyle(
                    color: _dimText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.tune_rounded, color: _teal, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Event Cards ────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.isLarge});

  final ShopEvent event;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEvent(event),
      child: isLarge
          ? _LargeEventCard(event: event)
          : _CompactEventCard(event: event),
    );
  }
}

class _LargeEventCard extends StatelessWidget {
  const _LargeEventCard({required this.event});

  final ShopEvent event;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(aspectRatio: 1.05, child: ShopImage(url: event.coverUrl)),
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
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: _dimText,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${event.dateLabel} • ${event.place}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _dimText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
                          if (event.tiers.length > 1)
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
                            event.ticketPriceDisplay ?? missingDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _violet,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        event.isSoldOut ? 'Sold Out' : 'Get Tickets',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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

  final ShopEvent event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1.5,
            child: ShopImage(url: event.coverUrl),
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
            Expanded(
              child: Text(
                [
                  event.dateLabel,
                  event.place,
                ].where((part) => part.isNotEmpty).join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _dimText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              event.ticketPriceDisplay ?? missingDisplay,
              style: const TextStyle(
                color: _teal,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (event.isSoldOut)
              const Text(
                'SOLD OUT',
                style: TextStyle(
                  color: _dimText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _chipBg,
                  border: Border.all(color: _chipBorder),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

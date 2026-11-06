import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/helpers/json_read.dart';
import '../../controller/my_tickets_controller.dart';
import '../../model/event_model.dart';
import 'shop_common.dart';

const _teal = Color(0xFF3BDDEB);
const _dimText = Color(0xFFA7A3AA);

/// The user's paid tickets, and the entry code each one needs at the door.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final MyTicketsController controller = MyTicketsController()..onInit();

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0C),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _teal),
        title: const Text(
          'My Tickets',
          style: TextStyle(
            color: _teal,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Obx(
              () => Row(
                children: [
                  for (final (value, label) in const [
                    ('upcoming', 'Upcoming'),
                    ('past', 'Past'),
                  ]) ...[
                    _TabChip(
                      label: label,
                      isSelected: controller.tab.value == value,
                      onTap: () => controller.selectTab(value),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const ShopLoading();
              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: ShopMessage(
                    icon: Icons.cloud_off_rounded,
                    message: controller.errorMessage.value,
                    onRetry: controller.load,
                  ),
                );
              }
              if (controller.tickets.isEmpty) {
                return Center(
                  child: ShopMessage(
                    icon: Icons.confirmation_number_outlined,
                    message: controller.tab.value == 'past'
                        ? 'No past tickets.'
                        : 'No upcoming tickets yet.',
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final ticket in controller.tickets) ...[
                    _TicketCard(ticket: ticket),
                    const SizedBox(height: 12),
                  ],
                  ShopLoadMore(
                    hasMore: controller.hasMore,
                    isLoading: controller.isLoadingMore.value,
                    onTap: controller.loadMore,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _teal : const Color(0xFF1C1C22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0B0B0C) : _dimText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final TicketOrder ticket;

  @override
  Widget build(BuildContext context) {
    final event = ticket.event;
    final date = event?.eventDate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ShopImage(
                    url: event?.coverUrl,
                    icon: Icons.confirmation_number_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event?.title ?? ticket.eventTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (date != null) DateFormat('MMM d, y').format(date),
                        ?event?.place,
                      ].where((part) => part.isNotEmpty).join(' • '),
                      style: const TextStyle(color: _dimText, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${ticket.quantity} × ${ticket.tierName} • '
                      '${ticket.totalDisplay ?? missingDisplay}',
                      style: const TextStyle(color: _dimText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2E2E38), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CodeBlock(label: 'BOOKING', value: ticket.bookingRef),
              ),
              if (ticket.entryCode.isNotEmpty)
                Expanded(
                  child: _CodeBlock(
                    label: 'ENTRY CODE',
                    value: ticket.entryCode,
                    highlight: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _dimText,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: TextStyle(
            color: highlight ? _teal : Colors.white,
            fontSize: highlight ? 18 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: highlight ? 1.5 : 0,
          ),
        ),
      ],
    );
  }
}

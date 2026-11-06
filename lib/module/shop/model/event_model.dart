import 'package:intl/intl.dart';

import '../../../core/helpers/json_read.dart';
import 'purchase_model.dart';

/// The day an event is on. The API stores its wall-clock date and time as if
/// UTC (`2026-12-01T18:00Z` with `eventTime: "18:00"`), so converting to local
/// time would move an evening show to the next day in Dhaka.
DateTime? _readEventDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toUtc();

class TicketTier {
  const TicketTier({
    required this.id,
    required this.name,
    this.remaining = 0,
    this.priceDisplay,
  });

  final String id;
  final String name;
  final int remaining;
  final String? priceDisplay;

  bool get isSoldOut => remaining <= 0;

  factory TicketTier.fromJson(Map<String, dynamic> json) {
    final remaining = json['remaining'];
    return TicketTier(
      id: readId(json),
      name: readString(json['name']),
      remaining: remaining == null
          ? readInt(json['quantity']) - readInt(json['sold'])
          : readInt(remaining),
      priceDisplay: readDisplay(json['priceDisplay']),
    );
  }
}

class ShopEvent {
  const ShopEvent({
    required this.id,
    required this.title,
    this.coverUrl = '',
    this.venue = '',
    this.city = '',
    this.description = '',
    this.eventType = '',
    this.eventDate,
    this.eventTime = '',
    this.ticketPriceDisplay,
    this.availability = 'available',
    this.isLive = false,
    this.soldOut = false,
    this.tiers = const [],
  });

  final String id;
  final String title;
  final String coverUrl;
  final String venue;
  final String city;
  final String description;
  final String eventType;
  final DateTime? eventDate;
  final String eventTime;

  /// The lowest tier's price.
  final String? ticketPriceDisplay;

  /// `available`, `low` or `sold_out`.
  final String availability;
  final bool isLive;
  final bool soldOut;
  final List<TicketTier> tiers;

  bool get isSoldOut => soldOut || availability == 'sold_out';

  String get dateLabel =>
      eventDate == null ? '' : DateFormat('MMM d, y').format(eventDate!);

  String get place => [venue, city].where((part) => part.isNotEmpty).join(', ');

  List<String> get tags => [
    if (eventType.isNotEmpty) eventType.toUpperCase(),
    if (isSoldOut)
      'SOLD OUT'
    else if (availability == 'low')
      'LOW AVAILABILITY',
  ];

  factory ShopEvent.fromJson(Map<String, dynamic> json) => ShopEvent(
    id: readId(json),
    title: readString(json['title']),
    coverUrl: readString(json['coverUrl']),
    venue: readString(json['venue']),
    city: readString(json['city']),
    description: readString(json['description']),
    eventType: readString(json['eventType']),
    eventDate: _readEventDate(json['eventDate']),
    eventTime: readString(json['eventTime']),
    ticketPriceDisplay: readDisplay(json['ticketPriceDisplay']),
    availability: json['availability']?.toString() ?? 'available',
    isLive: json['isLive'] == true,
    soldOut: json['soldOut'] == true,
    tiers: readMaps(json['ticketTiers']).map(TicketTier.fromJson).toList(),
  );
}

/// `GET /events/:id/quote`. Checks the price; it does not hold seats.
class TicketQuote {
  const TicketQuote({
    this.tierId = '',
    this.quantity = 1,
    this.unitPriceDisplay,
    this.totalDisplay,
    this.coinsAwarded = 0,
  });

  final String tierId;
  final int quantity;
  final String? unitPriceDisplay;
  final String? totalDisplay;
  final int coinsAwarded;

  factory TicketQuote.fromJson(Map<String, dynamic> json) => TicketQuote(
    tierId: readString(json['tierId']),
    quantity: readInt(json['quantity']),
    unitPriceDisplay: readDisplay(json['unitPriceDisplay']),
    totalDisplay: readDisplay(json['totalDisplay']),
    coinsAwarded: readInt(json['coinsAwarded']),
  );
}

/// The event attached to a ticket order, or null if it was deleted.
class TicketEvent {
  const TicketEvent({
    required this.title,
    this.coverUrl = '',
    this.place = '',
    this.eventDate,
  });

  final String title;
  final String coverUrl;
  final String place;
  final DateTime? eventDate;

  factory TicketEvent.fromJson(Map<String, dynamic> json) => TicketEvent(
    title: readString(json['title']),
    coverUrl: readString(json['coverUrl']),
    place: [
      readString(json['venue']),
      readString(json['city']),
    ].where((part) => part.isNotEmpty).join(', '),
    eventDate: _readEventDate(json['eventDate']),
  );
}

class TicketOrder implements Purchase {
  const TicketOrder({
    required this.id,
    required this.status,
    this.bookingRef = '',
    this.eventTitle = '',
    this.tierName = '',
    this.quantity = 1,
    this.totalDisplay,
    this.coinsAwarded = 0,
    this.paymentUrl = '',
    this.entryCode = '',
    this.event,
  });

  @override
  final String id;
  @override
  final PurchaseStatus status;
  final String bookingRef;
  final String eventTitle;
  final String tierName;
  final int quantity;
  final String? totalDisplay;
  @override
  final int coinsAwarded;
  @override
  final String paymentUrl;
  @override
  final String entryCode;
  final TicketEvent? event;

  factory TicketOrder.fromJson(Map<String, dynamic> json) {
    final event = json['event'];
    return TicketOrder(
      id: readId(json),
      status: PurchaseStatus.parse(json['status']),
      bookingRef: readString(json['bookingRef']),
      eventTitle: readString(json['eventTitle']),
      tierName: readString(json['tierName']),
      quantity: readInt(json['quantity']),
      totalDisplay: readDisplay(json['totalDisplay']),
      coinsAwarded: readInt(json['coinsAwarded']),
      paymentUrl: readString(json['paymentUrl']),
      entryCode: readString(json['entryCode']),
      event: event is Map
          ? TicketEvent.fromJson(Map<String, dynamic>.from(event))
          : null,
    );
  }
}

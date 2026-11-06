import '../../../core/helpers/json_read.dart';

enum PurchaseStatus {
  pending,
  paid,
  failed,
  expired;

  static PurchaseStatus parse(Object? value) => switch (value?.toString()) {
    'paid' => PurchaseStatus.paid,
    'failed' => PurchaseStatus.failed,
    'expired' => PurchaseStatus.expired,
    _ => PurchaseStatus.pending,
  };
}

/// Where to send the buyer to pay. Only the url matters to the app, and it is
/// the same flow for every gateway.
class PaymentInfo {
  const PaymentInfo({required this.redirectUrl});

  final String redirectUrl;

  /// Null when nothing is due, in which case the order is already paid.
  static PaymentInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final url = readString(json['redirectUrl']);
    return url.isEmpty ? null : PaymentInfo(redirectUrl: url);
  }
}

/// What a merchandise order and a ticket order have in common.
abstract interface class Purchase {
  String get id;
  PurchaseStatus get status;
  int get coinsAwarded;

  /// Where a still-unpaid purchase can be paid, when the server says.
  String get paymentUrl;

  /// The door code on a paid ticket; empty for merchandise.
  String get entryCode;
}

/// `{ order, payment }`, as creating an order or buying a ticket answers.
class CreatedPurchase<T extends Purchase> {
  const CreatedPurchase({required this.purchase, this.payment});

  final T purchase;
  final PaymentInfo? payment;
}

/// One product on an order request.
class OrderItemRequest {
  const OrderItemRequest({
    required this.productId,
    required this.quantity,
    this.size,
    this.color,
  });

  final String productId;
  final int quantity;
  final String? size;
  final String? color;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    if (size != null) 'size': size,
    if (color != null) 'color': color,
  };
}

class ShippingAddress {
  const ShippingAddress({
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.city,
    required this.postalCode,
  });

  final String firstName;
  final String lastName;
  final String address;
  final String city;
  final String postalCode;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'address': address,
    'city': city,
    'postalCode': postalCode,
  };
}

class QuoteLine {
  const QuoteLine({
    required this.name,
    this.image = '',
    this.quantity = 1,
    this.size = '',
    this.color = '',
    this.lineTotalDisplay,
  });

  final String name;
  final String image;
  final int quantity;
  final String size;
  final String color;
  final String? lineTotalDisplay;

  factory QuoteLine.fromJson(Map<String, dynamic> json) => QuoteLine(
    name: readString(json['name']),
    image: readString(json['image']),
    quantity: readInt(json['quantity']),
    size: readString(json['size']),
    color: readString(json['color']),
    lineTotalDisplay: readDisplay(json['lineTotalDisplay']),
  );
}

/// `POST /orders/quote`. The server's own prices; nothing is added up here.
class OrderQuote {
  const OrderQuote({
    this.items = const [],
    this.subtotalDisplay,
    this.shippingFeeDisplay,
    this.vatDisplay,
    this.totalDisplay,
    this.coinsAwarded = 0,
  });

  final List<QuoteLine> items;
  final String? subtotalDisplay;
  final String? shippingFeeDisplay;
  final String? vatDisplay;
  final String? totalDisplay;
  final int coinsAwarded;

  factory OrderQuote.fromJson(Map<String, dynamic> json) => OrderQuote(
    items: readMaps(json['items']).map(QuoteLine.fromJson).toList(),
    subtotalDisplay: readDisplay(json['subtotalDisplay']),
    shippingFeeDisplay: readDisplay(json['shippingFeeDisplay']),
    vatDisplay: readDisplay(json['vatDisplay']),
    totalDisplay: readDisplay(json['totalDisplay']),
    coinsAwarded: readInt(json['coinsAwarded']),
  );
}

class ShopOrder implements Purchase {
  const ShopOrder({
    required this.id,
    required this.status,
    this.orderNumber = '',
    this.coinsAwarded = 0,
    this.paymentUrl = '',
  });

  @override
  final String id;
  @override
  final PurchaseStatus status;
  final String orderNumber;
  @override
  final int coinsAwarded;
  @override
  final String paymentUrl;
  @override
  String get entryCode => '';

  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
    id: readId(json),
    status: PurchaseStatus.parse(json['status']),
    orderNumber: readString(json['orderNumber']),
    coinsAwarded: readInt(json['coinsAwarded']),
    paymentUrl: readString(json['paymentUrl']),
  );
}

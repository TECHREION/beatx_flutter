import 'package:beatx_flutter/core/api_handler/failure.dart';
import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/shop/model/event_model.dart';
import 'package:beatx_flutter/module/shop/model/product_model.dart';
import 'package:beatx_flutter/module/shop/model/purchase_model.dart';
import 'package:beatx_flutter/module/shop/services/shop_interface.dart';
import 'package:dartz/dartz.dart';

/// Shapes copied from the live test server.
final tShirt = ShopProduct.fromJson(const {
  '_id': 'p1',
  'title': 'Tour T-Shirt',
  'images': [
    {'url': 'https://example.com/black.webp', 'color': 'Black'},
  ],
  'category': 'apparel',
  'artistName': 'Demo Artist',
  'description': 'Official tour merch',
  'price': 2999,
  'priceDisplay': '৳29.99',
  'stock': 99,
  'coinReward': 5,
  'hasSizeVariants': true,
  'availableSizes': ['S', 'M'],
  'variants': <Object>[],
  'colorVariants': [
    {'name': 'Black', 'hex': '#000000', 'stock': 59, 'images': <Object>[]},
    {'name': 'Prism', 'hex': '#8b5cf6', 'stock': 0, 'images': <Object>[]},
  ],
});

final dhakaLive = ShopEvent.fromJson(const {
  '_id': 'e1',
  'title': 'Live in Dhaka',
  'venue': 'City Arena',
  'city': 'Dhaka',
  'eventDate': '2026-12-01T18:00:00.000Z',
  'eventTime': '18:00',
  'ticketPriceDisplay': '৳25.00',
  'availability': 'available',
  'ticketTiers': [
    {
      '_id': 't1',
      'name': 'General',
      'price': 2500,
      'quantity': 500,
      'sold': 2,
      'remaining': 498,
      'priceDisplay': '৳25.00',
    },
    {
      '_id': 't2',
      'name': 'VIP',
      'price': 9000,
      'quantity': 3,
      'sold': 0,
      'remaining': 3,
      'priceDisplay': '৳90.00',
    },
  ],
});

Left<DataCRUDFailure, T> serverError<T>(String message) => Left(
  DataCRUDFailure(
    failure: Failure.unknownFailure,
    uiMessage: message,
    fullError: message,
  ),
);

Left<DataCRUDFailure, T> timedOut<T>() => Left(
  DataCRUDFailure(failure: Failure.timeout, fullError: 'Connection timeout!'),
);

final class FakeShop extends ShopInterface {
  /// Next answers for creating, consumed in order.
  final createAnswers = <Request<Success<CreatedPurchase<ShopOrder>>>>[];
  final buyAnswers = <Request<Success<CreatedPurchase<TicketOrder>>>>[];

  final orderKeys = <String>[];
  final ticketKeys = <String>[];
  final ticketQuotes = <String>[];
  final productCategoriesAsked = <String>[];
  ShopOrder orderState = const ShopOrder(
    id: 'o1',
    status: PurchaseStatus.paid,
    coinsAwarded: 7,
  );
  TicketOrder ticketState = const TicketOrder(
    id: 'k1',
    status: PurchaseStatus.paid,
    entryCode: 'ABCD1234',
  );
  Request<Success<OrderQuote>>? quoteAnswer;

  @override
  FutureRequest<Success<List<String>>> getCategories() async =>
      Right(Success(data: const ['apparel', 'digital-art']));

  @override
  FutureRequest<Success<PagedResult<ShopProduct>>> getProducts({
    String category = '',
    required int page,
    required int limit,
  }) async {
    productCategoriesAsked.add(category);
    return Right(
      Success(
        data: PagedResult(items: [tShirt], total: 1, page: page, limit: limit),
      ),
    );
  }

  @override
  FutureRequest<Success<ShopProduct>> getProduct(String id) async =>
      Right(Success(data: tShirt));

  @override
  FutureRequest<Success<RatingSummary>> getRatingSummary(String id) async =>
      Right(Success(data: const RatingSummary()));

  @override
  FutureRequest<Success<OrderQuote>> quoteOrder(
    List<OrderItemRequest> items,
  ) async =>
      quoteAnswer ??
      Right(
        Success(
          data: const OrderQuote(
            items: [
              QuoteLine(
                name: 'Tour T-Shirt',
                size: 'M',
                lineTotalDisplay: '৳29.99',
              ),
            ],
            subtotalDisplay: '৳29.99',
            shippingFeeDisplay: '৳60.00',
            vatDisplay: '৳0.00',
            totalDisplay: '৳89.99',
            coinsAwarded: 7,
          ),
        ),
      );

  @override
  FutureRequest<Success<CreatedPurchase<ShopOrder>>> createOrder({
    required List<OrderItemRequest> items,
    required ShippingAddress address,
    required String idempotencyKey,
  }) async {
    orderKeys.add(idempotencyKey);
    return createAnswers.removeAt(0);
  }

  @override
  FutureRequest<Success<ShopOrder>> getOrder(String id) async =>
      Right(Success(data: orderState));

  @override
  FutureRequest<Success<PagedResult<ShopEvent>>> getEvents({
    String city = '',
    String eventType = '',
    String sort = '',
    required int page,
    required int limit,
  }) async => Right(
    Success(
      data: PagedResult(items: [dhakaLive], total: 1, page: page, limit: limit),
    ),
  );

  @override
  FutureRequest<Success<ShopEvent>> getEvent(String id) async =>
      Right(Success(data: dhakaLive));

  @override
  FutureRequest<Success<TicketQuote>> quoteTicket({
    required String eventId,
    required int quantity,
    String? tierId,
  }) async {
    ticketQuotes.add('$tierId:$quantity');
    return Right(
      Success(
        data: TicketQuote(
          tierId: tierId ?? '',
          quantity: quantity,
          unitPriceDisplay: '৳25.00',
          totalDisplay: '৳${25 * quantity}.00',
        ),
      ),
    );
  }

  @override
  FutureRequest<Success<CreatedPurchase<TicketOrder>>> buyTicket({
    required String eventId,
    required int quantity,
    String? tierId,
    required String idempotencyKey,
  }) async {
    ticketKeys.add(idempotencyKey);
    return buyAnswers.removeAt(0);
  }

  @override
  FutureRequest<Success<TicketOrder>> getTicket(String id) async =>
      Right(Success(data: ticketState));

  @override
  FutureRequest<Success<PagedResult<TicketOrder>>> getTickets({
    required String tab,
    required int page,
    required int limit,
  }) async => Right(
    Success(
      data: PagedResult(
        items: [ticketState],
        total: 1,
        page: page,
        limit: limit,
      ),
    ),
  );
}

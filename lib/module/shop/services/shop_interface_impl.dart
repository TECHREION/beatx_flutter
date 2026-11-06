import 'package:app_pigeon/app_pigeon.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/event_model.dart';
import '../model/product_model.dart';
import '../model/purchase_model.dart';
import 'shop_interface.dart';

final class ShopInterfaceImpl extends ShopInterface {
  ShopInterfaceImpl(this.appPigeon);

  final AuthorizedPigeon appPigeon;

  Map<String, dynamic> _data(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Options _idempotent(String key) => Options(headers: {'Idempotency-Key': key});

  CreatedPurchase<T> _created<T extends Purchase>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = _data(body);
    final purchase = data['order'];
    return CreatedPurchase<T>(
      purchase: fromJson(
        purchase is Map ? Map<String, dynamic>.from(purchase) : const {},
      ),
      payment: PaymentInfo.fromJson(data['payment']),
    );
  }

  @override
  FutureRequest<Success<List<String>>> getCategories() => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(ApiEndpoints.productCategories);
      return Success(
        data: pagedEntries(
          response.data is Map ? response.data['data'] : null,
        ).map((category) => category.toString()).toList(),
      );
    },
  );

  @override
  FutureRequest<Success<PagedResult<ShopProduct>>> getProducts({
    String category = '',
    required int page,
    required int limit,
  }) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(
        ApiEndpoints.products,
        queryParameters: {
          if (category.isNotEmpty) 'category': category,
          'page': page,
          'limit': limit,
        },
      );
      return Success(
        data: PagedResult.fromJson(_data(response.data), ShopProduct.fromJson),
      );
    },
  );

  @override
  FutureRequest<Success<ShopProduct>> getProduct(String id) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(ApiEndpoints.product(id: id));
      return Success(data: ShopProduct.fromJson(_data(response.data)));
    },
  );

  @override
  FutureRequest<Success<RatingSummary>> getRatingSummary(String productId) =>
      asyncTryCatch(
        tryFunc: () async {
          final response = await appPigeon.get(
            ApiEndpoints.productReviews(id: productId),
            queryParameters: {'page': 1, 'limit': 1},
          );
          final summary = _data(response.data)['summary'];
          return Success(
            data: RatingSummary.fromJson(
              summary is Map ? Map<String, dynamic>.from(summary) : const {},
            ),
          );
        },
      );

  @override
  FutureRequest<Success<OrderQuote>> quoteOrder(List<OrderItemRequest> items) =>
      asyncTryCatch(
        tryFunc: () async {
          final response = await appPigeon.post(
            ApiEndpoints.orderQuote,
            data: {'items': items.map((item) => item.toJson()).toList()},
          );
          return Success(data: OrderQuote.fromJson(_data(response.data)));
        },
      );

  @override
  FutureRequest<Success<CreatedPurchase<ShopOrder>>> createOrder({
    required List<OrderItemRequest> items,
    required ShippingAddress address,
    required String idempotencyKey,
  }) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.post(
        ApiEndpoints.orders,
        data: {
          'items': items.map((item) => item.toJson()).toList(),
          'shippingAddress': address.toJson(),
        },
        options: _idempotent(idempotencyKey),
      );
      return Success(data: _created(response.data, ShopOrder.fromJson));
    },
  );

  @override
  FutureRequest<Success<ShopOrder>> getOrder(String id) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(ApiEndpoints.order(id: id));
      return Success(data: ShopOrder.fromJson(_data(response.data)));
    },
  );

  @override
  FutureRequest<Success<PagedResult<ShopEvent>>> getEvents({
    String city = '',
    String eventType = '',
    String sort = '',
    required int page,
    required int limit,
  }) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(
        ApiEndpoints.events,
        queryParameters: {
          if (city.isNotEmpty) 'city': city,
          if (eventType.isNotEmpty) 'eventType': eventType,
          if (sort.isNotEmpty) 'sort': sort,
          'page': page,
          'limit': limit,
        },
      );
      return Success(
        data: PagedResult.fromJson(_data(response.data), ShopEvent.fromJson),
      );
    },
  );

  @override
  FutureRequest<Success<ShopEvent>> getEvent(String id) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(ApiEndpoints.event(id: id));
      return Success(data: ShopEvent.fromJson(_data(response.data)));
    },
  );

  @override
  FutureRequest<Success<TicketQuote>> quoteTicket({
    required String eventId,
    required int quantity,
    String? tierId,
  }) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(
        ApiEndpoints.eventQuote(id: eventId),
        queryParameters: {'quantity': quantity, 'tierId': ?tierId},
      );
      return Success(data: TicketQuote.fromJson(_data(response.data)));
    },
  );

  @override
  FutureRequest<Success<CreatedPurchase<TicketOrder>>> buyTicket({
    required String eventId,
    required int quantity,
    String? tierId,
    required String idempotencyKey,
  }) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.post(
        ApiEndpoints.eventBuy(id: eventId),
        data: {'quantity': quantity, 'tierId': ?tierId},
        options: _idempotent(idempotencyKey),
      );
      return Success(data: _created(response.data, TicketOrder.fromJson));
    },
  );

  @override
  FutureRequest<Success<TicketOrder>> getTicket(String id) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(ApiEndpoints.ticket(id: id));
      return Success(data: TicketOrder.fromJson(_data(response.data)));
    },
  );

  @override
  FutureRequest<Success<PagedResult<TicketOrder>>> getTickets({
    required String tab,
    required int page,
    required int limit,
  }) => asyncTryCatch(
    tryFunc: () async {
      final response = await appPigeon.get(
        ApiEndpoints.tickets,
        queryParameters: {'tab': tab, 'page': page, 'limit': limit},
      );
      return Success(
        data: PagedResult.fromJson(_data(response.data), TicketOrder.fromJson),
      );
    },
  );
}

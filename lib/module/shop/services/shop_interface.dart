import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/event_model.dart';
import '../model/product_model.dart';
import '../model/purchase_model.dart';

abstract base class ShopInterface extends BaseRepository {
  FutureRequest<Success<List<String>>> getCategories();
  FutureRequest<Success<PagedResult<ShopProduct>>> getProducts({
    String category = '',
    required int page,
    required int limit,
  });
  FutureRequest<Success<ShopProduct>> getProduct(String id);
  FutureRequest<Success<RatingSummary>> getRatingSummary(String productId);

  /// Prices [items] without creating anything.
  FutureRequest<Success<OrderQuote>> quoteOrder(List<OrderItemRequest> items);

  /// Creates a pending order. Send the same [idempotencyKey] when retrying
  /// after a timeout, to get the first order back rather than a second one.
  FutureRequest<Success<CreatedPurchase<ShopOrder>>> createOrder({
    required List<OrderItemRequest> items,
    required ShippingAddress address,
    required String idempotencyKey,
  });
  FutureRequest<Success<ShopOrder>> getOrder(String id);

  /// [city], [eventType] and [sort] are left off the request when empty.
  FutureRequest<Success<PagedResult<ShopEvent>>> getEvents({
    String city = '',
    String eventType = '',
    String sort = '',
    required int page,
    required int limit,
  });
  FutureRequest<Success<ShopEvent>> getEvent(String id);
  FutureRequest<Success<TicketQuote>> quoteTicket({
    required String eventId,
    required int quantity,
    String? tierId,
  });
  FutureRequest<Success<CreatedPurchase<TicketOrder>>> buyTicket({
    required String eventId,
    required int quantity,
    String? tierId,
    required String idempotencyKey,
  });
  FutureRequest<Success<TicketOrder>> getTicket(String id);

  /// The user's paid tickets, for [tab] `upcoming` or `past`.
  FutureRequest<Success<PagedResult<TicketOrder>>> getTickets({
    required String tab,
    required int page,
    required int limit,
  });
}

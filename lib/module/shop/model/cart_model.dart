import 'purchase_model.dart';

/// A product in the cart. The price is only for showing; what the buyer pays
/// always comes from the server's quote at checkout.
class CartLine {
  const CartLine({
    required this.productId,
    required this.title,
    this.imageUrl,
    this.priceDisplay,
    this.size,
    this.color,
    this.quantity = 1,
  });

  final String productId;
  final String title;
  final String? imageUrl;
  final String? priceDisplay;
  final String? size;
  final String? color;
  final int quantity;

  /// Two lines are the same purchase when product, size and colour all match.
  bool sameItemAs(CartLine other) =>
      productId == other.productId &&
      size == other.size &&
      color == other.color;

  CartLine withQuantity(int value) => CartLine(
    productId: productId,
    title: title,
    imageUrl: imageUrl,
    priceDisplay: priceDisplay,
    size: size,
    color: color,
    quantity: value,
  );

  OrderItemRequest toRequest() => OrderItemRequest(
    productId: productId,
    quantity: quantity,
    size: size,
    color: color,
  );
}

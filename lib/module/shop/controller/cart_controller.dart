import 'package:get/get.dart';

import '../model/cart_model.dart';

/// The shopping cart. The API has no cart of its own, since orders take their
/// items directly, so this lives on the device for the length of the session.
class CartController extends GetxController {
  static CartController get instance => Get.find<CartController>();

  final lines = <CartLine>[].obs;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  void add(CartLine line) {
    final index = lines.indexWhere(line.sameItemAs);
    if (index < 0) {
      lines.add(line);
    } else {
      lines[index] = lines[index].withQuantity(
        lines[index].quantity + line.quantity,
      );
    }
  }

  /// Sets a line's quantity. Zero or less removes it.
  void setQuantity(CartLine line, int quantity) {
    final index = lines.indexWhere(line.sameItemAs);
    if (index < 0) return;
    if (quantity <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].withQuantity(quantity);
    }
  }

  void remove(CartLine line) => lines.removeWhere(line.sameItemAs);

  void clear() => lines.clear();
}

import 'package:get/get.dart';

import '../model/cart_model.dart';
import '../model/product_model.dart';
import '../services/shop_interface.dart';

class ShopDetailController extends GetxController {
  ShopDetailController(this.productId);

  final String productId;

  final product = Rxn<ShopProduct>();
  final rating = const RatingSummary().obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final selectedSize = RxnString();
  final selectedColor = Rxn<ProductColor>();

  ShopInterface get _shop => Get.find<ShopInterface>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';

    final results = await Future.wait([
      _shop.getProduct(productId),
      _shop.getRatingSummary(productId),
    ]);
    results[0].fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      final loaded = success.data as ShopProduct?;
      product.value = loaded;
      if (loaded != null) _preselect(loaded);
    });
    // The rating is a nicety: without it the page still sells the product.
    results[1].fold((_) {}, (success) {
      final summary = success.data as RatingSummary?;
      if (summary != null) rating.value = summary;
    });
    isLoading.value = false;
  }

  /// Picks the first colour on offer. A size is left for the buyer to choose,
  /// since a silently chosen size is an easy way to ship the wrong one.
  void _preselect(ShopProduct loaded) {
    selectedColor.value = loaded.colors.firstWhereOrNull(
      loaded.isColorAvailable,
    );
  }

  void selectSize(ProductSize size) {
    if (size.isAvailable) selectedSize.value = size.name;
  }

  void selectColor(ProductColor color) {
    if (product.value?.isColorAvailable(color) ?? false) {
      selectedColor.value = color;
    }
  }

  /// What stops this product being bought as selected, or null if nothing.
  String? get selectionProblem {
    final loaded = product.value;
    if (loaded == null) return 'This product is not available.';
    if (!loaded.inStock) return 'This product is out of stock.';
    if (loaded.hasSizeVariants && selectedSize.value == null) {
      return 'Please select a size';
    }
    return null;
  }

  /// The current selection as a cart line. Check [selectionProblem] first.
  CartLine toLine() {
    final loaded = product.value!;
    return CartLine(
      productId: loaded.id,
      title: loaded.title,
      imageUrl: loaded.imagesFor(selectedColor.value).firstOrNull,
      priceDisplay: loaded.priceDisplay,
      size: selectedSize.value,
      color: selectedColor.value?.name,
    );
  }
}

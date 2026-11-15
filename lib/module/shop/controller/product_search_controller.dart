import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/base/search_list_controller.dart';
import '../../../core/common/widget/search_collection.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/product_model.dart';
import '../model/shop_model.dart';
import '../services/shop_interface.dart';

/// Product search, behind `GET /products?q=`.
///
/// The backend matches whole words in a product's title and description. A
/// part-typed word, or an artist's name, finds nothing there, so the shared
/// [SearchListController] falls back to filtering the catalogue here by
/// [searchableText]. The "genre" filter of the shared screen is the product
/// category.
class ProductSearchController extends SearchListController<ShopProduct> {
  /// The category chips, filled from `GET /products/categories`.
  final categories = <SearchFilterOption>[].obs;

  ShopInterface get _shop => Get.find<ShopInterface>();

  @override
  void onInit() {
    _loadCategories();
    super.onInit();
  }

  Future<void> _loadCategories() async {
    final result = await _shop.getCategories();
    result.fold((_) {}, (success) {
      categories.assignAll([
        for (final slug in success.data ?? const <String>[])
          (id: slug, label: ShopFilterOption.fromSlug(slug).label),
      ]);
    });
  }

  @override
  FutureRequest<Success<PagedResult<ShopProduct>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) => _shop.getProducts(
    query: query,
    category: genreId,
    page: page,
    limit: limit,
  );

  @override
  String searchableText(ShopProduct product) =>
      '${product.title} ${product.artistName} ${product.category}';
}

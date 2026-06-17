import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/shop_detail_model.dart';

class ShopDetailController extends GetxController {
  final selectedSizeIndex = 1.obs;
  final selectedColorIndex = 0.obs;

  final product = const ShopDetailModel(
    title: 'Regular Fit Slogan',
    description:
        'The name says it all, the right size slightly snugs the body '
        'leaving enough room for comfort in the sleeves and waist.',
    price: '124.00',
    currency: r'$',
    coinPrice: 50,
    rating: 4.0,
    reviewCount: 45,
    inStock: true,
    image: 'assets/image/Container.png',
    category: 'Merch / Apparel',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: [
      Color(0xFF1C1C1C),
      Color(0xFFB47FE5),
      Color(0xFF3BDDEB),
    ],
  );

  void selectSize(int index) => selectedSizeIndex.value = index;
  void selectColor(int index) => selectedColorIndex.value = index;
}

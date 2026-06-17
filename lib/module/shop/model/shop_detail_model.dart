import 'package:flutter/material.dart';

class ShopDetailModel {
  const ShopDetailModel({
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.coinPrice,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.image,
    required this.category,
    required this.sizes,
    required this.colors,
  });

  final String title;
  final String description;
  final String price;
  final String currency;
  final int coinPrice;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String image;
  final String category;
  final List<String> sizes;
  final List<Color> colors;
}

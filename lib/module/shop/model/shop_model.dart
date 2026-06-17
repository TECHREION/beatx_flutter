import 'package:flutter/material.dart';

class PromoBannerModel {
  const PromoBannerModel({
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.accentColor,
    required this.image,
    this.titleColor = Colors.white,
  });

  final String title;
  final String subtitle;
  final String ctaText;
  final Color accentColor;
  final String image;
  final Color titleColor;
}

class ShopCategoryModel {
  const ShopCategoryModel({required this.label});

  final String label;
}

class ShopProductModel {
  const ShopProductModel({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.currency,
    required this.coinPrice,
    required this.image,
    this.isNew = false,
    this.discountLabel,
  });

  final String title;
  final String subtitle;
  final String price;
  final String currency;
  final int coinPrice;
  final String image;
  final bool isNew;
  final String? discountLabel;
}

class ArtistCollectionModel {
  const ArtistCollectionModel({
    required this.name,
    required this.genre,
    required this.itemCount,
    required this.cover,
  });

  final String name;
  final String genre;
  final int itemCount;
  final String cover;
}

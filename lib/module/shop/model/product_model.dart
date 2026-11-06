import 'package:flutter/material.dart';

import '../../../core/helpers/json_read.dart';

class ProductImage {
  const ProductImage({required this.url, this.color});

  final String url;
  final String? color;
}

/// A size on offer. [stock] is null when the product lists its sizes without
/// a count per size (`availableSizes`), which is then checked at checkout.
class ProductSize {
  const ProductSize({required this.name, this.stock});

  final String name;
  final int? stock;

  bool get isAvailable => stock == null || stock! > 0;
}

class ProductColor {
  const ProductColor({
    required this.name,
    required this.swatch,
    required this.stock,
    this.imageUrls = const [],
  });

  final String name;
  final Color swatch;
  final int stock;
  final List<String> imageUrls;
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.title,
    this.images = const [],
    this.category = '',
    this.artistName = '',
    this.description = '',
    this.price = 0,
    this.priceDisplay,
    this.stock = 0,
    this.coinReward = 0,
    this.hasSizeVariants = false,
    this.sizes = const [],
    this.colors = const [],
  });

  final String id;
  final String title;
  final List<ProductImage> images;
  final String category;
  final String artistName;
  final String description;

  /// Whole paisa. For calculations only; show [priceDisplay].
  final int price;
  final String? priceDisplay;
  final int stock;

  /// The base reward. What an order really awards comes from its quote.
  final int coinReward;

  /// When true, every order line must name a [ProductSize].
  final bool hasSizeVariants;
  final List<ProductSize> sizes;
  final List<ProductColor> colors;

  bool get inStock => stock > 0;
  String? get coverUrl => images.isEmpty ? null : images.first.url;

  /// Whether colours carry their own stock. Some products list colours that
  /// all read zero while the product itself is in stock; those colours are
  /// just labels, and greying them all out would make the product unbuyable.
  bool get colorsTrackStock => colors.any((color) => color.stock > 0);

  bool isColorAvailable(ProductColor color) =>
      inStock && (!colorsTrackStock || color.stock > 0);

  /// The pictures to show with [color] selected, or all of them.
  List<String> imagesFor(ProductColor? color) {
    final ofColor = color?.imageUrls ?? const <String>[];
    return ofColor.isNotEmpty
        ? ofColor
        : images.map((image) => image.url).toList(growable: false);
  }

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final variants = readMaps(json['variants']);
    final listed = json['availableSizes'];

    return ShopProduct(
      id: readId(json),
      title: readString(json['title']),
      images: [
        for (final image in readMaps(json['images']))
          if (readString(image['url']).isNotEmpty)
            ProductImage(
              url: readString(image['url']),
              color: image['color']?.toString(),
            ),
      ],
      category: readString(json['category']),
      artistName: readString(json['artistName']),
      description: readString(json['description']),
      price: readInt(json['price']),
      priceDisplay: readDisplay(json['priceDisplay']),
      stock: readInt(json['stock']),
      coinReward: readInt(json['coinReward']),
      hasSizeVariants: json['hasSizeVariants'] == true,
      sizes: variants.isNotEmpty
          ? [
              for (final variant in variants)
                ProductSize(
                  name: readString(variant['size']),
                  stock: readInt(variant['stock']),
                ),
            ]
          : [
              if (listed is List)
                for (final size in listed) ProductSize(name: size.toString()),
            ],
      colors: [
        for (final color in readMaps(json['colorVariants']))
          ProductColor(
            name: readString(color['name']),
            swatch: _parseHex(color['hex']),
            stock: readInt(color['stock']),
            imageUrls: [
              for (final image in readMaps(color['images']))
                if (readString(image['url']).isNotEmpty)
                  readString(image['url']),
            ],
          ),
      ],
    );
  }

  static Color _parseHex(Object? value) {
    final hex = value?.toString().replaceFirst('#', '') ?? '';
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null || hex.length != 6) return const Color(0xFF55555F);
    return Color(0xFF000000 | parsed);
  }
}

/// `summary` from `GET /products/:id/reviews`.
class RatingSummary {
  const RatingSummary({this.averageRating, this.reviewCount = 0});

  /// Null when there are no reviews.
  final double? averageRating;
  final int reviewCount;

  factory RatingSummary.fromJson(Map<String, dynamic> json) => RatingSummary(
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    reviewCount: readInt(json['reviewCount']),
  );
}

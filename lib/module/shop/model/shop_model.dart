import 'package:flutter/material.dart';

/// A static promotion at the top of the shop. It opens the event list, or
/// filters the grid to [category].
class PromoBannerModel {
  const PromoBannerModel({
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.accentColor,
    required this.image,
    this.titleColor = Colors.white,
    this.category,
  });

  final String title;
  final String subtitle;
  final String ctaText;
  final Color accentColor;
  final String image;
  final Color titleColor;
  final String? category;
}

/// A filter chip. An empty [value] means no filter.
class ShopFilterOption {
  const ShopFilterOption({required this.label, this.value = ''});

  final String label;
  final String value;

  /// `digital-art` as a chip spells it: `Digital Art`.
  factory ShopFilterOption.fromSlug(String slug) => ShopFilterOption(
    value: slug,
    label: slug
        .split(RegExp(r'[-_ ]'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' '),
  );
}

import 'package:flutter/material.dart';

class CategoryModel {
  const CategoryModel({
    required this.title,
    required this.image,
    required this.tint,
  });

  final String title;
  final String image;
  final Color tint;
}

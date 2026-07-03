import 'package:flutter/material.dart';

class CheckoutOrderItemModel {
  const CheckoutOrderItemModel({
    required this.image,
    required this.title,
    required this.tag,
    required this.quantity,
    required this.price,
    required this.currency,
  });

  final String image;
  final String title;
  final String tag;
  final int quantity;
  final String price;
  final String currency;
}

class PaymentMethodModel {
  const PaymentMethodModel({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

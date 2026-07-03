import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/checkout_model.dart';

class CheckoutController extends GetxController {
  final firstNameController = TextEditingController(text: 'Billal');
  final lastNameController = TextEditingController(text: 'Hossain');
  final addressController = TextEditingController(text: 'Moghbazar');
  final cityController = TextEditingController(text: 'Dhaka');
  final postalCodeController = TextEditingController(text: '1000');
  final promoCodeController = TextEditingController();

  final selectedPaymentIndex = 0.obs;

  final paymentMethods = const <PaymentMethodModel>[
    PaymentMethodModel(label: 'Card', icon: Icons.credit_card_rounded),
    PaymentMethodModel(label: 'Apple Pay', icon: Icons.apple_rounded),
    PaymentMethodModel(label: 'Cash', icon: Icons.payments_outlined),
  ];

  final savedCardNumber = '****  ****  ****  2512';

  final orderItems = const <CheckoutOrderItemModel>[
    CheckoutOrderItemModel(
      image: 'assets/image/Album Art.png',
      title: 'Prism Echoes LP',
      tag: "COLLECTOR'S EDITION",
      quantity: 1,
      price: '45.00',
      currency: r'$',
    ),
    CheckoutOrderItemModel(
      image: 'assets/image/Now Playing.png',
      title: 'X-Series Pro',
      tag: 'STUDIO GRADE',
      quantity: 1,
      price: '129.00',
      currency: r'$',
    ),
  ];

  final subTotal = '250.00';
  final shippingFee = '80.00';
  final total = '330.00';
  final currency = r'$';

  void selectPaymentMethod(int index) => selectedPaymentIndex.value = index;

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
    promoCodeController.dispose();
    super.onClose();
  }
}

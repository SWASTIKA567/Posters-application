import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartItem {
  final String imageUrl;
  final String size;
  final int quantity;
  final double totalPrice;
  final DateTime addedAt;

  CartItem({
    required this.imageUrl,
    required this.size,
    required this.quantity,
    required this.totalPrice,
    required this.addedAt,
  });
}

class UserAddress {
  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;

  UserAddress({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
  });

  String get fullAddress => '$addressLine, $city, $state - $pincode';
}

class CartController extends GetxController {
  static CartController get to => Get.find();

  final RxList<CartItem> items = <CartItem>[].obs;
  final Rx<UserAddress?> deliveryAddress = Rx<UserAddress?>(null);
  final RxBool isPlacingOrder = false.obs;

  static const double deliveryCharge = 49.0;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get grandTotal => items.isEmpty ? 0 : subtotal + deliveryCharge;

  void addItem(CartItem item) => items.add(item);

  void removeItem(int index) => items.removeAt(index);

  void setAddress(UserAddress address) => deliveryAddress.value = address;

  Future<void> placeOrder() async {
    if (items.isEmpty) return;
    if (deliveryAddress.value == null) {
      Get.snackbar(
        'Address Required',
        'Please add a delivery address first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    isPlacingOrder.value = true;
    try {
      final addr = deliveryAddress.value!;
      await FirebaseFirestore.instance.collection('orders').add({
        'items': items
            .map(
              (e) => {
                'imageUrl': e.imageUrl,
                'size': e.size,
                'quantity': e.quantity,
                'totalPrice': e.totalPrice,
              },
            )
            .toList(),
        'address': {
          'name': addr.name,
          'phone': addr.phone,
          'addressLine': addr.addressLine,
          'city': addr.city,
          'state': addr.state,
          'pincode': addr.pincode,
        },
        'subtotal': subtotal,
        'deliveryCharge': deliveryCharge,
        'grandTotal': grandTotal,
        'paymentMethod': 'Cash on Delivery',
        'status': 'placed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      items.clear();
      deliveryAddress.value = null;
      isPlacingOrder.value = false;

      Get.snackbar(
        '🎉 Order Placed!',
        'Your order has been placed successfully.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      isPlacingOrder.value = false;
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }
}

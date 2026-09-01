import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/email_service.dart';
import '../controller/notification_controller.dart';
import '../controller/profile_controller.dart';

class CartItem {
  final String? docId;
  final String imageUrl;
  final String size;
  final int quantity;
  final double totalPrice;
  final DateTime addedAt;

  CartItem({
    this.docId,
    required this.imageUrl,
    required this.size,
    required this.quantity,
    required this.totalPrice,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'imageUrl': imageUrl,
        'size': size,
        'quantity': quantity,
        'totalPrice': totalPrice,
      };

  factory CartItem.fromMap(String docId, Map<String, dynamic> map) => CartItem(
        docId: docId,
        imageUrl: map['imageUrl'] ?? '',
        size: map['size'] ?? 'A4',
        quantity: map['quantity'] ?? 1,
        totalPrice: (map['totalPrice'] ?? 0).toDouble(),
        addedAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );
}

class UserAddress {
  final String? id;
  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;

  UserAddress({
    this.id,
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
  });

  String get fullAddress => '$addressLine, $city, $state - $pincode';

  factory UserAddress.fromMap(String id, Map<String, dynamic> map) => UserAddress(
        id: id,
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        addressLine: map['addressLine'] ?? '',
        city: map['city'] ?? '',
        state: map['state'] ?? '',
        pincode: map['pincode'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
      };
}

class OrderController extends GetxController {
  static OrderController get to => Get.find();

  // ── Cart ──────────────────────────────────────────────────────────────────
  final RxList<CartItem> items = <CartItem>[].obs;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // ── Pricing ───────────────────────────────────────────────────────────────
  static const double deliveryCharge = 49.0;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get grandTotal => items.isEmpty ? 0.0 : subtotal + deliveryCharge;

  // ── Address ───────────────────────────────────────────────────────────────
  final Rx<UserAddress?> deliveryAddress = Rx<UserAddress?>(null);
  final RxList<UserAddress> savedAddresses = <UserAddress>[].obs;

  void setAddress(UserAddress address) => deliveryAddress.value = address;

  // ── Orders ────────────────────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;

  Future<void> fetchOrders() async {
    try {
      final res = await ApiService.get('/orders');
      if (res['success'] == true && res['orders'] != null) {
        orders.value = (res['orders'] as List).map((e) {
          final data = Map<String, dynamic>.from(e);
          data['orderId'] = e['_id'];
          return data;
        }).toList();
      }
    } catch (e) {
      debugPrint('fetchOrders error: $e');
    }
  }

  Future<void> fetchAddresses() async {
    try {
      final res = await ApiService.get('/addresses');
      if (res['success'] == true && res['addresses'] != null) {
        savedAddresses.value = (res['addresses'] as List)
            .map((d) => UserAddress.fromMap(d['_id'], Map<String, dynamic>.from(d)))
            .toList();

        if (deliveryAddress.value == null && savedAddresses.isNotEmpty) {
          deliveryAddress.value = savedAddresses.first;
        }
      }
    } catch (e) {
      debugPrint('fetchAddresses error: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchCart();
    fetchAddresses();
    fetchOrders();
  }

  // ── Fetch Cart via REST API ───────────────────────────────────────────────
  Future<void> fetchCart() async {
    try {
      final res = await ApiService.get('/cart');
      if (res['success'] == true && res['items'] != null) {
        items.value = (res['items'] as List)
            .map((d) => CartItem.fromMap(d['_id'], Map<String, dynamic>.from(d)))
            .toList();
      }
    } catch (e) {
      debugPrint('fetchCart error: $e');
    }
  }

  // ── Add Item ───────────────────────────────────────────────────────────────
  Future<void> addItem(CartItem item) async {
    final res = await ApiService.post('/cart', item.toMap());
    if (res['success'] == true && res['item'] != null) {
      final docId = res['item']['_id'];
      items.add(CartItem(
        docId: docId,
        imageUrl: item.imageUrl,
        size: item.size,
        quantity: item.quantity,
        totalPrice: item.totalPrice,
        addedAt: item.addedAt,
      ));
    }
  }

  // ── Remove Item ────────────────────────────────────────────────────────────
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    items.removeAt(index);
    if (item.docId != null) {
      try {
        await ApiService.delete('/cart/${item.docId}');
      } catch (e) {
        debugPrint('removeItem error: $e');
      }
    }
  }

  // ── Place Order ───────────────────────────────────────────────────────────
  final RxBool isPlacingOrder = false.obs;

  Future<bool> placeOrder({
    String paymentMethod = 'Cash on Delivery',
    String paymentStatus = 'Pay on Delivery',
  }) async {
    if (items.isEmpty) return false;

    if (deliveryAddress.value == null) {
      Get.snackbar(
        'Address Required',
        'Please add a delivery address first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return false;
    }

    isPlacingOrder.value = true;
    try {
      final addr = deliveryAddress.value!;
      final trackingCode = 'KCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final res = await ApiService.post('/orders', {
        'items': items.map((e) => e.toMap()).toList(),
        'deliveryAddress': addr.toMap(),
        'subtotal': subtotal,
        'deliveryCharge': deliveryCharge,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'trackingCode': trackingCode,
      });

      if (res['success'] == true) {
        _sendOrderNotifications(
          trackingCode: trackingCode,
          orderId: res['order']?['_id'] ?? 'ORD-1001',
          grandTotal: grandTotal,
          paymentMethod: paymentMethod,
          itemsList: items.map((e) => e.toMap()).toList(),
          recipientName: addr.name,
        );
        items.clear();
        deliveryAddress.value = null;
        isPlacingOrder.value = false;
        fetchOrders();
        return true;
      } else {
        isPlacingOrder.value = false;
        Get.snackbar('Error', res['message'] ?? 'Failed to place order.');
        return false;
      }
    } catch (e) {
      isPlacingOrder.value = false;
      // Fallback local placement if offline / demo mode
      final addr = deliveryAddress.value!;
      final trackingCode = 'KCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final itemsSnapshot = items.map((e) => e.toMap()).toList();
      orders.insert(0, {
        'orderId': orderId,
        'items': itemsSnapshot,
        'deliveryAddress': addr.toMap(),
        'subtotal': subtotal,
        'deliveryCharge': deliveryCharge,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'status': 'Pending',
        'trackingCode': trackingCode,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _sendOrderNotifications(
        trackingCode: trackingCode,
        orderId: orderId,
        grandTotal: grandTotal,
        paymentMethod: paymentMethod,
        itemsList: itemsSnapshot,
        recipientName: addr.name,
      );

      items.clear();
      deliveryAddress.value = null;
      return true;
    }
  }

  void _sendOrderNotifications({
    required String trackingCode,
    required String orderId,
    required double grandTotal,
    required String paymentMethod,
    required List<dynamic> itemsList,
    required String recipientName,
  }) {
    if (Get.isRegistered<NotificationController>()) {
      NotificationController.to.addNotification(
        title: '🎉 Order Placed #$trackingCode',
        body: 'Your Kechi poster print order is confirmed & receipt sent to your Gmail!',
        type: 'order',
      );
    }

    String userEmail = 'customer@gmail.com';
    if (Get.isRegistered<ProfileController>() && ProfileController.to.emailCtrl.text.isNotEmpty) {
      userEmail = ProfileController.to.emailCtrl.text.trim();
    }

    EmailService.sendOrderConfirmationEmail(
      userEmail: userEmail,
      userName: recipientName,
      orderId: orderId,
      trackingCode: trackingCode,
      totalAmount: grandTotal,
      paymentMethod: paymentMethod,
      items: itemsList,
    );
  }

  // ── Cancel Order (only if Pending) ────────────────────────────────────────
  Future<void> cancelOrder(String orderId) async {
    try {
      final res = await ApiService.patch('/orders/$orderId/cancel', {});
      if (res['success'] == true) {
        // Immediately update local list so UI reflects without extra fetch
        final idx = orders.indexWhere(
          (o) => (o['_id'] ?? o['orderId']).toString() == orderId,
        );
        if (idx != -1) {
          final updated = Map<String, dynamic>.from(orders[idx]);
          updated['status'] = 'Cancelled';
          orders[idx] = updated;
          orders.refresh();
        }
        Get.snackbar(
          '🚫 Order Cancelled',
          'Your order has been cancelled successfully.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Cannot Cancel',
          res['message'] ?? 'Only Pending orders can be cancelled.',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }
}


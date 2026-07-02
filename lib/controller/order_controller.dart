import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartItem {
  final String? docId; // Firestore doc ID (null for local-only items)
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

  Map<String, dynamic> toMap(String uid) => {
    'userId': uid,
    'imageUrl': imageUrl,
    'size': size,
    'quantity': quantity,
    'totalPrice': totalPrice,
    'addedAt': Timestamp.fromDate(addedAt),
    'status': 'in_cart',
  };

  factory CartItem.fromMap(String docId, Map<String, dynamic> map) => CartItem(
    docId: docId,
    imageUrl: map['imageUrl'] ?? '',
    size: map['size'] ?? 'A4',
    quantity: map['quantity'] ?? 1,
    totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Cart ──────────────────────────────────────────────────────────────────
  final RxList<CartItem> items = <CartItem>[].obs;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _cartRef =>
      _firestore.collection('users').doc(_uid).collection('cart');

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // ── Pricing ───────────────────────────────────────────────────────────────
  static const double deliveryCharge = 49.0;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get grandTotal => items.isEmpty ? 0.0 : subtotal + deliveryCharge;

  // ── Address ───────────────────────────────────────────────────────────────
  final Rx<UserAddress?> deliveryAddress = Rx<UserAddress?>(null);
  final RxList<UserAddress> savedAddresses = <UserAddress>[].obs;
  
  StreamSubscription? _addressesSubscription;
  StreamSubscription? _authSubscription;

  void setAddress(UserAddress address) => deliveryAddress.value = address;

  // ── Orders ────────────────────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  StreamSubscription? _ordersSubscription;

  void fetchOrders() {
    _ordersSubscription?.cancel();
    final uid = _uid;
    if (uid == null) {
      orders.clear();
      return;
    }
    _ordersSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      orders.value = snap.docs.map((d) {
        final data = d.data();
        data['orderId'] = d.id;
        return data;
      }).toList();
    }, onError: (e) {
      debugPrint('fetchOrders error: $e');
    });
  }

  void fetchAddresses() {
    _addressesSubscription?.cancel();
    final uid = _uid;
    if (uid == null) {
      savedAddresses.clear();
      return;
    }
    _addressesSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .listen((snap) {
      savedAddresses.value = snap.docs
          .map((d) => UserAddress.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      // Automatically select the first address if none is selected yet
      if (deliveryAddress.value == null && savedAddresses.isNotEmpty) {
        deliveryAddress.value = savedAddresses.first;
      } else if (deliveryAddress.value != null) {
        // If the selected address was updated/deleted, keep local deliveryAddress synced
        final index = savedAddresses.indexWhere((e) => e.id == deliveryAddress.value!.id);
        if (index != -1) {
          deliveryAddress.value = savedAddresses[index];
        } else {
          deliveryAddress.value = savedAddresses.isNotEmpty ? savedAddresses.first : null;
        }
      }
    });
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    if (_uid != null) {
      fetchCart();
      fetchAddresses();
      fetchOrders();
    }
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        fetchCart();
        fetchAddresses();
        fetchOrders();
      } else {
        items.clear();
        deliveryAddress.value = null;
        savedAddresses.clear();
        orders.clear();
        _addressesSubscription?.cancel();
        _ordersSubscription?.cancel();
      }
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _addressesSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.onClose();
  }

  // ── Fetch cart from Firestore ─────────────────────────────────────────────
  Future<void> fetchCart() async {
    if (_uid == null) return;
    try {
      final snap = await _cartRef.orderBy('addedAt', descending: false).get();
      items.value = snap.docs
          .map((d) => CartItem.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchCart error: $e');
    }
  }

  // ── Add item — saves to Firestore + local list ────────────────────────────
  Future<void> addItem(CartItem item) async {
    if (_uid == null) {
      items.add(item);
      return;
    }
    try {
      final doc = await _cartRef.add(item.toMap(_uid!));
      // Store with docId so we can delete it later
      items.add(
        CartItem(
          docId: doc.id,
          imageUrl: item.imageUrl,
          size: item.size,
          quantity: item.quantity,
          totalPrice: item.totalPrice,
          addedAt: item.addedAt,
        ),
      );
    } catch (e) {
      debugPrint('addItem error: $e');
      items.add(item); // still add locally so UI doesn't break
    }
  }

  // ── Remove item — deletes from Firestore + local list ────────────────────
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    items.removeAt(index);
    if (_uid != null && item.docId != null) {
      try {
        await _cartRef.doc(item.docId).delete();
      } catch (e) {
        debugPrint('removeItem error: $e');
      }
    }
  }

  // ── Clear entire cart from Firestore ─────────────────────────────────────
  Future<void> _clearCartInFirestore() async {
    if (_uid == null) return;
    try {
      final snap = await _cartRef.get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('clearCart error: $e');
    }
  }

  // ── Place Order ───────────────────────────────────────────────────────────
  final RxBool isPlacingOrder = false.obs;

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
      final uid = _uid!;

      // Save order to Firestore
      await _firestore.collection('users').doc(uid).collection('orders').add({
        'userId': uid,
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

      // Clear cart from Firestore + locally
      await _clearCartInFirestore();
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

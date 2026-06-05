import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart'; //

import '../controller/order_controller.dart';

class PosterSize {
  final String label; // "A3", "A4", "A5"
  final String dimensions; // "29.7 × 42 cm"
  final double price;

  const PosterSize({
    required this.label,
    required this.dimensions,
    required this.price,
  });
}

class UploadController extends GetxController {
  static UploadController get to => Get.find();
  final FirebaseAuth auth = FirebaseAuth.instance;

  // ── Image ──────────────────────────────────────────────────────────────────
  final Rx<File?> pickedImage = Rx<File?>(null);
  final RxString uploadedImageUrl = ''.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  // ── Size ──────────────────────────────────────────────────────────────────
  final List<PosterSize> sizes = const [
    PosterSize(label: 'A5', dimensions: '14.8 × 21 cm', price: 99),
    PosterSize(label: 'A4', dimensions: '21 × 29.7 cm', price: 149),
    PosterSize(label: 'A3', dimensions: '29.7 × 42 cm', price: 249),
  ];

  final RxInt selectedSizeIndex = 1.obs; // default A4

  PosterSize get selectedSize => sizes[selectedSizeIndex.value];

  // ── Quantity ───────────────────────────────────────────────────────────────
  final RxInt quantity = 1.obs;

  void increment() {
    if (quantity.value < 50) quantity.value++;
  }

  void decrement() {
    if (quantity.value > 1) quantity.value--;
  }

  // ── Computed ───────────────────────────────────────────────────────────────
  double get totalPrice => selectedSize.price * quantity.value;

  // ── State ──────────────────────────────────────────────────────────────────
  final RxBool isAddingToCart = false.obs;

  // ── Image Picker ───────────────────────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file != null) {
      pickedImage.value = File(file.path);
      uploadedImageUrl.value = ''; // reset previous upload
    }
  }

  // ── Firebase Upload ────────────────────────────────────────────────────────
  Future<String?> _uploadToStorage(File image) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0;
      final uid = auth.currentUser!.uid;

      final String fileName = '${const Uuid().v4()}.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'poster_uploads/$uid/$fileName',
      );

      final uploadTask = ref.putFile(image);

      uploadTask.snapshotEvents.listen((snap) {
        uploadProgress.value = snap.bytesTransferred / snap.totalBytes;
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      isUploading.value = false;
      return url;
    } catch (e) {
      isUploading.value = false;
      Get.snackbar(
        'Upload Failed',
        e.toString(),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // ── Add to Cart ────────────────────────────────────────────────────────────
  Future<void> addToCart() async {
    if (pickedImage.value == null) {
      Get.snackbar(
        'No Image',
        'Please upload a poster image first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    isAddingToCart.value = true;

    // 1. Upload image if not already uploaded
    if (uploadedImageUrl.value.isEmpty) {
      final url = await _uploadToStorage(pickedImage.value!);
      if (url == null) {
        isAddingToCart.value = false;
        return;
      }
      uploadedImageUrl.value = url;
    }

    // 2. Save order to Firestore
    try {
      final uid = auth.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart_orders')
          .add({
            'userId': uid,
            'imageUrl': uploadedImageUrl.value,
            'size': selectedSize.label,
            'dimensions': selectedSize.dimensions,
            'pricePerUnit': selectedSize.price,
            'quantity': quantity.value,
            'totalPrice': totalPrice,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'in_cart',
          });

      // 3. Update local cart
      OrderController.to.addItem(
        CartItem(
          imageUrl: uploadedImageUrl.value,
          size: selectedSize.label,
          quantity: quantity.value,
          totalPrice: totalPrice,
          addedAt: DateTime.now(),
        ),
      );

      isAddingToCart.value = false;

      // 4. Success feedback
      Get.snackbar(
        '🎉 Added to Cart!',
        '${quantity.value}× ${selectedSize.label} poster added.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Reset for next upload
      _reset();
    } catch (e) {
      isAddingToCart.value = false;
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  void _reset() {
    pickedImage.value = null;
    uploadedImageUrl.value = '';
    quantity.value = 1;
    selectedSizeIndex.value = 1;
    uploadProgress.value = 0;
  }
}

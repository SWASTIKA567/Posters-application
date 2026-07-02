import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/order_controller.dart';

class AddressController extends GetxController {
  static AddressController get to => Get.find();
  final FirebaseAuth auth = FirebaseAuth.instance;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    prefillFromProfile();
  }

  void prefillFromProfile() {
    final user = auth.currentUser;
    if (user != null && nameCtrl.text.isEmpty) {
      nameCtrl.text = user.displayName ?? '';
    }
  }

  void clearFields() {
    nameCtrl.clear();
    phoneCtrl.clear();
    addressCtrl.clear();
    cityCtrl.clear();
    stateCtrl.clear();
    pincodeCtrl.clear();
  }

  Future<void> saveAddress() async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) return;

    final uid = auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar(
        'Not Logged In',
        'Please log in to save an address.',
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }

    isSaving.value = true;

    try {

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .add({
            'userId': uid,
            'name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'addressLine': addressCtrl.text.trim(),
            'city': cityCtrl.text.trim(),
            'state': stateCtrl.text.trim(),
            'pincode': pincodeCtrl.text.trim(),
            'savedAt': FieldValue.serverTimestamp(),
          });

      final address = UserAddress(
        id: docRef.id,
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        addressLine: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        pincode: pincodeCtrl.text.trim(),
      );

      OrderController.to.setAddress(address);
      isSaving.value = false;

      clearFields();

      Get.back(); // back to SelectAddressView

      Get.snackbar(
        '✅ Address Saved',
        'Your delivery address has been added.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
    } catch (e) {
      isSaving.value = false;
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(id)
          .delete();
      
      // If the deleted address is the currently selected one, update it
      if (OrderController.to.deliveryAddress.value?.id == id) {
        final remaining = OrderController.to.savedAddresses;
        if (remaining.isNotEmpty) {
          // Note: remaining might still contain the deleted one if stream hasn't fired yet.
          // So we find the first one that is NOT the deleted ID.
          final nextSelectable = remaining.firstWhereOrNull((e) => e.id != id);
          OrderController.to.deliveryAddress.value = nextSelectable;
        } else {
          OrderController.to.deliveryAddress.value = null;
        }
      }
      
      Get.snackbar(
        'Address Deleted',
        'Your address has been deleted.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
    super.onClose();
  }
}

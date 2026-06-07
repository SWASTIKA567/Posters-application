import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart';
import '../controller/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> saveAddress() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;

    final address = UserAddress(
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      addressLine: addressCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      state: stateCtrl.text.trim(),
      pincode: pincodeCtrl.text.trim(),
    );

    try {
      final uid = auth.currentUser!.uid; //

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .add({
            'userId': uid,
            'name': address.name,
            'phone': address.phone,
            'addressLine': address.addressLine,
            'city': address.city,
            'state': address.state,
            'pincode': address.pincode,
            'savedAt': FieldValue.serverTimestamp(),
          });

      OrderController.to.setAddress(address);
      isSaving.value = false;

      Get.back(); // back to cart

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

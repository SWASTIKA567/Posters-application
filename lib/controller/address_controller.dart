import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../controller/order_controller.dart';
import '../controller/profile_controller.dart';

class AddressController extends GetxController {
  static AddressController get to => Get.find();

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
    if (Get.isRegistered<ProfileController>()) {
      final profile = ProfileController.to;
      if (nameCtrl.text.isEmpty && profile.nameCtrl.text.isNotEmpty) {
        nameCtrl.text = profile.nameCtrl.text;
      }
      if (phoneCtrl.text.isEmpty && profile.phoneCtrl.text.isNotEmpty) {
        phoneCtrl.text = profile.phoneCtrl.text;
      }
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

    isSaving.value = true;

    try {
      final res = await ApiService.post('/addresses', {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'addressLine': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
        'pincode': pincodeCtrl.text.trim(),
      });

      if (res['success'] == true && res['address'] != null) {
        final data = res['address'];
        final address = UserAddress(
          id: data['_id'],
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          addressLine: data['addressLine'] ?? '',
          city: data['city'] ?? '',
          state: data['state'] ?? '',
          pincode: data['pincode'] ?? '',
        );

        OrderController.to.setAddress(address);
        OrderController.to.fetchAddresses();
        
        if (phoneCtrl.text.trim().isNotEmpty) {
          try {
            await ApiService.put('/users/profile', {
              'phone': phoneCtrl.text.trim(),
            });
          } catch (_) {}
        }
        if (Get.isRegistered<ProfileController>()) {
          ProfileController.to.loadProfile();
        }

        isSaving.value = false;

        clearFields();
        Get.back();

        Get.snackbar(
          '✅ Address Saved',
          'Your delivery address has been added.',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      } else {
        isSaving.value = false;
        Get.snackbar('Error', res['message'] ?? 'Failed to save address.');
      }
    } catch (e) {
      isSaving.value = false;
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await ApiService.delete('/addresses/$id');
      OrderController.to.fetchAddresses();

      if (OrderController.to.deliveryAddress.value?.id == id) {
        OrderController.to.deliveryAddress.value = null;
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
        e.toString().replaceAll('Exception: ', ''),
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

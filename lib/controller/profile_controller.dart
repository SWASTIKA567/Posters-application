import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isEditMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final res = await ApiService.get('/users/profile');
      if (res['success'] == true && res['user'] != null) {
        final user = res['user'];
        nameCtrl.text = user['name'] ?? '';
        emailCtrl.text = user['email'] ?? '';
        phoneCtrl.text = user['phone'] ?? '';
      }

      final addrRes = await ApiService.get('/addresses');
      if (addrRes['success'] == true &&
          addrRes['addresses'] != null &&
          (addrRes['addresses'] as List).isNotEmpty) {
        final data = addrRes['addresses'][0];
        addressCtrl.text = data['addressLine'] ?? '';
        cityCtrl.text = data['city'] ?? '';
        stateCtrl.text = data['state'] ?? '';
        pincodeCtrl.text = data['pincode'] ?? '';
      }
    } catch (e) {
      debugPrint('loadProfile error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEditMode() => isEditMode.value = !isEditMode.value;

  Future<void> saveProfile() async {
    isSaving.value = true;
    try {
      await ApiService.put('/users/profile', {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
      });

      if (addressCtrl.text.trim().isNotEmpty) {
        await ApiService.post('/addresses', {
          'name': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'addressLine': addressCtrl.text.trim(),
          'city': cityCtrl.text.trim(),
          'state': stateCtrl.text.trim(),
          'pincode': pincodeCtrl.text.trim(),
        });
      }

      isEditMode.value = false;

      Get.snackbar(
        '✅ Profile Updated',
        'Your profile has been saved.',
        backgroundColor: const Color(0xFF00796B),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
    super.onClose();
  }
}

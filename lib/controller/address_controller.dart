import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../controller/order_controller.dart';
import '../controller/profile_controller.dart';
import '../utils/ncr_helper.dart';

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
  final RxBool isLoadingPincode = false.obs;
  final Rx<bool?> isDeliverableInNcr = Rx<bool?>(null);
  final RxString pincodeFeedback = ''.obs;

  String _lastFetchedPincode = '';

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
    isDeliverableInNcr.value = null;
    pincodeFeedback.value = '';
    _lastFetchedPincode = '';
  }

  /// Automatically fetch District & State when user inputs 6-digit Pincode
  Future<void> onPincodeChanged(String value) async {
    final pincode = value.trim();

    if (pincode.length < 6) {
      if (isDeliverableInNcr.value != null) {
        isDeliverableInNcr.value = null;
        pincodeFeedback.value = '';
      }
      return;
    }

    if (pincode.length == 6 && pincode != _lastFetchedPincode) {
      _lastFetchedPincode = pincode;
      await fetchLocationByPincode(pincode);
    }
  }

  Future<void> fetchLocationByPincode(String pincode) async {
    isLoadingPincode.value = true;
    pincodeFeedback.value = 'Locating area...';

    try {
      final url = Uri.parse('https://api.postalpincode.in/pincode/$pincode');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List<dynamic>?;
          if (postOffices != null && postOffices.isNotEmpty) {
            final po = postOffices[0];
            final district = po['District']?.toString().trim() ?? '';
            final state = po['State']?.toString().trim() ?? '';

            cityCtrl.text = district;
            stateCtrl.text = state;

            final isNcr = isNcrRegion(
              state: state,
              district: district,
              pincode: pincode,
            );

            if (isNcr) {
              isDeliverableInNcr.value = true;
              pincodeFeedback.value = 'Delivering to $district, NCR';

              Get.snackbar(
                ' NCR Delivery Available',
                'We deliver across $district ($state)!',
                backgroundColor: const Color(0xFF10B981),
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                borderRadius: 14,
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
              );
            } else {
              isDeliverableInNcr.value = false;
              pincodeFeedback.value = 'Delivery coming soon to $district';

              Get.snackbar(
                '🚀 Delivery Coming Soon!',
                'We currently deliver exclusively in Delhi-NCR. Coming soon to $district!',
                backgroundColor: const Color(0xFF8B0000),
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                borderRadius: 14,
                icon: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                ),
              );
            }
            return;
          }
        }
      }

      isDeliverableInNcr.value = false;
      pincodeFeedback.value = 'Pincode not found';
      Get.snackbar(
        'Invalid Pincode',
        'Could not find location for PIN code $pincode. Please check your pincode.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    } catch (e) {
      debugPrint('Error fetching pincode: $e');
      pincodeFeedback.value = 'Could not verify location';
    } finally {
      isLoadingPincode.value = false;
    }
  }

  Future<void> saveAddress() async {
    if (formKey.currentState == null || !formKey.currentState!.validate())
      return;

    final pincode = pincodeCtrl.text.trim();
    final district = cityCtrl.text.trim();
    final state = stateCtrl.text.trim();

    final isNcr = isNcrRegion(
      state: state,
      district: district,
      pincode: pincode,
    );

    if (!isNcr) {
      Get.snackbar(
        '🚀 Delivery Coming Soon!',
        'We currently deliver only across the whole region of Delhi-NCR. Service is coming soon to your location!',
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.access_time_rounded, color: Colors.white),
      );
      return;
    }

    isSaving.value = true;

    try {
      final res = await ApiService.post('/addresses', {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'addressLine': addressCtrl.text.trim(),
        'city': district,
        'state': state,
        'pincode': pincode,
        'isDefault': true,
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
          isDefault: data['isDefault'] ?? true,
        );

        await OrderController.to.setAddress(address);
        await OrderController.to.fetchAddresses();

        if (phoneCtrl.text.trim().isNotEmpty) {
          try {
            await ApiService.put('/users/profile', {
              'phone': phoneCtrl.text.trim(),
            });
          } catch (_) {}
        }
        if (Get.isRegistered<ProfileController>()) {
          ProfileController.to.setSelectedAddress(address);
          ProfileController.to.loadProfile();
        }

        isSaving.value = false;

        clearFields();
        Get.back();

        Get.snackbar(
          '✅ Address Saved',
          'Your NCR delivery address has been added.',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
        );
      } else {
        isSaving.value = false;
        Get.snackbar(
          'Notice',
          ApiService.cleanErrorMessage(
            res['message'],
            defaultMessage: 'Failed to save address.',
          ),
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isSaving.value = false;
      Get.snackbar(
        'Notice',
        ApiService.cleanErrorMessage(e),
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
        'Notice',
        ApiService.cleanErrorMessage(e),
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

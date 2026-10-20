import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../views/login_view.dart';
import '../controller/order_controller.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  final Rx<UserAddress?> selectedAddress = Rx<UserAddress?>(null);

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isDeleting = false.obs;
  final isEditMode = false.obs;
  final isAdminUser = false.obs;
  final isAdminUnlocked = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> checkAdminStatus() async {
    try {
      final res = await ApiService.get('/auth/check-admin-status');
      if (res != null && res['isAdminEmail'] == true) {
        isAdminUser.value = true;
      } else {
        isAdminUser.value = false;
      }
    } catch (_) {
      isAdminUser.value = false;
    }
  }

  Future<bool> verifyAdminPassword(String email, String password) async {
    try {
      final res = await ApiService.post('/auth/verify-admin', {
        'email': email.trim(),
        'password': password.trim(),
      });
      if (res != null && res['isAdmin'] == true) {
        isAdminUnlocked.value = true;
        isAdminUser.value = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Admin verify error: $e');
      return false;
    }
  }

  void setSelectedAddress(UserAddress address) {
    selectedAddress.value = address;
    addressCtrl.text = address.addressLine;
    cityCtrl.text = address.city;
    stateCtrl.text = address.state;
    pincodeCtrl.text = address.pincode;
  }

  void clearSelectedAddress() {
    selectedAddress.value = null;
    addressCtrl.clear();
    cityCtrl.clear();
    stateCtrl.clear();
    pincodeCtrl.clear();
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
        // Check if user is configured as admin on backend
        await checkAdminStatus();
      }

      final addrRes = await ApiService.get('/addresses');
      if (addrRes['success'] == true &&
          addrRes['addresses'] != null &&
          (addrRes['addresses'] as List).isNotEmpty) {
        final list = (addrRes['addresses'] as List)
            .map((d) => UserAddress.fromMap(d['_id'], Map<String, dynamic>.from(d)))
            .toList();

        // Pick default address or first one
        final chosen = list.firstWhereOrNull((a) => a.isDefault) ?? list.first;
        setSelectedAddress(chosen);

        if (Get.isRegistered<OrderController>()) {
          OrderController.to.savedAddresses.value = list;
          if (OrderController.to.deliveryAddress.value == null) {
            OrderController.to.deliveryAddress.value = chosen;
          }
        }
      } else {
        clearSelectedAddress();
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
        if (selectedAddress.value?.id != null) {
          // Update existing selected address
          await ApiService.put('/addresses/${selectedAddress.value!.id}', {
            'name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'addressLine': addressCtrl.text.trim(),
            'city': cityCtrl.text.trim(),
            'state': stateCtrl.text.trim(),
            'pincode': pincodeCtrl.text.trim(),
          });
        } else {
          // Create new address
          final addrRes = await ApiService.post('/addresses', {
            'name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'addressLine': addressCtrl.text.trim(),
            'city': cityCtrl.text.trim(),
            'state': stateCtrl.text.trim(),
            'pincode': pincodeCtrl.text.trim(),
            'isDefault': true,
          });
          if (addrRes['success'] == true && addrRes['address'] != null) {
            final d = addrRes['address'];
            final newAddr = UserAddress.fromMap(d['_id'], Map<String, dynamic>.from(d));
            setSelectedAddress(newAddr);
          }
        }
        if (Get.isRegistered<OrderController>()) {
          OrderController.to.fetchAddresses();
        }
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
        'Notice',
        ApiService.cleanErrorMessage(e),
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ── Delete Account (Google Play Policy Requirement) ─────────────────────────
  Future<void> deleteAccount() async {
    isDeleting.value = true;
    try {
      final res = await ApiService.delete('/users/account');
      if (res['success'] == true) {
        await ApiService.setAuthToken(null);
        isDeleting.value = false;
        Get.offAll(() => const LoginScreen());
        Get.snackbar(
          'Account Deleted',
          'Your account and all associated data have been permanently removed.',
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
        );
      } else {
        isDeleting.value = false;
        Get.snackbar(
          'Notice',
          ApiService.cleanErrorMessage(res['message'], defaultMessage: 'Failed to delete account.'),
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isDeleting.value = false;
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
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
    super.onClose();
  }
}

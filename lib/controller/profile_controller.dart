import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  User? get currentUser => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      nameCtrl.text = currentUser?.displayName ?? '';
      emailCtrl.text = currentUser?.email ?? '';

      final addressSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .orderBy('savedAt', descending: true)
          .limit(1)
          .get();

      if (addressSnap.docs.isNotEmpty) {
        final data = addressSnap.docs.first.data();
        phoneCtrl.text = data['phone'] ?? '';
        addressCtrl.text = data['addressLine'] ?? '';
        cityCtrl.text = data['city'] ?? '';
        stateCtrl.text = data['state'] ?? '';
        pincodeCtrl.text = data['pincode'] ?? '';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEditMode() => isEditMode.value = !isEditMode.value;

  Future<void> saveProfile() async {
    isSaving.value = true;
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      // Update display name in Firebase Auth
      await currentUser?.updateDisplayName(nameCtrl.text.trim());

      // Update/create address doc
      final addressSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .orderBy('savedAt', descending: true)
          .limit(1)
          .get();

      final addressData = {
        'userId': uid,
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'addressLine': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
        'pincode': pincodeCtrl.text.trim(),
        'savedAt': FieldValue.serverTimestamp(),
      };

      if (addressSnap.docs.isNotEmpty) {
        await addressSnap.docs.first.reference.update(addressData);
      } else {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('addresses')
            .add(addressData);
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
        e.toString(),
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

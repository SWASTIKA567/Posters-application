import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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

  // ── Map & Geolocation State ────────────────────────────────────────────────
  final mapController = MapController();
  final Rx<LatLng> selectedLocation = const LatLng(28.6139, 77.2090).obs; // New Delhi Connaught Place
  final RxBool isDetectingLocation = false.obs;
  final RxBool isReverseGeocoding = false.obs;
  final RxBool showMap = true.obs;

  // ── Phone OTP Verification State ───────────────────────────────────────────
  final RxBool isPhoneVerified = false.obs;
  final RxBool isSendingPhoneOtp = false.obs;
  final RxBool isVerifyingPhoneOtp = false.obs;
  final RxBool isOtpSent = false.obs;
  final RxString phoneVerificationError = ''.obs;
  final RxInt otpCountdown = 30.obs;
  final RxBool canResendOtp = false.obs;
  final otpController = TextEditingController();

  String? _verificationId;
  int? _resendToken;
  Timer? _countdownTimer;
  String _verifiedPhoneDigits = '';

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

  @override
  void onClose() {
    _countdownTimer?.cancel();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
    otpController.dispose();
    super.onClose();
  }

  Future<void> getCurrentLocation() async {
    isDetectingLocation.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services Disabled',
          'Please turn on GPS / Location on your device.',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        isDetectingLocation.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required to detect your location automatically.',
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
          );
          isDetectingLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Blocked',
          'Please enable location in App Settings or enter address manually.',
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
        );
        isDetectingLocation.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      final targetLatLng = LatLng(position.latitude, position.longitude);
      selectedLocation.value = targetLatLng;

      try {
        mapController.move(targetLatLng, 15.5);
      } catch (_) {}

      await reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      Get.snackbar(
        'Location Notice',
        'Could not detect GPS. You can tap on the map or type address manually.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } finally {
      isDetectingLocation.value = false;
    }
  }

  Future<void> reverseGeocode(double lat, double lng) async {
    isReverseGeocoding.value = true;
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'KechiPosterApp/1.0 (com.kechi.poster)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final postcode = (address['postcode'] ?? '').toString().trim();
          final state = (address['state'] ?? '').toString().trim();
          final district = (address['state_district'] ??
                  address['city'] ??
                  address['county'] ??
                  address['district'] ??
                  '')
              .toString()
              .trim();

          // Build road / street string
          final streetParts = [
            address['house_number'],
            address['building'],
            address['road'],
            address['neighbourhood'] ?? address['suburb'],
          ].where((part) => part != null && part.toString().trim().isNotEmpty).toList();

          final streetLine = streetParts.isNotEmpty
              ? streetParts.join(', ')
              : (data['display_name'] ?? '');

          if (streetLine.isNotEmpty) {
            addressCtrl.text = streetLine;
          }
          if (district.isNotEmpty) {
            cityCtrl.text = district;
          }
          if (state.isNotEmpty) {
            stateCtrl.text = state;
          }
          if (postcode.isNotEmpty && RegExp(r'^\d{6}$').hasMatch(postcode)) {
            pincodeCtrl.text = postcode;
          }

          // Check NCR Region validity
          final isNcr = isNcrRegion(
            state: stateCtrl.text.trim(),
            district: cityCtrl.text.trim(),
            pincode: pincodeCtrl.text.trim(),
          );

          if (isNcr) {
            isDeliverableInNcr.value = true;
            pincodeFeedback.value = 'Delivering to ${cityCtrl.text.trim()}, NCR';
            Get.snackbar(
              '📍 Address Auto-Detected',
              'Delivering across ${cityCtrl.text.trim()} (Delhi-NCR)! You can adjust any field manually.',
              backgroundColor: const Color(0xFF10B981),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
              borderRadius: 14,
            );
          } else {
            isDeliverableInNcr.value = false;
            pincodeFeedback.value = 'Delivery currently limited to Delhi-NCR';
            Get.snackbar(
              'Outside Delhi-NCR',
              'Detected location is outside Delhi-NCR. We currently deliver only across Delhi-NCR.',
              backgroundColor: const Color(0xFF8B0000),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
              borderRadius: 14,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    } finally {
      isReverseGeocoding.value = false;
    }
  }

  void onMapTapped(LatLng position) {
    selectedLocation.value = position;
    try {
      mapController.move(position, mapController.camera.zoom);
    } catch (_) {}
    reverseGeocode(position.latitude, position.longitude);
  }

  void onPhoneChanged(String val) {
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits != _verifiedPhoneDigits) {
      isPhoneVerified.value = false;
      isOtpSent.value = false;
      phoneVerificationError.value = '';
    }
  }

  void _startOtpTimer() {
    _countdownTimer?.cancel();
    otpCountdown.value = 30;
    canResendOtp.value = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpCountdown.value > 1) {
        otpCountdown.value--;
      } else {
        _countdownTimer?.cancel();
        otpCountdown.value = 0;
        canResendOtp.value = true;
      }
    });
  }

  Future<void> sendPhoneOtp() async {
    final digits = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      phoneVerificationError.value = 'Please enter a valid 10-digit mobile number';
      return;
    }

    isSendingPhoneOtp.value = true;
    phoneVerificationError.value = '';

    try {
      final fullPhoneNumber = '+91$digits';
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Auto-verification completed via Play Services');
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } catch (_) {}
          isPhoneVerified.value = true;
          _verifiedPhoneDigits = digits;
          isOtpSent.value = false;
          phoneVerificationError.value = '';
          Get.snackbar(
            '🎉 Mobile Verified',
            'Phone number +91 $digits verified successfully!',
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.code} - ${e.message}');
          isSendingPhoneOtp.value = false;
          if (e.code == 'invalid-phone-number') {
            phoneVerificationError.value = 'Invalid phone number format.';
          } else if (e.code == 'too-many-requests') {
            phoneVerificationError.value = 'Too many requests. Please wait before retrying.';
          } else {
            phoneVerificationError.value = e.message ?? 'Failed to send SMS code. Check your network.';
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📩 SMS OTP code sent to $fullPhoneNumber');
          _verificationId = verificationId;
          _resendToken = resendToken;
          isSendingPhoneOtp.value = false;
          isOtpSent.value = true;
          otpController.clear();
          _startOtpTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      isSendingPhoneOtp.value = false;
      phoneVerificationError.value = 'Could not send verification code: $e';
    }
  }

  Future<void> verifyPhoneOtp() async {
    final code = otpController.text.trim();
    if (code.length != 6) {
      phoneVerificationError.value = 'Please enter the complete 6-digit OTP';
      return;
    }

    if (_verificationId == null) {
      phoneVerificationError.value = 'Session expired. Please request a new OTP.';
      return;
    }

    isVerifyingPhoneOtp.value = true;
    phoneVerificationError.value = '';

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      final digits = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      isPhoneVerified.value = true;
      _verifiedPhoneDigits = digits;
      isOtpSent.value = false;
      isVerifyingPhoneOtp.value = false;
      phoneVerificationError.value = '';

      Get.snackbar(
        '🎉 Mobile Verified',
        'Phone number +91 $digits verified successfully!',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } on FirebaseAuthException catch (e) {
      isVerifyingPhoneOtp.value = false;
      if (e.code == 'invalid-verification-code') {
        phoneVerificationError.value = 'Incorrect OTP code. Please check and retry.';
      } else if (e.code == 'session-expired') {
        phoneVerificationError.value = 'OTP expired. Please tap "Resend Code".';
      } else {
        phoneVerificationError.value = e.message ?? 'Verification failed.';
      }
    } catch (e) {
      isVerifyingPhoneOtp.value = false;
      phoneVerificationError.value = 'Verification error: $e';
    }
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
    otpController.clear();
    isPhoneVerified.value = false;
    isOtpSent.value = false;
    phoneVerificationError.value = '';
    _verifiedPhoneDigits = '';
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
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    // Ensure phone number has been verified via SMS OTP before saving address
    if (!isPhoneVerified.value) {
      Get.snackbar(
        'Phone Verification Required',
        'Please verify your 10-digit mobile number with OTP before saving address.',
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.shield_outlined, color: Colors.white),
      );
      return;
    }

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
}

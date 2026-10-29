import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
  final confirmPhoneCtrl = TextEditingController();
  final houseNoCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  // ── Map & Geolocation State ────────────────────────────────────────────────
  final mapController = MapController();
  final Rx<LatLng> selectedLocation = const LatLng(28.6139, 77.2090).obs; // New Delhi Connaught Place
  final RxBool isDetectingLocation = false.obs;
  final RxBool isReverseGeocoding = false.obs;
  final RxBool isGeocodingAddress = false.obs;
  final RxString mapVerificationStatus = ''.obs;
  final RxBool showMap = true.obs;
  Timer? _addressDebounce;

  // ── Phone Double-Entry Confirmation State ─────────────────────────────────
  final RxBool doPhonesMatch = false.obs;

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
    _addressDebounce?.cancel();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    confirmPhoneCtrl.dispose();
    houseNoCtrl.dispose();
    streetCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
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

          // Extract house/building and road/street parts
          final houseParts = [
            address['house_number'],
            address['building'],
          ].where((part) => part != null && part.toString().trim().isNotEmpty).toList();

          final roadParts = [
            address['road'],
            address['neighbourhood'] ?? address['suburb'],
          ].where((part) => part != null && part.toString().trim().isNotEmpty).toList();

          if (houseParts.isNotEmpty) {
            houseNoCtrl.text = houseParts.join(', ');
          }
          if (roadParts.isNotEmpty) {
            streetCtrl.text = roadParts.join(', ');
          } else if (data['display_name'] != null && streetCtrl.text.isEmpty) {
            streetCtrl.text = data['display_name'];
          }

          final streetLine = [houseNoCtrl.text, streetCtrl.text]
              .where((p) => p.trim().isNotEmpty)
              .join(', ');
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

  void onAddressFieldChanged(String val) {
    _addressDebounce?.cancel();
    if (val.trim().length >= 4) {
      _addressDebounce = Timer(const Duration(milliseconds: 1400), () {
        locateAddressOnMap(showNotification: false);
      });
    }
  }

  Future<void> locateAddressOnMap({bool showNotification = false}) async {
    final street = streetCtrl.text.trim();
    final house = houseNoCtrl.text.trim();
    final city = cityCtrl.text.trim();
    final state = stateCtrl.text.trim();
    final pincode = pincodeCtrl.text.trim();

    final queryParts = [house, street, city, state, pincode, 'India']
        .where((p) => p.isNotEmpty)
        .toList();

    if (queryParts.length <= 1) {
      if (showNotification) {
        Get.snackbar(
          'Address Info Needed',
          'Please enter Street / Area or PIN code to locate on map.',
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
        );
      }
      return;
    }

    isGeocodingAddress.value = true;
    mapVerificationStatus.value = 'Locating on map...';

    try {
      final query = queryParts.join(', ');
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'KechiPosterApp/1.0 (com.kechi.poster)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final first = results[0];
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');

          if (lat != null && lon != null) {
            final target = LatLng(lat, lon);
            selectedLocation.value = target;
            try {
              mapController.move(target, 16.0);
            } catch (_) {}

            mapVerificationStatus.value = '📍 Address verified & pinned on map';
            if (showNotification) {
              Get.snackbar(
                '📍 Map Pin Updated',
                'Located address on map: ${first['display_name'] ?? ''}',
                backgroundColor: const Color(0xFF10B981),
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                borderRadius: 14,
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              );
            }
            return;
          }
        }
      }

      // Secondary search if full address didn't pinpoint:
      if (pincode.isNotEmpty || city.isNotEmpty) {
        final fallbackQuery = [street, city, pincode, 'NCR, India']
            .where((p) => p.isNotEmpty)
            .join(', ');
        final fbUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(fallbackQuery)}&format=json&limit=1',
        );
        final fbRes = await http.get(
          fbUrl,
          headers: {'User-Agent': 'KechiPosterApp/1.0 (com.kechi.poster)'},
        ).timeout(const Duration(seconds: 6));

        if (fbRes.statusCode == 200) {
          final List<dynamic> fbList = jsonDecode(fbRes.body);
          if (fbList.isNotEmpty) {
            final lat = double.tryParse(fbList[0]['lat']?.toString() ?? '');
            final lon = double.tryParse(fbList[0]['lon']?.toString() ?? '');
            if (lat != null && lon != null) {
              final target = LatLng(lat, lon);
              selectedLocation.value = target;
              try {
                mapController.move(target, 15.0);
              } catch (_) {}
              mapVerificationStatus.value = '📍 Area located on map';
              return;
            }
          }
        }
      }

      mapVerificationStatus.value = 'Could not pinpoint exact address on map';
    } catch (e) {
      debugPrint('Locate address error: $e');
      mapVerificationStatus.value = '';
    } finally {
      isGeocodingAddress.value = false;
    }
  }

  void onPhoneChanged(String val) {
    _checkPhonesMatch();
  }

  void onConfirmPhoneChanged(String val) {
    _checkPhonesMatch();
  }

  void _checkPhonesMatch() {
    final p1 = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final p2 = confirmPhoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    doPhonesMatch.value = (p1.length == 10 && p2.length == 10 && p1 == p2);
  }

  void prefillFromProfile() {
    if (Get.isRegistered<ProfileController>()) {
      final profile = ProfileController.to;
      if (nameCtrl.text.isEmpty && profile.nameCtrl.text.isNotEmpty) {
        nameCtrl.text = profile.nameCtrl.text;
      }
      if (phoneCtrl.text.isEmpty && profile.phoneCtrl.text.isNotEmpty) {
        phoneCtrl.text = profile.phoneCtrl.text;
        confirmPhoneCtrl.text = profile.phoneCtrl.text;
        _checkPhonesMatch();
      }
    }
  }

  void clearFields() {
    _addressDebounce?.cancel();
    nameCtrl.clear();
    phoneCtrl.clear();
    confirmPhoneCtrl.clear();
    doPhonesMatch.value = false;
    houseNoCtrl.clear();
    streetCtrl.clear();
    addressCtrl.clear();
    cityCtrl.clear();
    stateCtrl.clear();
    pincodeCtrl.clear();
    mapVerificationStatus.value = '';
    isGeocodingAddress.value = false;
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

    final p1 = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final p2 = confirmPhoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (p1.length != 10) {
      Get.snackbar(
        'Invalid Phone Number',
        'Please enter a valid 10-digit mobile number.',
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.phone_android_rounded, color: Colors.white),
      );
      return;
    }

    if (p1 != p2) {
      Get.snackbar(
        'Phone Numbers Do Not Match',
        'Please make sure the phone number and confirm phone number match exactly.',
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
      );
      return;
    }

    final houseNo = houseNoCtrl.text.trim();
    final street = streetCtrl.text.trim();

    if (houseNo.isEmpty) {
      Get.snackbar(
        'House/Flat Required',
        'Please enter your Flat, House No., or Building name.',
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.apartment_rounded, color: Colors.white),
      );
      return;
    }

    if (street.isEmpty) {
      Get.snackbar(
        'Street / Area Required',
        'Please enter your Street, Road, or Area name.',
        backgroundColor: const Color(0xFF8B0000),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.add_road_rounded, color: Colors.white),
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

    final combinedAddress = '$houseNo, $street';
    addressCtrl.text = combinedAddress;

    isSaving.value = true;

    try {
      final res = await ApiService.post('/addresses', {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'addressLine': combinedAddress,
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  static NavigationController get to => Get.isRegistered<NavigationController>()
      ? Get.find<NavigationController>()
      : Get.put(NavigationController(), permanent: true);

  final RxInt selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void goToHome() {
    selectedIndex.value = 0;
  }

  void handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      goToHome();
    }
  }
}

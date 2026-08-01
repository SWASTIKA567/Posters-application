import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../model/wishlist_model.dart';

class WishlistController extends GetxController {
  static WishlistController get to => Get.find();

  RxList<WishlistItem> wishlist = <WishlistItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchWishlist();
  }

  Future<void> addToWishlist({
    required String title,
    required String image,
  }) async {
    final alreadyAdded = wishlist.any((item) => item.title == title);
    if (alreadyAdded) return;

    try {
      await ApiService.post('/wishlist/toggle', {
        'title': title,
        'image': image,
      });
      await fetchWishlist();
    } catch (e) {
      debugPrint('addToWishlist error: $e');
    }
  }

  Future<void> fetchWishlist() async {
    try {
      final res = await ApiService.get('/wishlist');
      if (res['success'] == true && res['wishlist'] != null) {
        wishlist.value = (res['wishlist'] as List)
            .map((doc) => WishlistItem.fromMap(doc['_id'], Map<String, dynamic>.from(doc)))
            .toList();
      }
    } catch (e) {
      debugPrint('fetchWishlist error: $e');
    }
  }

  bool isWishlisted(String title) {
    return wishlist.any((item) => item.title == title);
  }

  Future<void> removeWishlist(String docId) async {
    try {
      await ApiService.delete('/wishlist/$docId');
      await fetchWishlist();
    } catch (e) {
      debugPrint('removeWishlist error: $e');
    }
  }
}

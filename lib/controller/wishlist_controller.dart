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

    // ✅ Optimistic update — add instantly to UI (no waiting for API)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempItem = WishlistItem(
      docId: tempId,
      title: title,
      image: image,
    );
    wishlist.add(tempItem);

    // Sync with backend in background
    try {
      await ApiService.post('/wishlist/toggle', {
        'title': title,
        'image': image,
      });
      // Refresh to get real docId from server
      await fetchWishlist();
    } catch (e) {
      // Revert optimistic update on failure
      wishlist.removeWhere((item) => item.id == tempItem.id);
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
    // ✅ Optimistic update — remove instantly from UI
    final removed = wishlist.firstWhereOrNull((item) => item.id == docId);
    wishlist.removeWhere((item) => item.id == docId);

    try {
      await ApiService.delete('/wishlist/$docId');
    } catch (e) {
      // Revert — add back if delete failed
      if (removed != null) wishlist.add(removed);
      debugPrint('removeWishlist error: $e');
    }
  }
}

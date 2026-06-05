// TODO Implement this library.
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/wishlist_model.dart';

class WishlistController extends GetxController {
  static WishlistController get to => Get.find();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  RxList<WishlistItem> wishlist = <WishlistItem>[].obs;

  CollectionReference get _collection => firestore
      .collection('users')
      .doc(auth.currentUser!.uid)
      .collection('wishlist');

  @override
  void onInit() {
    super.onInit();
    if (auth.currentUser != null) {
      fetchWishlist();
    }
  }

  Future<void> addToWishlist({
    required String title,
    required String image,
  }) async {
    final alreadyAdded = wishlist.any((item) => item.title == title);
    if (alreadyAdded) return;

    await _collection.add({
      'title': title,
      'image': image,
      'createdAt': Timestamp.now(),
    });

    await fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .get();

    wishlist.value = snapshot.docs
        .map(
          (doc) =>
              WishlistItem.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  bool isWishlisted(String title) {
    return wishlist.any((item) => item.title == title);
  }

  Future<void> removeWishlist(String docId) async {
    await _collection.doc(docId).delete();
    await fetchWishlist();
  }
}

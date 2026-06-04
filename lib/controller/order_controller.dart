import 'package:get/get.dart';

class CartItem {
  final String imageUrl;
  final String size;
  final int quantity;
  final double totalPrice;
  final DateTime addedAt;

  CartItem({
    required this.imageUrl,
    required this.size,
    required this.quantity,
    required this.totalPrice,
    required this.addedAt,
  });
}

class CartController extends GetxController {
  static CartController get to => Get.find();

  final RxList<CartItem> items = <CartItem>[].obs;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  void addItem(CartItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  double get grandTotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);
}

class WishlistItem {
  final String title;
  final String image;

  WishlistItem({required this.title, required this.image});

  Map<String, dynamic> toMap() {
    return {'title': title, 'image': image};
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(title: map['title'] ?? '', image: map['image'] ?? '');
  }
}

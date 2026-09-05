class WishlistItem {
  final String docId;
  final String title;
  final String image;

  // Alias so controller can use either .docId or .id
  String get id => docId;

  WishlistItem({required this.docId, required this.title, required this.image});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      // docId is NOT saved to backend — it's the document ID itself
    };
  }

  factory WishlistItem.fromMap(String docId, Map<String, dynamic> map) {
    return WishlistItem(
      docId: docId,
      title: map['title'] ?? '',
      image: map['image'] ?? '',
    );
  }
}

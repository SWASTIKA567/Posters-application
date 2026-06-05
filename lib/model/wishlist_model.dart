class WishlistItem {
  final String docId;
  final String title;
  final String image;

  WishlistItem({required this.docId, required this.title, required this.image});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      // docId is NOT saved to Firestore — it's the document ID itself
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

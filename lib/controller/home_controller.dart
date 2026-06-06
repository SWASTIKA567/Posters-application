import 'package:get/get.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // ── Featured: these are CATEGORY cards on home screen ─────────────────
  final featuredPosters = [
    {"title": "Matisse", "image": "assets/posters/poster1.jpg", "price": "₹49"},
    {
      "title": "Discipline",
      "image": "assets/posters/poster2.jpg",
      "price": "₹59",
    },
    {"title": "Flower", "image": "assets/posters/poster3.jpg", "price": "₹39"},
  ].obs;

  // ── Recent: individual posters shown in detail on tap ─────────────────
  final recentPosters = [
    {"title": "Nature", "image": "assets/posters/poster4.jpg", "price": "₹49"},
    {"title": "Travel", "image": "assets/posters/poster5.jpg", "price": "₹69"},
  ].obs;

  // ── Category posters: shown inside CategoryPostersScreen ──────────────
  // Key = featured card title. Add as many posters per category as you want.
  final Map<String, List<Map<String, String>>> categoryPosters = {
    "Matisse": [
      {
        "title": "Matisse Blue",
        "image": "assets/posters/poster1.jpg",
        "price": "₹49",
      },
      {
        "title": "Matisse Red",
        "image": "assets/posters/poster2.jpg",
        "price": "₹59",
      },
      {
        "title": "Matisse Green",
        "image": "assets/posters/poster3.jpg",
        "price": "₹39",
      },
      {
        "title": "Matisse Yellow",
        "image": "assets/posters/poster4.jpg",
        "price": "₹45",
      },
    ],
    "Discipline": [
      {"title": "Focus", "image": "assets/posters/poster2.jpg", "price": "₹59"},
      {"title": "Grind", "image": "assets/posters/poster3.jpg", "price": "₹49"},
      {
        "title": "Hustle",
        "image": "assets/posters/poster4.jpg",
        "price": "₹39",
      },
      {
        "title": "Mindset",
        "image": "assets/posters/poster5.jpg",
        "price": "₹55",
      },
    ],
    "Flower": [
      {"title": "Rose", "image": "assets/posters/poster3.jpg", "price": "₹39"},
      {
        "title": "Sunflower",
        "image": "assets/posters/poster4.jpg",
        "price": "₹49",
      },
      {"title": "Tulip", "image": "assets/posters/poster1.jpg", "price": "₹45"},
      {"title": "Daisy", "image": "assets/posters/poster2.jpg", "price": "₹35"},
    ],
  };

  // Returns posters for a given category title
  List<Map<String, String>> postersByCategory(String categoryTitle) =>
      categoryPosters[categoryTitle] ?? [];
}

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // ── Search ──────────────────────────────────────────────────────────────────
  final searchQuery = ''.obs;

  // ── Selected Category (null = show all) ─────────────────────────────────────
  final selectedCategory = RxnString();

  // ── Loading state ───────────────────────────────────────────────────────────
  final isLoadingPosters = false.obs;

  // ── All Categories with icons ────────────────────────────────────────────────
  final RxList<Map<String, String>> categories = <Map<String, String>>[
    {'title': 'All',        'icon': '🏠'},
    {'title': 'Matisse',    'icon': '🎨'},
    {'title': 'Discipline', 'icon': '💪'},
    {'title': 'Flower',     'icon': '🌸'},
    {'title': 'Nature',     'icon': '🌿'},
    {'title': 'Travel',     'icon': '✈️'},
    {'title': 'Minimal',    'icon': '⬜'},
    {'title': 'Vintage',    'icon': '🕰️'},
    {'title': 'Abstract',   'icon': '🔷'},
    {'title': 'Typography', 'icon': '📝'},
    {'title': 'Sports',     'icon': '⚽'},
    {'title': 'Music',      'icon': '🎵'},
    {'title': 'Movies',     'icon': '🎬'},
    {'title': 'Anime',      'icon': '🌟'},
    {'title': 'Birthday',   'icon': '🎂'},
    {'title': 'Wedding',    'icon': '💍'},
  ].obs;

  // ── Master poster list (reactive) ──────────────────────────────────────────
  final RxList<Map<String, String>> allPosters = <Map<String, String>>[
    {'title': 'Matisse Blue',   'image': 'assets/posters/poster1.jpg', 'price': '₹49', 'category': 'Matisse'},
    {'title': 'Matisse Red',    'image': 'assets/posters/poster2.jpg', 'price': '₹59', 'category': 'Matisse'},
    {'title': 'Matisse Green',  'image': 'assets/posters/poster3.jpg', 'price': '₹39', 'category': 'Matisse'},
    {'title': 'Matisse Yellow', 'image': 'assets/posters/poster4.jpg', 'price': '₹45', 'category': 'Matisse'},
    {'title': 'Focus',          'image': 'assets/posters/poster2.jpg', 'price': '₹59', 'category': 'Discipline'},
    {'title': 'Grind',          'image': 'assets/posters/poster3.jpg', 'price': '₹49', 'category': 'Discipline'},
    {'title': 'Hustle',         'image': 'assets/posters/poster4.jpg', 'price': '₹39', 'category': 'Discipline'},
    {'title': 'Mindset',        'image': 'assets/posters/poster5.jpg', 'price': '₹55', 'category': 'Discipline'},
    {'title': 'Rose',           'image': 'assets/posters/poster3.jpg', 'price': '₹39', 'category': 'Flower'},
    {'title': 'Sunflower',      'image': 'assets/posters/poster4.jpg', 'price': '₹49', 'category': 'Flower'},
    {'title': 'Tulip',          'image': 'assets/posters/poster1.jpg', 'price': '₹45', 'category': 'Flower'},
    {'title': 'Daisy',          'image': 'assets/posters/poster2.jpg', 'price': '₹35', 'category': 'Flower'},
    {'title': 'Nature',         'image': 'assets/posters/poster4.jpg', 'price': '₹49', 'category': 'Nature'},
    {'title': 'Travel',         'image': 'assets/posters/poster5.jpg', 'price': '₹69', 'category': 'Travel'},
  ].obs;

  // ── Filtered posters (reactive) ───────────────────────────────────────────────
  RxList<Map<String, String>> get filteredPosters {
    final q    = searchQuery.value.toLowerCase().trim();
    final cat  = selectedCategory.value;
    return allPosters.where((p) {
      final matchCat   = cat == null || cat == 'All' || p['category'] == cat;
      final matchQuery = q.isEmpty ||
          (p['title'] ?? '').toLowerCase().contains(q) ||
          (p['category'] ?? '').toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList().obs;
  }

  // ── Featured (top row cards) ─────────────────────────────────────────────────
  final featuredPosters = [
    {'title': 'Matisse',    'image': 'assets/posters/poster1.jpg', 'price': '₹49'},
    {'title': 'Discipline', 'image': 'assets/posters/poster2.jpg', 'price': '₹59'},
    {'title': 'Flower',     'image': 'assets/posters/poster3.jpg', 'price': '₹39'},
  ].obs;

  // ── Recent / Trending ────────────────────────────────────────────────────────
  final recentPosters = [
    {'title': 'Nature', 'image': 'assets/posters/poster4.jpg', 'price': '₹49'},
    {'title': 'Travel', 'image': 'assets/posters/poster5.jpg', 'price': '₹69'},
  ].obs;

  // ── Category posters map (used by CategoryPostersScreen) ─────────────────────
  final RxMap<String, List<Map<String, String>>> categoryPosters = <String, List<Map<String, String>>>{
    'Matisse': [
      {'title': 'Matisse Blue',   'image': 'assets/posters/poster1.jpg', 'price': '₹49'},
      {'title': 'Matisse Red',    'image': 'assets/posters/poster2.jpg', 'price': '₹59'},
      {'title': 'Matisse Green',  'image': 'assets/posters/poster3.jpg', 'price': '₹39'},
      {'title': 'Matisse Yellow', 'image': 'assets/posters/poster4.jpg', 'price': '₹45'},
    ],
    'Discipline': [
      {'title': 'Focus',   'image': 'assets/posters/poster2.jpg', 'price': '₹59'},
      {'title': 'Grind',   'image': 'assets/posters/poster3.jpg', 'price': '₹49'},
      {'title': 'Hustle',  'image': 'assets/posters/poster4.jpg', 'price': '₹39'},
      {'title': 'Mindset', 'image': 'assets/posters/poster5.jpg', 'price': '₹55'},
    ],
    'Flower': [
      {'title': 'Rose',      'image': 'assets/posters/poster3.jpg', 'price': '₹39'},
      {'title': 'Sunflower', 'image': 'assets/posters/poster4.jpg', 'price': '₹49'},
      {'title': 'Tulip',     'image': 'assets/posters/poster1.jpg', 'price': '₹45'},
      {'title': 'Daisy',     'image': 'assets/posters/poster2.jpg', 'price': '₹35'},
    ],
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBackendPosters();
  }

  // ── Fetch dynamic posters from Backend / Cloudinary ─────────────────────────
  Future<void> fetchBackendPosters() async {
    try {
      isLoadingPosters.value = true;
      final res = await ApiService.get('/posters');
      if (res != null && res['posters'] is List) {
        final List list = res['posters'];
        final dynamicPosters = <Map<String, String>>[];

        for (var item in list) {
          final title = item['title']?.toString() ?? '';
          final image = item['imageUrl']?.toString() ?? '';
          final price = '₹${item['price'] ?? 49}';
          final category = item['category']?.toString() ?? 'General';
          final id = item['_id']?.toString() ?? '';

          if (title.isNotEmpty && image.isNotEmpty) {
            final posterMap = {
              'id': id,
              'title': title,
              'image': image,
              'price': price,
              'category': category,
              'isDynamic': 'true',
            };
            dynamicPosters.add(posterMap);

            // Add new category if not present
            if (!categories.any((c) => (c['title'] ?? '').toLowerCase() == category.toLowerCase())) {
              categories.add({'title': category, 'icon': '🖼️'});
            }

            // Group into categoryPosters
            if (!categoryPosters.containsKey(category)) {
              categoryPosters[category] = [];
            }
            if (!categoryPosters[category]!.any((p) => p['id'] == id || (p['title'] == title && p['image'] == image))) {
              categoryPosters[category]!.insert(0, posterMap);
            }
          }
        }

        // Remove old dynamic entries and prepend newly loaded ones to top
        allPosters.removeWhere((p) => p['isDynamic'] == 'true');
        allPosters.insertAll(0, dynamicPosters);

        // Also add latest dynamic poster to recent/featured
        if (dynamicPosters.isNotEmpty) {
          for (var p in dynamicPosters.take(2)) {
            if (!recentPosters.any((rp) => rp['title'] == p['title'])) {
              recentPosters.insert(0, p);
            }
          }
        }

        allPosters.refresh();
        categories.refresh();
        categoryPosters.refresh();
      }
    } catch (e) {
      debugPrint('Notice loading backend posters: $e');
    } finally {
      isLoadingPosters.value = false;
    }
  }

  List<Map<String, String>> postersByCategory(String categoryTitle) =>
      categoryPosters[categoryTitle] ?? [];

  void setCategory(String? cat) {
    selectedCategory.value = cat;
  }

  void setSearch(String q) {
    searchQuery.value = q;
  }

  bool get isFiltering =>
      searchQuery.value.isNotEmpty ||
      (selectedCategory.value != null && selectedCategory.value != 'All');
}

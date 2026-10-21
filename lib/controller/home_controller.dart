import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // ── Search ──────────────────────────────────────────────────────────────────
  final searchQuery = ''.obs;

  // ── Selected Category (null = show all) ─────────────────────────────────────
  final selectedCategory = RxnString();

  // ── Loading state ───────────────────────────────────────────────────────────
  final isLoadingPosters = false.obs;

  // ── SharedPreferences keys for asset poster overrides ──────────────────────
  static const String _kAssetCategoryOverrides = 'asset_poster_categories';
  static const String _kDeletedAssetPosters = 'deleted_asset_posters';

  // ── Default Bundled Asset Posters ───────────────────────────────────────────
  static final List<Map<String, String>> _initialAssetPosters = [
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
  ];

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
  final RxList<Map<String, String>> allPosters = <Map<String, String>>[].obs;

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
  final RxMap<String, List<Map<String, String>>> categoryPosters =
      <String, List<Map<String, String>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initPosters();
  }

  Future<void> _initPosters() async {
    await _loadAssetPosters();
    await fetchBackendPosters();
  }

  Future<void> _loadAssetPosters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deleted = prefs.getStringList(_kDeletedAssetPosters) ?? [];
      final overridesRaw = prefs.getString(_kAssetCategoryOverrides);
      Map<String, dynamic> overrides = {};
      if (overridesRaw != null) {
        overrides = jsonDecode(overridesRaw) as Map<String, dynamic>;
      }

      final List<Map<String, String>> assets = [];
      for (final raw in _initialAssetPosters) {
        final title = raw['title'] ?? '';
        if (deleted.contains(title)) continue;

        final category = overrides[title]?.toString() ?? raw['category'] ?? 'General';
        final poster = Map<String, String>.from(raw);
        poster['category'] = category;
        poster['isDynamic'] = 'false';
        assets.add(poster);

        // Make sure category exists in categories list
        if (!categories.any((c) => (c['title'] ?? '').toLowerCase() == category.toLowerCase())) {
          categories.add({'title': category, 'icon': '🖼️'});
        }
      }

      // Keep dynamic posters, update assets
      final dynamicOnes = allPosters.where((p) => p['isDynamic'] == 'true').toList();
      allPosters.assignAll([...dynamicOnes, ...assets]);
      _rebuildCategoryPosters();
    } catch (e) {
      debugPrint('Error loading asset poster overrides: $e');
    }
  }

  void _rebuildCategoryPosters() {
    categoryPosters.clear();
    for (var p in allPosters) {
      final cat = p['category'] ?? 'General';
      if (!categoryPosters.containsKey(cat)) {
        categoryPosters[cat] = [];
      }
      categoryPosters[cat]!.add(p);
    }
    allPosters.refresh();
    categoryPosters.refresh();
    categories.refresh();
  }

  Future<void> updateAssetPosterCategory(String title, String newCategory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final overridesRaw = prefs.getString(_kAssetCategoryOverrides);
      Map<String, dynamic> overrides = {};
      if (overridesRaw != null) {
        overrides = jsonDecode(overridesRaw) as Map<String, dynamic>;
      }
      overrides[title] = newCategory;
      await prefs.setString(_kAssetCategoryOverrides, jsonEncode(overrides));

      final index = allPosters.indexWhere((p) => p['title'] == title && p['isDynamic'] != 'true');
      if (index != -1) {
        allPosters[index]['category'] = newCategory;
      }

      if (!categories.any((c) => (c['title'] ?? '').toLowerCase() == newCategory.toLowerCase())) {
        categories.add({'title': newCategory, 'icon': '🖼️'});
      }

      _rebuildCategoryPosters();
    } catch (e) {
      debugPrint('Error updating asset category: $e');
    }
  }

  Future<void> deleteAssetPoster(String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deleted = prefs.getStringList(_kDeletedAssetPosters) ?? [];
      if (!deleted.contains(title)) {
        deleted.add(title);
        await prefs.setStringList(_kDeletedAssetPosters, deleted);
      }

      allPosters.removeWhere((p) => p['title'] == title && p['isDynamic'] != 'true');
      _rebuildCategoryPosters();
    } catch (e) {
      debugPrint('Error deleting asset poster: $e');
    }
  }

  // ── Fetch dynamic posters from Backend / Cloudinary ─────────────────────────
  Future<void> fetchBackendPosters() async {
    try {
      isLoadingPosters.value = true;
      await _loadAssetPosters();

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
          }
        }

        // Retain local asset posters and place dynamic ones at top
        final assetOnly = allPosters.where((p) => p['isDynamic'] != 'true').toList();
        allPosters.assignAll([...dynamicPosters, ...assetOnly]);

        // Also add latest dynamic poster to recent/featured
        if (dynamicPosters.isNotEmpty) {
          for (var p in dynamicPosters.take(2)) {
            if (!recentPosters.any((rp) => rp['title'] == p['title'])) {
              recentPosters.insert(0, p);
            }
          }
        }

        _rebuildCategoryPosters();
      }
    } catch (e) {
      debugPrint('Notice loading backend posters: $e');
    } finally {
      isLoadingPosters.value = false;
    }
  }

  List<Map<String, String>> postersByCategory(String categoryTitle) {
    return allPosters
        .where((p) => (p['category'] ?? '').toLowerCase() == categoryTitle.toLowerCase())
        .toList();
  }

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

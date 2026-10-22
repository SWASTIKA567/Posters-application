import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // ── Search ──────────────────────────────────────────────────────────────────
  final searchQuery = ''.obs;

  // ── Selected Category (null or 'All' = show all) ───────────────────────────
  final selectedCategory = RxnString();

  // ── Loading state ───────────────────────────────────────────────────────────
  final isLoadingPosters = false.obs;

  // ── SharedPreferences keys for local cache ─────────────────────────────────
  static const String _kCustomLocalPosters = 'custom_local_posters';

  // ── Dynamic Categories with icons ──────────────────────────────────────────
  final RxList<Map<String, String>> categories = <Map<String, String>>[
    {'title': 'All', 'icon': '🏠'},
  ].obs;

  // ── Master poster list (reactive) ──────────────────────────────────────────
  final RxList<Map<String, String>> allPosters = <Map<String, String>>[].obs;

  // ── Filtered posters (reactive) ─────────────────────────────────────────────
  RxList<Map<String, String>> get filteredPosters {
    final q = searchQuery.value.toLowerCase().trim();
    final cat = selectedCategory.value;
    return allPosters.where((p) {
      final matchCat = cat == null || cat == 'All' || p['category']?.toLowerCase() == cat.toLowerCase();
      final matchQuery = q.isEmpty ||
          (p['title'] ?? '').toLowerCase().contains(q) ||
          (p['category'] ?? '').toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList().obs;
  }

  // ── Section 1: "Want to explore Our Collection?" (Category-wise) ───────────
  final RxList<Map<String, String>> featuredPosters = <Map<String, String>>[].obs;

  // ── Section 2: "Trending Posters" ──────────────────────────────────────────
  final RxList<Map<String, String>> recentPosters = <Map<String, String>>[].obs;

  // ── Category posters map (used by CategoryPostersScreen) ───────────────────
  final RxMap<String, List<Map<String, String>>> categoryPosters =
      <String, List<Map<String, String>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBackendPosters();
  }

  // ── Category Icon Mapper ───────────────────────────────────────────────────
  String _getCategoryIcon(String category) {
    final lower = category.toLowerCase().trim();
    if (lower.contains('anime') || lower.contains('manga')) return '🌟';
    if (lower.contains('movie') || lower.contains('cinema')) return '🎬';
    if (lower.contains('music') || lower.contains('song')) return '🎵';
    if (lower.contains('sport') || lower.contains('football') || lower.contains('cricket')) return '⚽';
    if (lower.contains('nature') || lower.contains('green') || lower.contains('landscape')) return '🌿';
    if (lower.contains('flower') || lower.contains('floral') || lower.contains('rose')) return '🌸';
    if (lower.contains('minimal')) return '⬜';
    if (lower.contains('vintage') || lower.contains('retro')) return '🕰️';
    if (lower.contains('art') || lower.contains('paint')) return '🎨';
    if (lower.contains('gym') || lower.contains('fitness') || lower.contains('discipline') || lower.contains('workout')) return '💪';
    if (lower.contains('travel') || lower.contains('trip') || lower.contains('city')) return '✈️';
    if (lower.contains('car') || lower.contains('bike') || lower.contains('auto') || lower.contains('supercar')) return '🏎️';
    if (lower.contains('quote') || lower.contains('typo') || lower.contains('motivation')) return '📝';
    if (lower.contains('gaming') || lower.contains('game')) return '🎮';
    if (lower.contains('abstract')) return '🔷';
    if (lower.contains('birthday')) return '🎂';
    if (lower.contains('wedding')) return '💍';
    return '🖼️';
  }

  // ── Rebuild Sections and Categories dynamically from allPosters ───────────
  void _rebuildSectionsAndCategories() {
    // 1. Rebuild categories dynamically
    final Set<String> uniqueCats = {};
    for (var p in allPosters) {
      final cat = (p['category'] ?? '').trim();
      if (cat.isNotEmpty && cat.toLowerCase() != 'all') {
        uniqueCats.add(cat);
      }
    }

    final List<Map<String, String>> newCats = [
      {'title': 'All', 'icon': '🏠'},
    ];
    for (var cat in uniqueCats) {
      newCats.add({
        'title': cat,
        'icon': _getCategoryIcon(cat),
      });
    }
    categories.assignAll(newCats);

    // 2. Rebuild categoryPosters map
    categoryPosters.clear();
    for (var p in allPosters) {
      final cat = p['category'] ?? 'General';
      if (!categoryPosters.containsKey(cat)) {
        categoryPosters[cat] = [];
      }
      categoryPosters[cat]!.add(p);
    }

    // 3. Rebuild "Want to explore Our Collection?" (featuredPosters) Category-Wise
    // Posters assigned to section 'explore' or 'both'
    final explorePosters = allPosters.where((p) {
      final sec = p['section'] ?? 'both';
      return sec == 'explore' || sec == 'both';
    }).toList();

    final List<Map<String, String>> exploreCategoryCards = [];
    final Set<String> seenExploreCats = {};

    for (var p in explorePosters) {
      final cat = p['category'] ?? 'General';
      if (!seenExploreCats.contains(cat.toLowerCase())) {
        seenExploreCats.add(cat.toLowerCase());
        exploreCategoryCards.add({
          'id': p['id'] ?? '',
          'title': cat, // Shows category name on collection card
          'category': cat,
          'image': p['image'] ?? '',
          'price': p['price'] ?? '₹49',
          'section': 'explore',
        });
      }
    }

    // Fallback: If no posters explicitly tagged 'explore', show available categories from catalog
    if (exploreCategoryCards.isEmpty) {
      final Set<String> fallbackCats = {};
      for (var p in allPosters) {
        final cat = p['category'] ?? 'General';
        if (!fallbackCats.contains(cat.toLowerCase())) {
          fallbackCats.add(cat.toLowerCase());
          exploreCategoryCards.add({
            'id': p['id'] ?? '',
            'title': cat,
            'category': cat,
            'image': p['image'] ?? '',
            'price': p['price'] ?? '₹49',
            'section': 'explore',
          });
        }
      }
    }
    featuredPosters.assignAll(exploreCategoryCards);

    // 4. Rebuild "Trending Posters" (recentPosters)
    // Posters assigned to section 'trending' or 'both'
    final trendingList = allPosters.where((p) {
      final sec = p['section'] ?? 'both';
      return sec == 'trending' || sec == 'both';
    }).toList();

    if (trendingList.isNotEmpty) {
      recentPosters.assignAll(trendingList);
    } else {
      // Fallback: Show latest posters in catalog
      recentPosters.assignAll(allPosters.take(8).toList());
    }

    allPosters.refresh();
    featuredPosters.refresh();
    recentPosters.refresh();
    categoryPosters.refresh();
    categories.refresh();
  }

  // ── Local Cached Posters ───────────────────────────────────────────────────
  Future<List<Map<String, String>>> _getLocalCachedPosters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localRaw = prefs.getString(_kCustomLocalPosters);
      if (localRaw != null) {
        final List list = jsonDecode(localRaw) as List;
        return list.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveLocalPoster(Map<String, String> poster) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await _getLocalCachedPosters();
      list.insert(0, poster);
      await prefs.setString(_kCustomLocalPosters, jsonEncode(list));
      allPosters.insert(0, poster);
      _rebuildSectionsAndCategories();
    } catch (e) {
      debugPrint('Error saving local poster: $e');
    }
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
          final section = item['section']?.toString() ?? 'both';
          final id = item['_id']?.toString() ?? '';

          if (title.isNotEmpty && image.isNotEmpty) {
            dynamicPosters.add({
              'id': id,
              'title': title,
              'image': image,
              'price': price,
              'category': category,
              'section': section,
              'isDynamic': 'true',
            });
          }
        }

        final localPosters = await _getLocalCachedPosters();
        allPosters.assignAll([...dynamicPosters, ...localPosters]);
        _rebuildSectionsAndCategories();
      }
    } catch (e) {
      debugPrint('Notice loading backend posters: $e');
      final localPosters = await _getLocalCachedPosters();
      if (localPosters.isNotEmpty) {
        allPosters.assignAll(localPosters);
        _rebuildSectionsAndCategories();
      }
    } finally {
      isLoadingPosters.value = false;
    }
  }

  // ── Update Poster Section ──────────────────────────────────────────────────
  Future<void> updatePosterSection({
    required String id,
    required String newSection,
  }) async {
    try {
      if (id.isNotEmpty) {
        await ApiService.put('/posters/$id', {'section': newSection});
      }
      final index = allPosters.indexWhere((p) => p['id'] == id);
      if (index != -1) {
        allPosters[index] = {
          ...allPosters[index],
          'section': newSection,
        };
      }
      _rebuildSectionsAndCategories();
    } catch (e) {
      debugPrint('Error updating poster section: $e');
    }
  }

  // ── Delete Poster ──────────────────────────────────────────────────────────
  Future<void> deletePoster(String id, String title) async {
    try {
      if (id.isNotEmpty) {
        await ApiService.delete('/posters/$id');
      }
      final prefs = await SharedPreferences.getInstance();
      final list = await _getLocalCachedPosters();
      list.removeWhere((item) => item['id'] == id || item['title'] == title);
      await prefs.setString(_kCustomLocalPosters, jsonEncode(list));

      allPosters.removeWhere((p) => p['id'] == id || (id.isEmpty && p['title'] == title));
      _rebuildSectionsAndCategories();
    } catch (e) {
      debugPrint('Error deleting poster: $e');
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

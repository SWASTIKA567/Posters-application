import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/home_controller.dart';
import '../services/api_service.dart';
import '../themes/app_colors.dart';
import '../widgets/poster_image.dart';

class AdminPostersView extends StatefulWidget {
  const AdminPostersView({super.key});

  @override
  State<AdminPostersView> createState() => _AdminPostersViewState();
}

class _AdminPostersViewState extends State<AdminPostersView> {
  final homeCtrl = HomeController.to;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController(text: '59');
  final TextEditingController _newCategoryCtrl = TextEditingController();

  File? _selectedImage;
  String? _selectedAssetPath;
  String? _selectedCategory;
  bool _isNewCategory = false;
  bool _isPublishing = false;
  String _uploadStatus = '';
  String _catalogFilter = 'all'; // 'all', 'dynamic', 'asset'

  // Available bundled poster assets that can be assigned
  static const List<String> _bundledAssetOptions = [
    'assets/posters/poster1.jpg',
    'assets/posters/poster2.jpg',
    'assets/posters/poster3.jpg',
    'assets/posters/poster4.jpg',
    'assets/posters/poster5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    if (homeCtrl.categories.isNotEmpty) {
      final firstCat = homeCtrl.categories.firstWhere(
        (c) => c['title'] != 'All',
        orElse: () => {'title': 'General'},
      );
      _selectedCategory = firstCat['title'];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file != null) {
        setState(() {
          _selectedImage = File(file.path);
          _selectedAssetPath = null;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Image Selection Error',
        e.toString(),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  void _showImagePickerModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            const Center(
              child: Text(
                'Select Poster Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.collections_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Pick from Bundled Poster Assets'),
              subtitle: const Text('Use built-in poster templates'),
              onTap: () {
                Get.back();
                _showBundledAssetPickerModal();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBundledAssetPickerModal() {
    Get.bottomSheet(
      Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Bundled Asset Template',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _bundledAssetOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final assetPath = _bundledAssetOptions[index];
                  final isSelected = _selectedAssetPath == assetPath;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAssetPath = assetPath;
                        _selectedImage = null;
                      });
                      Get.back();
                    },
                    child: Container(
                      width: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(assetPath, fit: BoxFit.cover),
                            Positioned(
                              bottom: 6,
                              left: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Asset ${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishPoster() async {
    final title = _titleCtrl.text.trim();
    final category = _isNewCategory
        ? _newCategoryCtrl.text.trim()
        : (_selectedCategory ?? 'General');
    final price = int.tryParse(_priceCtrl.text.trim().replaceAll('₹', '')) ?? 59;

    if (title.isEmpty) {
      Get.snackbar(
        'Missing Title',
        'Please enter a poster title',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    if (category.isEmpty) {
      Get.snackbar(
        'Missing Category',
        'Please select or enter a category',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedImage == null && _selectedAssetPath == null) {
      Get.snackbar(
        'Missing Image',
        'Please select an image (gallery, camera, or bundled asset)',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadStatus = 'Saving poster...';
    });

    try {
      // If a bundled asset was chosen, save directly into local catalog
      if (_selectedAssetPath != null) {
        await homeCtrl.addLocalPoster(
          title: title,
          imagePath: _selectedAssetPath!,
          category: category,
          price: '₹$price',
        );
        _resetForm();
        Get.snackbar(
          '🎉 Asset Poster Added',
          '"$title" was added to category "$category".',
          backgroundColor: const Color(0xFF1B5E20),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // If a file was picked, attempt Cloudinary upload
      setState(() {
        _uploadStatus = 'Uploading image to Cloudinary...';
      });

      final uploadedUrl = await ApiService.uploadImage(_selectedImage!);
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception(
          'Cloudinary upload failed or network unavailable.',
        );
      }

      setState(() {
        _uploadStatus = 'Saving poster to catalog database...';
      });

      final res = await ApiService.post('/posters', {
        'title': title,
        'imageUrl': uploadedUrl,
        'category': category,
        'price': price,
        'description': _descCtrl.text.trim(),
        'sizes': [
          {'label': 'A5', 'dimensions': '14.8 × 21 cm', 'price': 39},
          {'label': 'A4', 'dimensions': '21 × 29.7 cm', 'price': price},
          {'label': 'A3', 'dimensions': '29.7 × 42 cm', 'price': 99},
        ],
      });

      if (res != null && res['success'] == true) {
        _resetForm();
        await homeCtrl.fetchBackendPosters();
        Get.snackbar(
          '🎉 Poster Published Live!',
          '"$title" is now live in the $category category for all users.',
          backgroundColor: const Color(0xFF1B5E20),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        throw Exception(
          ApiService.cleanErrorMessage(
            res?['message'],
            defaultMessage: 'Could not create poster.',
          ),
        );
      }
    } catch (e) {
      // Fallback: If network/backend is unreachable, save locally so admin add always succeeds!
      try {
        final imagePath = _selectedImage?.path ?? _selectedAssetPath ?? '';
        if (imagePath.isNotEmpty) {
          await homeCtrl.addLocalPoster(
            title: title,
            imagePath: imagePath,
            category: category,
            price: '₹$price',
          );
          _resetForm();
          Get.snackbar(
            '🎉 Poster Added (Saved Locally)',
            '"$title" was added to category "$category".',
            backgroundColor: const Color(0xFF1B5E20),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      } catch (_) {}

      Get.snackbar(
        'Upload Notice',
        ApiService.cleanErrorMessage(e),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _uploadStatus = '';
        });
      }
    }
  }

  void _resetForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.text = '59';
    _newCategoryCtrl.clear();
    setState(() {
      _selectedImage = null;
      _selectedAssetPath = null;
      _isNewCategory = false;
    });
  }

  Future<void> _editPosterDetails(Map<String, String> poster) async {
    final id = poster['id'] ?? '';
    final isDynamic = poster['isDynamic'] == 'true';
    final currentTitle = poster['title'] ?? 'Poster';
    final originalTitle = poster['originalTitle'] ?? currentTitle;
    final currentCategory = poster['category'] ?? 'General';
    final rawPrice = (poster['price'] ?? '₹59').replaceAll('₹', '').trim();

    final availableCats = homeCtrl.categories
        .where((c) => c['title'] != 'All')
        .map((c) => c['title']!)
        .toList();

    String selectedCategory = availableCats.contains(currentCategory)
        ? currentCategory
        : (availableCats.isNotEmpty ? availableCats.first : 'General');

    final titleEditCtrl = TextEditingController(text: currentTitle);
    final priceEditCtrl = TextEditingController(text: rawPrice);
    final customCatCtrl = TextEditingController();
    bool isCustom = false;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isDynamic ? Icons.cloud_done_rounded : Icons.folder_special_rounded,
                  color: isDynamic ? AppColors.primary : Colors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isDynamic ? 'Edit Cloud Poster' : 'Edit Asset Poster',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Poster Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleEditCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter poster title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  if (!isCustom)
                    DropdownButtonFormField<String>(
                      initialValue: availableCats.contains(selectedCategory) ? selectedCategory : null,
                      decoration: InputDecoration(
                        labelText: 'Select Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: availableCats.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    )
                  else
                    TextField(
                      controller: customCatCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'New Category Name',
                        hintText: 'e.g. Gaming, Aesthetic',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        isCustom = !isCustom;
                      });
                    },
                    icon: Icon(isCustom ? Icons.list_rounded : Icons.add_circle_outline_rounded, size: 18),
                    label: Text(isCustom ? 'Choose existing category' : '+ Create new category'),
                  ),
                  const SizedBox(height: 10),
                  const Text('Base Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: priceEditCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: '59',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final targetTitle = titleEditCtrl.text.trim();
                  final targetCategory = isCustom ? customCatCtrl.text.trim() : selectedCategory;
                  final targetPrice = priceEditCtrl.text.trim().replaceAll('₹', '');

                  if (targetTitle.isEmpty) {
                    Get.snackbar('Title Required', 'Please enter a valid poster title.');
                    return;
                  }
                  if (targetCategory.isEmpty) {
                    Get.snackbar('Category Required', 'Please enter or select a category.');
                    return;
                  }

                  Get.back();

                  try {
                    if (isDynamic && id.isNotEmpty) {
                      final res = await ApiService.put('/posters/$id', {
                        'title': targetTitle,
                        'category': targetCategory,
                        'price': int.tryParse(targetPrice) ?? 59,
                      });
                      if (res != null && res['success'] == true) {
                        await homeCtrl.fetchBackendPosters();
                        Get.snackbar(
                          'Poster Updated',
                          '"$targetTitle" is now in "$targetCategory" (₹$targetPrice)',
                          backgroundColor: const Color(0xFF1B5E20),
                          colorText: Colors.white,
                        );
                      }
                    } else {
                      // Asset or local poster update
                      await homeCtrl.updateAssetPoster(
                        originalTitle: originalTitle,
                        newTitle: targetTitle,
                        newCategory: targetCategory,
                        newPrice: targetPrice.isNotEmpty ? '₹$targetPrice' : null,
                      );
                      Get.snackbar(
                        'Poster Updated',
                        '"$targetTitle" is now in "$targetCategory" (₹$targetPrice)',
                        backgroundColor: const Color(0xFF1B5E20),
                        colorText: Colors.white,
                      );
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Update Error',
                      ApiService.cleanErrorMessage(e),
                      backgroundColor: Colors.red.shade800,
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deletePoster(Map<String, String> poster) async {
    final id = poster['id'] ?? '';
    final isDynamic = poster['isDynamic'] == 'true';
    final title = poster['title'] ?? 'Poster';
    final originalTitle = poster['originalTitle'] ?? title;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Poster'),
        content: Text(
          'Are you sure you want to remove "$title" from the store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (isDynamic && id.isNotEmpty) {
          final res = await ApiService.delete('/posters/$id');
          if (res != null && res['success'] == true) {
            await homeCtrl.fetchBackendPosters();
            Get.snackbar(
              'Deleted',
              'Poster "$title" was removed.',
              backgroundColor: Colors.black87,
              colorText: Colors.white,
            );
          }
        } else {
          // Asset poster deletion
          await homeCtrl.deleteAssetPoster(title, originalTitle: originalTitle);
          Get.snackbar(
            'Deleted',
            'Asset poster "$title" was removed.',
            backgroundColor: Colors.black87,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Delete Notice',
          ApiService.cleanErrorMessage(e),
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _confirmResetAssetPosters() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset Bundled Posters'),
        content: const Text(
          'This will restore all default bundled asset posters (Matisse, Discipline, Flower, Nature, Travel) and their original categories. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B)),
            child: const Text('Reset Defaults', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await homeCtrl.resetAssetPosters();
      Get.snackbar(
        'Posters Restored',
        'Bundled asset posters have been restored to defaults.',
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text(
          'Manage Posters (Admin)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Restore Default Bundled Posters',
            onPressed: _confirmResetAssetPosters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Posters',
            onPressed: () => homeCtrl.fetchBackendPosters(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ADD POSTER CARD ─────────────────────────────────────────
            _buildAddPosterCard(),

            const SizedBox(height: 24),

            // ── EXISTING CATALOG / MANAGE ───────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Live Catalog Posters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Obx(() => Text(
                  '${homeCtrl.allPosters.length} Total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Add, update categories, edit titles/prices, or delete both Cloud and Asset posters.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // ── Filter Chips (All, Cloudinary, Bundled Assets) ───────────
            _buildCatalogFilterChips(),

            const SizedBox(height: 12),

            _buildLivePostersList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(label: 'All Posters', key: 'all'),
          const SizedBox(width: 8),
          _filterChip(label: '📁 Bundled / Local Assets', key: 'asset'),
          const SizedBox(width: 8),
          _filterChip(label: '⚡ Cloud Database', key: 'dynamic'),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required String key}) {
    final isSelected = _catalogFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _catalogFilter = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildAddPosterCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Add New Poster to Store',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),

          // ── Image preview / picker box ──
          GestureDetector(
            onTap: _isPublishing ? null : _showImagePickerModal,
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_selectedImage != null || _selectedAssetPath != null)
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: (_selectedImage != null || _selectedAssetPath != null) ? 2 : 1,
                ),
              ),
              child: (_selectedImage != null || _selectedAssetPath != null)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.cover)
                              : Image.asset(_selectedAssetPath!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: _showImagePickerModal,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedAssetPath != null ? 'Bundled Asset Image' : 'Device Image',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 44,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to Select Poster Image',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bundled Asset Templates, Gallery, or Camera',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Title Input ──
          TextField(
            controller: _titleCtrl,
            enabled: !_isPublishing,
            decoration: InputDecoration(
              labelText: 'Poster Title *',
              hintText: 'e.g. Cyberpunk Samurai, Matisse Joy',
              prefixIcon: const Icon(Icons.title_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Category Selector ──
          Row(
            children: [
              Expanded(
                child: _isNewCategory
                    ? TextField(
                        controller: _newCategoryCtrl,
                        enabled: !_isPublishing,
                        decoration: InputDecoration(
                          labelText: 'New Category Name *',
                          hintText: 'e.g. Gaming, Aesthetic, Quotes',
                          prefixIcon: const Icon(
                            Icons.category_rounded,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      )
                    : Obx(() {
                        final availableCats = homeCtrl.categories
                            .where((c) => c['title'] != 'All')
                            .map((c) => c['title']!)
                            .toList();

                        return DropdownButtonFormField<String>(
                          initialValue: availableCats.contains(_selectedCategory)
                              ? _selectedCategory
                              : (availableCats.isNotEmpty
                                    ? availableCats.first
                                    : null),
                          items: availableCats.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: _isPublishing
                              ? null
                              : (val) {
                                  setState(() => _selectedCategory = val);
                                },
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: const Icon(
                              Icons.folder_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        );
                      }),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _isNewCategory
                    ? 'Choose Existing Category'
                    : 'Create New Category',
                icon: Icon(
                  _isNewCategory
                      ? Icons.list_rounded
                      : Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isNewCategory = !_isNewCategory;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Price Input ──
          TextField(
            controller: _priceCtrl,
            enabled: !_isPublishing,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Base Price (₹) *',
              prefixText: '₹ ',
              hintText: '59',
              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Description ──
          TextField(
            controller: _descCtrl,
            enabled: !_isPublishing,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: '300 GSM archival stock, vivid pigment inks...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Upload status text ──
          if (_isPublishing && _uploadStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _uploadStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishPoster,
              icon: _isPublishing
                  ? const SizedBox.shrink()
                  : const Icon(Icons.add_task_rounded, color: Colors.white),
              label: Text(
                _isPublishing
                    ? 'Publishing Poster...'
                    : 'Add Poster to Store',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePostersList() {
    return Obx(() {
      final all = homeCtrl.allPosters;
      if (all.isEmpty) {
        return const Center(child: Text('No posters available.'));
      }

      final posters = all.where((p) {
        final isDynamic = p['isDynamic'] == 'true';
        if (_catalogFilter == 'dynamic') return isDynamic;
        if (_catalogFilter == 'asset') return !isDynamic;
        return true;
      }).toList();

      if (posters.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _catalogFilter == 'dynamic'
                  ? 'No cloud database posters found.'
                  : 'No asset/local posters found.',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final p = posters[index];
          final isDynamic = p['isDynamic'] == 'true';
          final img = p['image'] ?? '';
          final category = p['category'] ?? 'General';
          final price = p['price'] ?? '₹59';

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDynamic
                    ? AppColors.primary.withOpacity(0.3)
                    : const Color(0xFFEAEAEA),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 55,
                    height: 75,
                    child: PosterImage(
                      imagePath: img,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _editPosterDetails(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 11,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              price,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDynamic ? '⚡ Cloud / Database' : '📁 Bundled Asset / Local',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDynamic ? Colors.green.shade700 : Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF00796B),
                    size: 22,
                  ),
                  tooltip: 'Edit Poster',
                  onPressed: () => _editPosterDetails(p),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 22,
                  ),
                  tooltip: 'Delete Poster',
                  onPressed: () => _deletePoster(p),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

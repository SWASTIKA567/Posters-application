import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/home_controller.dart';
import '../services/api_service.dart';
import '../themes/app_colors.dart';

class AdminPostersView extends StatefulWidget {
  const AdminPostersView({super.key});

  @override
  State<AdminPostersView> createState() => _AdminPostersViewState();
}

class _AdminPostersViewState extends State<AdminPostersView> {
  final homeCtrl = HomeController.to;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _newCategoryCtrl = TextEditingController();

  File? _selectedImage;
  String? _selectedCategory;
  bool _isNewCategory = false;
  bool _isPublishing = false;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    if (homeCtrl.categories.isNotEmpty) {
      // Pick first non-'All' category as default
      final firstCat = homeCtrl.categories.firstWhere(
        (c) => c['title'] != 'All',
        orElse: () => {'title': 'Anime'},
      );
      _selectedCategory = firstCat['title'];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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

  Future<void> _publishPoster() async {
    final title = _titleCtrl.text.trim();
    final category = _isNewCategory
        ? _newCategoryCtrl.text.trim()
        : (_selectedCategory ?? 'General');

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

    if (_selectedImage == null) {
      Get.snackbar(
        'Missing Image',
        'Please pick a poster image to upload',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadStatus = 'Uploading image to Cloudinary...';
    });

    try {
      // 1. Upload image to Cloudinary
      final uploadedUrl = await ApiService.uploadImage(_selectedImage!);
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception(
          'Failed to upload image. Please check internet connection.',
        );
      }

      setState(() {
        _uploadStatus = 'Saving poster to catalog database...';
      });

      // 2. Save poster in MongoDB with standard fixed size pricing (A5: ₹39, A4: ₹59, A3: ₹99)
      final res = await ApiService.post('/posters', {
        'title': title,
        'imageUrl': uploadedUrl,
        'category': category,
        'price': 59,
        'description': _descCtrl.text.trim(),
        'sizes': [
          {'label': 'A5', 'dimensions': '14.8 × 21 cm', 'price': 39},
          {'label': 'A4', 'dimensions': '21 × 29.7 cm', 'price': 59},
          {'label': 'A3', 'dimensions': '29.7 × 42 cm', 'price': 99},
        ],
      });

      if (res != null && (res['success'] == true || res['poster'] != null)) {
        // Reset form
        _titleCtrl.clear();
        _descCtrl.clear();
        _newCategoryCtrl.clear();
        setState(() {
          _selectedImage = null;
          _isNewCategory = false;
        });

        // Refresh home posters
        await homeCtrl.fetchBackendPosters();

        Get.snackbar(
          '🎉 Poster Published!',
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

  Future<void> _deletePoster(String id, String title) async {
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
            const Text(
              'Live Catalog Posters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Posters uploaded here are synced live to MongoDB and Cloudinary.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            _buildLivePostersList(),

            const SizedBox(height: 40),
          ],
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
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedImage != null
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: _selectedImage != null ? 2 : 1,
                ),
              ),
              child: _selectedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
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
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to Pick Poster Image',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'High-res JPG / PNG (Gallery or Camera)',
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
              hintText: 'e.g. Cyberpunk Samurai, Neon Bloom',
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
                          hintText: 'e.g. Gaming, Quotes, Cars',
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
                          value: availableCats.contains(_selectedCategory)
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

          // ── Base Price ──

          // ── Description ──
          TextField(
            controller: _descCtrl,
            enabled: !_isPublishing,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: '300 GSM archival stock, vivid archival inks...',
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
                  : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
              label: Text(
                _isPublishing
                    ? 'Publishing Poster...'
                    : 'Publish Poster to Store',
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
      final posters = homeCtrl.allPosters;
      if (posters.isEmpty) {
        return const Center(child: Text('No posters available.'));
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final p = posters[index];
          final isDynamic = p['isDynamic'] == 'true';
          final id = p['id'] ?? '';
          final img = p['image'] ?? '';

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
                    child: img.startsWith('http')
                        ? Image.network(img, fit: BoxFit.cover)
                        : Image.asset(img, fit: BoxFit.cover),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p['category'] ?? 'General',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isDynamic) ...[
                        const SizedBox(height: 4),
                        const Text(
                          '⚡ Cloudinary / Database item',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isDynamic && id.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete Poster',
                    onPressed: () => _deletePoster(id, p['title'] ?? 'Poster'),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

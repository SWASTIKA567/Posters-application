import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
  String? _selectedCategory;
  String _selectedSection = 'both'; // 'explore', 'trending', 'both', 'none'
  bool _isNewCategory = false;
  bool _isPublishing = false;
  String _uploadStatus = '';
  String _catalogFilter = 'all'; // 'all', 'explore', 'trending', 'none'

  // ── Customer Print Orders State ─────────────────────────────────────────────
  List<dynamic> _customerOrders = [];
  bool _isLoadingOrders = false;

  final List<Map<String, String>> _sectionOptions = [
    {
      'key': 'both',
      'label': 'Both Sections',
      'desc': 'Shows in Explore Collection & Trending Posters',
      'icon': '🌟+🔥',
    },
    {
      'key': 'explore',
      'label': 'Want to Explore Our Collection',
      'desc': 'Shows under category in Explore Our Collection',
      'icon': '🌟',
    },
    {
      'key': 'trending',
      'label': 'Trending Posters',
      'desc': 'Shows directly in Trending Posters row',
      'icon': '🔥',
    },
    {
      'key': 'none',
      'label': 'General Catalog Only',
      'desc': 'Available in store search and category browse only',
      'icon': '📦',
    },
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
    _fetchCustomerOrders();
  }

  Future<void> _fetchCustomerOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final res = await ApiService.get('/orders/admin/all');
      if (res != null && res['success'] == true) {
        setState(() {
          _customerOrders = (res['orders'] as List<dynamic>? ?? []);
          _isLoadingOrders = false;
        });
      } else {
        setState(() => _isLoadingOrders = false);
      }
    } catch (e) {
      debugPrint('Admin fetch orders notice: $e');
      setState(() => _isLoadingOrders = false);
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

    if (_selectedImage == null) {
      Get.snackbar(
        'Missing Image',
        'Please select an image from gallery or camera',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadStatus = 'Uploading image...';
    });

    try {
      final uploadedUrl = await ApiService.uploadImage(_selectedImage!);
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Cloudinary upload failed or network unavailable.');
      }

      setState(() {
        _uploadStatus = 'Saving poster to catalog database...';
      });

      final res = await ApiService.post('/posters', {
        'title': title,
        'imageUrl': uploadedUrl,
        'category': category,
        'section': _selectedSection,
        'price': price,
        'description': _descCtrl.text.trim(),
        'sizes': [
          {'label': 'A5', 'dimensions': '14.8 × 21 cm', 'price': (price * 0.75).round()},
          {'label': 'A4', 'dimensions': '21 × 29.7 cm', 'price': price},
          {'label': 'A3', 'dimensions': '29.7 × 42 cm', 'price': (price * 1.6).round()},
        ],
      });

      if (res != null && res['success'] == true) {
        _resetForm();
        await homeCtrl.fetchBackendPosters();
        Get.snackbar(
          'Poster Published Live',
          '"$title" added to "$category" in section "${_getSectionLabel(_selectedSection)}".',
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
      // Offline fallback: save locally
      try {
        if (_selectedImage != null) {
          await homeCtrl.saveLocalPoster({
            'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
            'title': title,
            'image': _selectedImage!.path,
            'category': category,
            'section': _selectedSection,
            'price': '₹$price',
            'isDynamic': 'false',
          });
          _resetForm();
          Get.snackbar(
            'Poster Added (Saved Locally)',
            '"$title" saved to category "$category" on device.',
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
      _isNewCategory = false;
      _selectedSection = 'both';
    });
  }

  String _getSectionLabel(String? sec) {
    switch (sec) {
      case 'explore':
        return '🌟 Explore Collection';
      case 'trending':
        return '🔥 Trending';
      case 'both':
        return '🌟+🔥 Both';
      case 'none':
        return '📦 Catalog Only';
      default:
        return '🌟+🔥 Both';
    }
  }

  Color _getSectionColor(String? sec) {
    switch (sec) {
      case 'explore':
        return const Color(0xFF6A1B9A);
      case 'trending':
        return const Color(0xFFE65100);
      case 'both':
        return AppColors.primary;
      case 'none':
        return Colors.blueGrey;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _quickChangeSection(Map<String, String> poster) async {
    final id = poster['id'] ?? '';
    final currentSection = poster['section'] ?? 'both';
    final title = poster['title'] ?? 'Poster';

    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Assign Section for "$title"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._sectionOptions.map((opt) {
              final isCurrent = opt['key'] == currentSection;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : Colors.grey.shade300,
                    width: isCurrent ? 2 : 1,
                  ),
                  color: isCurrent ? AppColors.primary.withOpacity(0.06) : Colors.white,
                ),
                child: ListTile(
                  title: Text(
                    '${opt['icon']}  ${opt['label']}',
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isCurrent ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    opt['desc']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Get.back();
                    await homeCtrl.updatePosterSection(
                      id: id,
                      newSection: opt['key']!,
                    );
                    Get.snackbar(
                      'Section Updated',
                      '"$title" is now set to ${opt['label']}.',
                      backgroundColor: const Color(0xFF1B5E20),
                      colorText: Colors.white,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _editPosterDetails(Map<String, String> poster) async {
    final id = poster['id'] ?? '';
    final currentTitle = poster['title'] ?? 'Poster';
    final currentCategory = poster['category'] ?? 'General';
    final currentSection = poster['section'] ?? 'both';
    final rawPrice = (poster['price'] ?? '₹59').replaceAll('₹', '').trim();

    final availableCats = homeCtrl.categories
        .where((c) => c['title'] != 'All')
        .map((c) => c['title']!)
        .toList();

    String selectedCategory = availableCats.contains(currentCategory)
        ? currentCategory
        : (availableCats.isNotEmpty ? availableCats.first : 'General');
    String selectedSec = currentSection;

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
              children: const [
                Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Edit Poster Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Poster Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (!isCustom)
                    DropdownButtonFormField<String>(
                      initialValue: availableCats.contains(selectedCategory) ? selectedCategory : null,
                      decoration: InputDecoration(
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

                  const Text('Section Assignment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSec,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _sectionOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt['key'],
                        child: Text('${opt['icon']}  ${opt['label']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedSec = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Base Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

                  if (targetTitle.isEmpty || targetCategory.isEmpty) {
                    Get.snackbar('Validation', 'Title and Category are required.');
                    return;
                  }

                  Get.back();

                  try {
                    if (id.isNotEmpty) {
                      final res = await ApiService.put('/posters/$id', {
                        'title': targetTitle,
                        'category': targetCategory,
                        'section': selectedSec,
                        'price': int.tryParse(targetPrice) ?? 59,
                      });
                      if (res != null && res['success'] == true) {
                        await homeCtrl.fetchBackendPosters();
                        Get.snackbar(
                          'Poster Updated',
                          '"$targetTitle" updated successfully.',
                          backgroundColor: const Color(0xFF1B5E20),
                          colorText: Colors.white,
                        );
                      }
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
    final title = poster['title'] ?? 'Poster';

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
        await homeCtrl.deletePoster(id, title);
        Get.snackbar(
          'Deleted',
          'Poster "$title" was removed.',
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FA),
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: Colors.black87,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: Icon(Icons.print_rounded, size: 20),
                text: 'Customer Prints',
              ),
              Tab(
                icon: Icon(Icons.inventory_2_rounded, size: 20),
                text: 'Store Posters',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                homeCtrl.fetchBackendPosters();
                _fetchCustomerOrders();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildCustomerPrintsTab(),
            _buildStoreCatalogTab(),
          ],
        ),
      ),
    );
  }

  // ── STORE CATALOG TAB ───────────────────────────────────────────────────────
  Widget _buildStoreCatalogTab() {
    return SingleChildScrollView(
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
            'Select section (Explore Collection, Trending, Both) for any poster.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // ── Filter Chips ────────────────────────────────────────────
          _buildCatalogFilterChips(),

          const SizedBox(height: 12),

          _buildLivePostersList(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── CUSTOMER PRINTS TAB ─────────────────────────────────────────────────────
  Widget _buildCustomerPrintsTab() {
    if (_isLoadingOrders) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text(
              'Loading customer print uploads...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_customerOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchCustomerOrders,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.print_disabled_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Customer Posters Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When customers upload posters to print, they will securely appear here with who uploaded it, date & time, and private print download links.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _fetchCustomerOrders,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCustomerOrders,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _customerOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = _customerOrders[index] as Map<String, dynamic>;
          return _buildCustomerOrderCard(order);
        },
      ),
    );
  }

  Widget _buildCustomerOrderCard(Map<String, dynamic> order) {
    final customerName = (order['customerName'] ?? 'Customer').toString();
    final customerEmail = (order['customerEmail'] ?? 'No email').toString();
    final customerPhone = (order['customerPhone'] ?? '').toString();
    final status = (order['status'] ?? 'Pending').toString();
    final createdAt = order['createdAt'];
    final items = (order['items'] as List<dynamic>? ?? []);
    final orderId = (order['_id'] ?? '').toString();
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8).toUpperCase() : orderId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER: User info & Date ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusBadgeColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusBadgeColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customerEmail + (customerPhone.isNotEmpty ? ' • $customerPhone' : ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Order #$shortId',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── POSTER ITEMS ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploads (${items.length} ${items.length == 1 ? 'Poster' : 'Posters'})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ...items.map((item) {
                  final itemMap = item as Map<String, dynamic>;
                  final imgUrl = (itemMap['imageUrl'] ?? '').toString();
                  final size = (itemMap['size'] ?? 'A4').toString();
                  final qty = itemMap['quantity'] ?? 1;
                  final price = itemMap['totalPrice'] ?? 0;
                  final printDownloadUrl = (itemMap['printDownloadUrl'] ?? imgUrl).toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 75,
                            color: Colors.grey.shade200,
                            child: imgUrl.isNotEmpty
                                ? Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  )
                                : const Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Size $size',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Qty: $qty',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹$price',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showPrintDialog(itemMap, order),
                                    icon: const Icon(Icons.fullscreen_rounded, size: 14),
                                    label: const Text('View', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF111827),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _downloadImageToDevice(
                                      printDownloadUrl,
                                      'poster_${customerName}_${size}_$qty',
                                    ),
                                    icon: const Icon(Icons.file_download_rounded, size: 14),
                                    label: const Text('Download', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: printDownloadUrl));
                                      Get.snackbar(
                                        'Link Copied',
                                        'Private print URL copied! Valid for 24 hours.',
                                        backgroundColor: const Color(0xFF10B981),
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 3),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 13),
                                    label: const Text('Link', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintDialog(Map<String, dynamic> item, Map<String, dynamic> order) {
    final imgUrl = (item['imageUrl'] ?? '').toString();
    final printDownloadUrl = (item['printDownloadUrl'] ?? imgUrl).toString();
    final customerName = (order['customerName'] ?? 'Customer').toString();
    final customerEmail = (order['customerEmail'] ?? '').toString();
    final size = (item['size'] ?? 'A4').toString();
    final qty = item['quantity'] ?? 1;
    final createdAt = _formatDateTime(order['createdAt']);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Customer Print Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _printInfoRow('Uploaded By:', customerName),
                    const SizedBox(height: 4),
                    _printInfoRow('Email:', customerEmail),
                    const SizedBox(height: 4),
                    _printInfoRow('Uploaded At:', createdAt),
                    const SizedBox(height: 4),
                    _printInfoRow('Poster Size:', '$size ($qty ${qty == 1 ? 'Copy' : 'Copies'})'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 260,
                  width: double.infinity,
                  color: Colors.black12,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('Unable to load preview'),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Pinch or double tap to zoom in and check print quality',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        _downloadImageToDevice(
                          printDownloadUrl,
                          'poster_${customerName}_${size}_$qty',
                        );
                      },
                      icon: const Icon(Icons.file_download_rounded, size: 16),
                      label: const Text('Download Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: printDownloadUrl));
                        Get.back();
                        Get.snackbar(
                          'Signed URL Copied',
                          'Private Cloudinary link copied! Send to printing shop.',
                          backgroundColor: const Color(0xFF10B981),
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImageToDevice(String url, String fileName) async {
    try {
      Get.snackbar(
        'Downloading Poster',
        'Fetching original print file...',
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (downloadDir.existsSync()) {
          targetDir = downloadDir;
        } else {
          targetDir = Directory('/storage/emulated/0/Pictures');
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          targetDir = Directory('$userProfile\\Downloads');
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          targetDir = Directory('$home/Downloads');
        }
      }

      if (targetDir != null && targetDir.existsSync()) {
        final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
        final file = File('${targetDir.path}${Platform.pathSeparator}$safeName.jpg');
        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          'Downloaded Successfully',
          'Poster saved to Downloads: ${file.path.split(Platform.pathSeparator).last}',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Clipboard.setData(ClipboardData(text: url));
        Get.snackbar(
          'Print Link Ready',
          'Direct print link copied to clipboard!',
          backgroundColor: const Color(0xFF3B82F6),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: url));
      Get.snackbar(
        'Link Ready',
        'Direct download link copied to clipboard! (Status: $e)',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    }
  }

  Widget _printInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'processing':
        return const Color(0xFF8B5CF6);
      case 'shipped':
        return const Color(0xFF06B6D4);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(dynamic rawDate) {
    if (rawDate == null) return 'Recent';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute $period';
    } catch (_) {
      return 'Recent';
    }
  }

  Widget _buildCatalogFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(label: 'All Posters', key: 'all'),
          const SizedBox(width: 8),
          _filterChip(label: '🌟 Explore Collection', key: 'explore'),
          const SizedBox(width: 8),
          _filterChip(label: '🔥 Trending Posters', key: 'trending'),
          const SizedBox(width: 8),
          _filterChip(label: '📦 Catalog Only', key: 'none'),
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
                          'Choose from Gallery or take a photo',
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
              hintText: 'e.g. Cyberpunk Samurai, Anime Warrior',
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

          // ── Section Selector ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.dashboard_customize_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Assign to Section *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSection,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _sectionOptions.map((opt) {
                    return DropdownMenuItem(
                      value: opt['key'],
                      child: Text('${opt['icon']}  ${opt['label']}'),
                    );
                  }).toList(),
                  onChanged: _isPublishing
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedSection = val);
                          }
                        },
                ),
                const SizedBox(height: 4),
                Text(
                  _sectionOptions.firstWhere((o) => o['key'] == _selectedSection)['desc'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
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
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'No posters in catalog yet. Add your first poster above!',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      final posters = all.where((p) {
        final sec = p['section'] ?? 'both';
        if (_catalogFilter == 'explore') {
          return sec == 'explore' || sec == 'both';
        }
        if (_catalogFilter == 'trending') {
          return sec == 'trending' || sec == 'both';
        }
        if (_catalogFilter == 'none') {
          return sec == 'none';
        }
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
              'No posters match the "${_catalogFilter}" section filter.',
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
          final img = p['image'] ?? '';
          final category = p['category'] ?? 'General';
          final section = p['section'] ?? 'both';
          final price = p['price'] ?? '₹59';

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEAEAEA),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 6),
                      // Section badge with quick-change tap
                      GestureDetector(
                        onTap: () => _quickChangeSection(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getSectionColor(section).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getSectionColor(section).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getSectionLabel(section),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getSectionColor(section),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 12,
                                color: _getSectionColor(section),
                              ),
                            ],
                          ),
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

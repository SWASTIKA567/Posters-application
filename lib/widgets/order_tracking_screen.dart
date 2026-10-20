import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/order_controller.dart';
import '../services/api_service.dart';
import '../themes/app_colors.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final bool autoOpenReplacement;

  const OrderTrackingScreen({
    super.key,
    required this.order,
    this.autoOpenReplacement = false,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Map<String, dynamic> _order;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    if (widget.autoOpenReplacement) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openReplacementSheet();
      });
    }
  }

  void _openReplacementSheet() {
    final TextEditingController reasonCtrl = TextEditingController();
    List<File> pickedPhotos = [];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> pickPhoto(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final XFile? file = await picker.pickImage(
                  source: source,
                  imageQuality: 85,
                  maxWidth: 1600,
                );
                if (file != null) {
                  setModalState(() {
                    pickedPhotos.add(File(file.path));
                  });
                }
              } catch (e) {
                Get.snackbar('Image Picker', 'Could not access image: $e');
              }
            }

            void showPhotoSourceDialog() {
              showModalBottomSheet(
                context: modalContext,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Add Defect Photo",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF8B0000),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                          title: const Text("Take Photo with Camera", style: TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () {
                            Navigator.pop(modalContext);
                            pickPhoto(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(Icons.photo_library, color: Colors.black87, size: 20),
                          ),
                          title: const Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () {
                            Navigator.pop(modalContext);
                            pickPhoto(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalContext).size.height * 0.88,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B0000).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.published_with_changes_rounded, color: Color(0xFF8B0000), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Request Free Replacement",
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Kechi 100% Quality & Defect Guarantee",
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: isSubmitting ? null : () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade900),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Upload clear photo(s) of the defect or transit damage within 24 hours of delivery. Once verified, we will dispatch a 100% free reprint to your address.",
                                style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Issue Description Field
                      const Text(
                        "Describe the Defect / Issue *",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonCtrl,
                        maxLines: 3,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          hintText: "E.g. Poster was bent during transit, color smudged, or print paper was torn...",
                          hintStyle: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.35)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Defect Photo Upload
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Upload Defect Photo(s) *",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          Text(
                            "${pickedPhotos.length}/3 photos",
                            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Photos row
                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (pickedPhotos.length < 3)
                              GestureDetector(
                                onTap: isSubmitting ? null : showPhotoSourceDialog,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF8B0000).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, color: const Color(0xFF8B0000), size: 26),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Add Photo",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8B0000)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ...pickedPhotos.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final file = entry.value;
                              return Container(
                                width: 90,
                                height: 90,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: isSubmitting
                                            ? null
                                            : () {
                                                setModalState(() {
                                                  pickedPhotos.removeAt(idx);
                                                });
                                              },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final reason = reasonCtrl.text.trim();
                                  if (reason.length < 5) {
                                    Get.snackbar(
                                      'Missing Details',
                                      'Please write a few words explaining the defect with the poster.',
                                      backgroundColor: Colors.orange.shade800,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  if (pickedPhotos.isEmpty) {
                                    Get.snackbar(
                                      'Photo Required',
                                      'Please upload at least 1 clear photo showing the defective poster.',
                                      backgroundColor: Colors.orange.shade800,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  setModalState(() {
                                    isSubmitting = true;
                                  });

                                  try {
                                    // 1. Upload photos to server / Cloudinary
                                    List<String> uploadedUrls = [];
                                    for (final photoFile in pickedPhotos) {
                                      final url = await ApiService.uploadImage(photoFile);
                                      if (url != null && url.isNotEmpty) {
                                        uploadedUrls.add(url);
                                      }
                                    }

                                    if (uploadedUrls.isEmpty) {
                                      throw Exception('Failed to upload defect photo. Please check your internet connection.');
                                    }

                                    // 2. Submit replacement request to backend
                                    final orderId = (_order['orderId'] ?? _order['_id']).toString();
                                    final success = await OrderController.to.submitReplacementRequest(
                                      orderId: orderId,
                                      reason: reason,
                                      photos: uploadedUrls,
                                    );

                                    if (success) {
                                      Navigator.pop(modalContext);
                                      setState(() {
                                        _order['replacementRequest'] = {
                                          'status': 'Requested',
                                          'reason': reason,
                                          'photos': uploadedUrls,
                                          'requestedAt': DateTime.now().toIso8601String(),
                                        };
                                      });
                                    } else {
                                      setModalState(() {
                                        isSubmitting = false;
                                      });
                                    }
                                  } catch (err) {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                    Get.snackbar(
                                      'Error',
                                      ApiService.cleanErrorMessage(err),
                                      backgroundColor: Colors.red.shade800,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    SizedBox(width: 12),
                                    Text("Uploading Photos & Submitting...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : const Text(
                                  "Submit Replacement Request",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (_order['status'] ?? 'Pending').toString();
    final waybill = (_order['waybillNumber'] ?? _order['trackingCode'] ?? 'SFX849201824').toString();
    final courierPartner = (_order['courierPartner'] ?? 'Shadowfax Express').toString();
    final trackingUrl = (_order['trackingUrl'] ?? 'https://tracker.shadowfax.in/track?orderId=$waybill').toString();
    final addressMap = _order['deliveryAddress'] as Map<String, dynamic>?;

    final steps = [
      {'title': 'Order Placed',        'desc': 'Your order has been received.',             'time': 'Step 1'},
      {'title': 'Printing & Quality', 'desc': 'Kechi high-resolution poster print in progress.', 'time': 'Step 2'},
      {'title': 'Shipped & In Transit','desc': 'Handed over to $courierPartner.',          'time': 'Step 3'},
      {'title': 'Out for Delivery',    'desc': 'Shadowfax rider is out for delivery.',      'time': 'Step 4'},
      {'title': 'Delivered',           'desc': 'Package delivered to recipient.',            'time': 'Step 5'},
    ];

    int currentStepIndex = 1;
    final sLower = status.toLowerCase();
    if (sLower == 'confirmed') currentStepIndex = 1;
    if (sLower == 'processing') currentStepIndex = 2;
    if (sLower == 'shipped') currentStepIndex = 3;
    if (sLower == 'delivered') currentStepIndex = 4;
    if (sLower == 'cancelled') currentStepIndex = -1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back();
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        title: const Text(
          "Order Tracking",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracking Code Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFC9A227)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B0000).withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "COURIER PARTNER",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            courierPartner,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "WAYBILL / TRACKING NUMBER",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                waybill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: waybill));
                            Get.snackbar(
                              "Copied!",
                              "Tracking number copied to clipboard",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.black87,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Web Tracking External Link
            if (sLower != 'cancelled') ...[
              GestureDetector(
                onTap: () {
                  Get.bottomSheet(
                    Container(
                      padding: const EdgeInsets.all(20),
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
                              const Icon(Icons.open_in_new_rounded, color: Color(0xFF8B0000)),
                              const SizedBox(width: 8),
                              const Text(
                                "Live Shadowfax Tracking",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tracking URL: $trackingUrl",
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: trackingUrl));
                                Get.back();
                                Get.snackbar(
                                  "Tracking Link Copied",
                                  "Paste into your browser to track live Shadowfax rider",
                                  backgroundColor: Colors.black87,
                                  colorText: Colors.white,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B0000),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Copy Tracking Link", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.radar_rounded, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            "Live Courier Tracking Link",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(0.3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Step Progress Timeline
            const Text(
              "Delivery Timeline",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: sLower == 'cancelled'
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This order has been cancelled.",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: steps.length,
                      itemBuilder: (context, idx) {
                        final step = steps[idx];
                        final isCompleted = idx <= currentStepIndex;
                        final isCurrent = idx == currentStepIndex;
                        final isLast = idx == steps.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline Node
                              Column(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? const Color(0xFF8B0000)
                                          : Colors.grey.shade100,
                                      border: isCurrent
                                          ? Border.all(color: const Color(0xFFC9A227), width: 3)
                                          : null,
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                          : Text(
                                              "${idx + 1}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black.withOpacity(0.4),
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2.5,
                                        color: idx < currentStepIndex
                                            ? const Color(0xFF8B0000)
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // Text Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['title']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                          color: isCompleted ? Colors.black87 : Colors.black38,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step['desc']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // Delivery Address Card
            if (addressMap != null) ...[
              const Text(
                "Shipping Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF8B0000), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressMap['name'] ?? 'Recipient',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${addressMap['addressLine'] ?? ''}, ${addressMap['city'] ?? ''} - ${addressMap['pincode'] ?? ''}",
                            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 2-Hour Cancellation Window / Policy Info
            if (sLower == 'pending') ...[
              Builder(
                builder: (context) {
                  DateTime? orderTime;
                  try {
                    if (_order['createdAt'] != null) {
                      orderTime = DateTime.parse(_order['createdAt'].toString());
                    }
                  } catch (_) {}

                  final diffHours = orderTime != null
                      ? DateTime.now().difference(orderTime).inHours
                      : 0;

                  final canCancel = diffHours < 2;

                  if (canCancel) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 16, color: Colors.red.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Free cancellation available within 2 hours of order placement.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Cancel Order?'),
                                    content: const Text('Are you sure you want to cancel this poster order?'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Keep Order')),
                                      ElevatedButton(
                                        onPressed: () => Get.back(result: true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final orderId = _order['orderId'] ?? _order['_id'];
                                  if (orderId != null) {
                                    await OrderController.to.cancelOrder(orderId.toString());
                                    setState(() {
                                      _order['status'] = 'Cancelled';
                                    });
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Cancel Order', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Order is now in high-definition printing production. Custom items cannot be cancelled after 2 hours.",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ] else if (sLower == 'delivered') ...[
              // Delivered State with In-App Defect / Replacement Request
              Builder(
                builder: (context) {
                  final rep = _order['replacementRequest'] as Map<String, dynamic>?;
                  final repStatus = rep?['status']?.toString();

                  if (repStatus != null && repStatus != 'None') {
                    final rLower = repStatus.toLowerCase();

                    // If rejected
                    if (rLower == 'rejected') {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cancel_rounded, size: 20, color: Colors.red.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Replacement Request Declined",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rep?['adminNotes']?.toString() ??
                                  "The reported issue does not qualify for a replacement. For questions, contact support.kechi@gmail.com.",
                              style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                            ),
                          ],
                        ),
                      );
                    }

                    // Active replacement tracking lifecycle
                    final repSteps = [
                      {'title': 'Defect Reported', 'desc': 'Photos submitted & under review.'},
                      {'title': 'Approved & Printing', 'desc': 'Free reprint in progress.'},
                      {'title': 'Dispatched & In Transit', 'desc': 'Courier tracking active.'},
                      {'title': 'Replacement Delivered', 'desc': 'Package delivered to recipient.'},
                    ];

                    int repCurrentStep = 0;
                    if (rLower == 'approved' || rLower == 'in production') repCurrentStep = 1;
                    if (rLower == 'shipped') repCurrentStep = 2;
                    if (rLower == 'delivered' || rLower == 'completed') repCurrentStep = 3;

                    final repWaybill = rep?['waybillNumber']?.toString();
                    final repCourier = rep?['courierPartner']?.toString() ?? 'Shadowfax Express';
                    final repTrackingUrl = rep?['trackingUrl']?.toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B0000).withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B0000).withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.sync_rounded, color: Color(0xFF8B0000), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Replacement Order",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "100% Free Reprint Guarantee",
                                        style: TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: repCurrentStep == 3
                                      ? Colors.green.shade100
                                      : const Color(0xFF8B0000).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  repStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: repCurrentStep == 3 ? Colors.green.shade900 : const Color(0xFF8B0000),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Customer's issue reason
                          if (rep?['reason'] != null && rep!['reason'].toString().isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                "Defect Note: \"${rep['reason']}\"",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Courier & Waybill for replacement (if shipped)
                          if (repWaybill != null && repWaybill.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "COURIER: $repCourier",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.5)),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: repWaybill));
                                          Get.snackbar("Copied!", "Replacement tracking code copied");
                                        },
                                        child: const Row(
                                          children: [
                                            Icon(Icons.copy_rounded, size: 13, color: Color(0xFF8B0000)),
                                            SizedBox(width: 4),
                                            Text("Copy AWB", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B0000))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "AWB: $repWaybill",
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'monospace'),
                                  ),
                                  if (repTrackingUrl != null && repTrackingUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: repTrackingUrl));
                                        Get.snackbar("Link Copied", "Paste in browser to track live replacement rider");
                                      },
                                      child: const Text(
                                        "Track Replacement Live →",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Replacement Timeline steps
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: repSteps.length,
                            itemBuilder: (context, idx) {
                              final st = repSteps[idx];
                              final isDone = idx <= repCurrentStep;
                              final isCurrent = idx == repCurrentStep;
                              final isLast = idx == repSteps.length - 1;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDone ? const Color(0xFF8B0000) : Colors.grey.shade200,
                                          ),
                                          child: Center(
                                            child: isDone
                                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                                : Text("${idx + 1}", style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: idx < repCurrentStep ? const Color(0xFF8B0000) : Colors.grey.shade200,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              st['title']!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                                color: isDone ? Colors.black87 : Colors.black38,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              st['desc']!,
                                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  // Check 24 hours window
                  DateTime? delDate;
                  try {
                    if (_order['deliveredAt'] != null) {
                      delDate = DateTime.parse(_order['deliveredAt'].toString());
                    } else if (_order['updatedAt'] != null) {
                      delDate = DateTime.parse(_order['updatedAt'].toString());
                    }
                  } catch (_) {}

                  final diffHours = delDate != null ? DateTime.now().difference(delDate).inHours : 0;
                  final isWithin24Hours = diffHours < 24;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified_rounded, size: 20, color: Colors.green.shade700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Order Delivered",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  Text(
                                    isWithin24Hours
                                        ? "Defective or damaged print? 100% Free Replacement available for 24h."
                                        : "Delivered successfully. Thank you for shopping with Kechi!",
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isWithin24Hours) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openReplacementSheet,
                              icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              label: const Text(
                                "Report Defect / Free Replacement",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B0000),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            // Support & Contact Button
            GestureDetector(
              onTap: () {
                Get.bottomSheet(
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kechi Customer Support",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Have a question about your order or need a free replacement for a defective print?",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.email_outlined, color: Color(0xFF8B0000)),
                              SizedBox(width: 10),
                              Text(
                                "support.kechi@gmail.com",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "• Operating hours: Mon - Sat, 10 AM - 7 PM\n• Please mention your Order ID for faster resolution.",
                          style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.headset_mic_outlined, color: Color(0xFF8B0000), size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Contact Kechi Support",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B0000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

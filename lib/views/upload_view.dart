import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poster_application/controller/cart_controller.dart';
import 'package:poster_application/controller/upload_controller.dart';
import '../themes/app_colors.dart';

class UploadView extends StatelessWidget {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UploadController>()) Get.put(UploadController());
    final ctrl = UploadController.to;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Header(),
                  const SizedBox(height: 28),
                  _StepLabel(number: '01', label: 'Upload Your Poster'),
                  const SizedBox(height: 14),
                  _ImageUploadSection(ctrl: ctrl),
                  const SizedBox(height: 30),
                  _StepLabel(number: '02', label: 'Choose Size'),
                  const SizedBox(height: 14),
                  _SizePicker(ctrl: ctrl),
                  const SizedBox(height: 30),
                  _StepLabel(number: '03', label: 'Select Quantity'),
                  const SizedBox(height: 14),
                  _QuantityPicker(ctrl: ctrl),
                  const SizedBox(height: 30),
                  _StepLabel(number: '04', label: 'Order Summary'),
                  const SizedBox(height: 14),
                  _OrderSummary(ctrl: ctrl),
                  const SizedBox(height: 28),
                  _AddToCartButton(ctrl: ctrl),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // back button — same style as notification button in HomeView
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // title uses same ShaderMask + logoGrad as "postly." in HomeView
        ShaderMask(
          shaderCallback: (b) =>
              const LinearGradient(colors: AppColors.logoGrad).createShader(b),
          child: Text(
            "Print Poster",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGrad[0],
            ),
          ),
        ),
        const Spacer(),
        // cart badge — notification icon style from HomeView
        Obx(() {
          final count = CartController.to.totalItems;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGrad,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ─── STEP LABEL ───────────────────────────────────────────────────────────────
// Matches _sectionTitle() style from HomeView + gradient number accent
class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: AppColors.primaryGrad,
          ).createShader(b),
          child: const Text(
            // number is small gradient accent beside the black section title
            '',   // placeholder — actual text below via Stack trick
            style: TextStyle(fontSize: 0),
          ),
        ),
        // gradient step number
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: AppColors.primaryGrad,
          ).createShader(b),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,   // overridden by ShaderMask
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // section title — same as _sectionTitle() in HomeView
        Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// ─── IMAGE UPLOAD ─────────────────────────────────────────────────────────────
// Styled like _buildUploadCard() in HomeView — gradient container, black icons
class _ImageUploadSection extends StatelessWidget {
  final UploadController ctrl;
  const _ImageUploadSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final image = ctrl.pickedImage.value;

      return Column(
        children: [
          GestureDetector(
            onTap: () => _showSourcePicker(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                // when no image: same gradient as _buildUploadCard
                gradient: image == null
                    ? const LinearGradient(colors: AppColors.primaryGrad)
                    : null,
                image: image != null
                    ? DecorationImage(
                        image: FileImage(image),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // icon circle — same as _buildUploadCard icon circle
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.black,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Upload Poster",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Gallery  •  Camera",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: GestureDetector(
                          onTap: () => _showSourcePicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              // same black overlay used in HomeView cards
                              color: Colors.black.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined,
                                    color: Colors.white, size: 15),
                                SizedBox(width: 5),
                                Text(
                                  "Change",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // upload progress bar
          if (ctrl.isUploading.value) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Obx(
                      () => LinearProgressIndicator(
                        value: ctrl.uploadProgress.value,
                        // same black.withOpacity as HomeView overlays
                        backgroundColor: Colors.black.withOpacity(.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGrad[0],
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => Text(
                    '${(ctrl.uploadProgress.value * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.black.withOpacity(.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // bg matches AppColors.bg feel — white sheet on light background
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Source",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SourceTile(
                    icon: Icons.photo_library_outlined,
                    label: "Gallery",
                    onTap: () {
                      Get.back();
                      ctrl.pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SourceTile(
                    icon: Icons.camera_alt_outlined,
                    label: "Camera",
                    onTap: () {
                      Get.back();
                      ctrl.pickImage(ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          // same .05 black overlay used throughout HomeView
          color: Colors.black.withOpacity(.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(.7),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SIZE PICKER ──────────────────────────────────────────────────────────────
// Selected tile: primaryGrad (same as _buildUploadCard)
// Unselected tile: Colors.black.withOpacity(.05) (same as notification button)
class _SizePicker extends StatelessWidget {
  final UploadController ctrl;
  const _SizePicker({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: List.generate(ctrl.sizes.length, (i) {
          final size = ctrl.sizes[i];
          final isSelected = ctrl.selectedSizeIndex.value == i;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i < ctrl.sizes.length - 1 ? 12 : 0,
              ),
              child: GestureDetector(
                onTap: () => ctrl.selectedSizeIndex.value = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isSelected
                        ? const LinearGradient(colors: AppColors.primaryGrad)
                        : null,
                    color: isSelected ? null : Colors.black.withOpacity(.05),
                  ),
                  child: Column(
                    children: [
                      Text(
                        size.label,
                        style: TextStyle(
                          // selected: white (on gradient); unselected: black
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        size.dimensions,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black.withOpacity(.45),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${size.price.toInt()}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black.withOpacity(.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── QUANTITY PICKER ──────────────────────────────────────────────────────────
class _QuantityPicker extends StatelessWidget {
  final UploadController ctrl;
  const _QuantityPicker({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Number of copies",
            style: TextStyle(
              color: Colors.black.withOpacity(.7),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              _QtyButton(icon: Icons.remove, onTap: ctrl.decrement),
              const SizedBox(width: 20),
              Obx(
                () => Text(
                  '${ctrl.quantity.value}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _QtyButton(icon: Icons.add, onTap: ctrl.increment),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.primaryGrad),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.remove, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── ORDER SUMMARY ────────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final UploadController ctrl;
  const _OrderSummary({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final size = ctrl.selectedSize;
      final qty = ctrl.quantity.value;
      final total = ctrl.totalPrice;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(.05),
        ),
        child: Column(
          children: [
            _SummaryRow(label: 'Size', value: '${size.label} (${size.dimensions})'),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Price per copy', value: '₹${size.price.toInt()}'),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Quantity', value: '× $qty'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: Colors.black.withOpacity(.1), thickness: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // total amount: same ShaderMask + primaryGrad as hero text
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: AppColors.primaryGrad,
                  ).createShader(b),
                  child: Text(
                    '₹${total.toInt()}',
                    style: const TextStyle(
                      color: Colors.white, // overridden by ShaderMask
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(.45),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── ADD TO CART BUTTON ───────────────────────────────────────────────────────
// Full-width gradient button — same as _buildUploadCard gradient container
class _AddToCartButton extends StatelessWidget {
  final UploadController ctrl;
  const _AddToCartButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = ctrl.isAddingToCart.value;
      return GestureDetector(
        onTap: loading ? null : ctrl.addToCart,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: AppColors.primaryGrad),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // icon in a circle — same as _buildUploadCard icon wrapper
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => Text(
                          'Add to Cart  •  ₹${ctrl.totalPrice.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
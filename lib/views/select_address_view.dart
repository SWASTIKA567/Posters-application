import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';
import '../controller/order_controller.dart';
import '../controller/address_controller.dart';
import '../controller/profile_controller.dart';
import '../utils/ncr_helper.dart';
import 'address_view.dart';

class SelectAddressView extends StatelessWidget {
  const SelectAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AddressController>()) {
      Get.put(AddressController());
    }
    final orderCtrl = OrderController.to;
    final addressCtrl = AddressController.to;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Get.back();
                      }
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: AppColors.logoGrad,
                    ).createShader(b),
                    child: const Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ── Address List / Empty State ───────────────────────────────────
            Expanded(
              child: Obx(() {
                final addresses = orderCtrl.savedAddresses;
                final selectedAddress = orderCtrl.deliveryAddress.value;

                if (addresses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_off_outlined,
                              size: 36,
                              color: Colors.black.withOpacity(.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No saved addresses",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please add an address to deliver your posters.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(.4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              addressCtrl.clearFields();
                              addressCtrl.prefillFromProfile();
                              Get.to(() => const AddressView());
                            },
                            icon: const Icon(
                              Icons.add_location_alt_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "Add Address Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final isSelected = selectedAddress?.id == address.id;
                    final isNcr = isNcrRegion(
                      state: address.state,
                      district: address.city,
                      pincode: address.pincode,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black.withOpacity(.07),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withOpacity(.10)
                                : Colors.black.withOpacity(.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            if (!isNcr) {
                              Get.snackbar(
                                'Delivery Coming Soon',
                                'We currently deliver only across the Delhi-NCR region. We are coming to ${address.city} soon!',
                                backgroundColor: const Color(0xFF8B0000),
                                colorText: Colors.white,
                                duration: const Duration(seconds: 4),
                                snackPosition: SnackPosition.BOTTOM,
                                margin: const EdgeInsets.all(16),
                                borderRadius: 14,
                                icon: const Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                ),
                              );
                              return;
                            }

                            await orderCtrl.setAddress(address);
                            if (Get.isRegistered<ProfileController>()) {
                              ProfileController.to.setSelectedAddress(address);
                            }
                            Get.snackbar(
                              '✅ Address Selected',
                              '${address.name}\'s address selected for delivery & profile.',
                              duration: const Duration(milliseconds: 1600),
                              backgroundColor: const Color(0xFF10B981),
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 14,
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 350),
                            );
                            Get.back();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Radio circle ──────────────────────────
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.black38,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // ── Address detail column ─────────────────
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Line 1: Full name (no overflow)
                                      Text(
                                        address.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 5),

                                      // Line 2: Badges row
                                      Row(
                                        children: [
                                          _Badge(
                                            label: isNcr
                                                ? "NCR Area"
                                                : "Coming Soon",
                                            color: isNcr
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF8B0000),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 6),
                                            _Badge(
                                              label: "✓ Selected",
                                              color: const Color(0xFF10B981),
                                              bordered: true,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Line 3: Phone
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined,
                                              size: 13,
                                              color:
                                                  Colors.black.withOpacity(.4)),
                                          const SizedBox(width: 5),
                                          Text(
                                            address.phone,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.black
                                                  .withOpacity(.55),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Divider
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Colors.black.withOpacity(.07),
                                      ),
                                      const SizedBox(height: 8),

                                      // Line 4: House/Flat/Street
                                      _AddressLine(
                                        icon: Icons.home_outlined,
                                        text: address.addressLine,
                                      ),
                                      const SizedBox(height: 4),

                                      // Line 5: City, State
                                      _AddressLine(
                                        icon: Icons.location_city_outlined,
                                        text:
                                            '${address.city}, ${address.state}',
                                      ),
                                      const SizedBox(height: 4),

                                      // Line 6: Pincode
                                      _AddressLine(
                                        icon: Icons.pin_drop_outlined,
                                        text: address.pincode,
                                        bold: true,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // ── Delete button ─────────────────────────
                                GestureDetector(
                                  onTap: () => _confirmDelete(
                                    context,
                                    addressCtrl,
                                    address,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // ── Add Other Address bottom button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: () {
                  addressCtrl.clearFields();
                  addressCtrl.prefillFromProfile();
                  Get.to(() => const AddressView());
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGrad,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Add Other Address",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AddressController ctrl,
    UserAddress address,
  ) {
    if (address.id == null) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Address?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this saved address?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.deleteAddress(address.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Small badge chip ──────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool bordered;

  const _Badge({
    required this.label,
    required this.color,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(6),
        border: bordered ? Border.all(color: color.withOpacity(.35)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── One structured address row ────────────────────────────────────────────────
class _AddressLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;

  const _AddressLine({
    required this.icon,
    required this.text,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(
            icon,
            size: 13,
            color: Colors.black.withOpacity(.38),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(bold ? .8 : .6),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

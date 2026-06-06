import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../themes/app_colors.dart';
import 'address_view.dart';
import '../controller/order_controller.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = OrderController.to;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
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
                      "My Cart",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGrad,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ctrl.totalItems} items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                if (ctrl.items.isEmpty) {
                  return Center(
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
                            Icons.shopping_bag_outlined,
                            size: 36,
                            color: Colors.black.withOpacity(.3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Your cart is empty",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(.4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Upload a poster to get started",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // ── Cart Items ─────────────────────────────────────────
                    ...List.generate(ctrl.items.length, (i) {
                      final item = ctrl.items[i];
                      return _CartItemCard(item: item, index: i, ctrl: ctrl);
                    }),

                    const SizedBox(height: 24),

                    // ── Delivery Address Section ───────────────────────────
                    _AddressSection(ctrl: ctrl),

                    const SizedBox(height: 24),

                    // ── Price Summary ──────────────────────────────────────
                    _PriceSummary(ctrl: ctrl),

                    const SizedBox(height: 24),

                    // ── Place Order Button ─────────────────────────────────
                    _PlaceOrderButton(ctrl: ctrl),

                    const SizedBox(height: 32),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CART ITEM CARD ───────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final int index;
  final OrderController ctrl;

  const _CartItemCard({
    required this.item,
    required this.index,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Poster thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.black.withOpacity(.08),
                child: const Icon(Icons.image_outlined, color: Colors.black38),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGrad,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.size,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ctrl.removeItem(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Qty: ${item.quantity} ${item.quantity == 1 ? 'copy' : 'copies'}',
                  style: TextStyle(
                    color: Colors.black.withOpacity(.55),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: AppColors.primaryGrad,
                  ).createShader(b),
                  child: Text(
                    '₹${item.totalPrice.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADDRESS SECTION ──────────────────────────────────────────────────────────
class _AddressSection extends StatelessWidget {
  final OrderController ctrl;
  const _AddressSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final address = ctrl.deliveryAddress.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: AppColors.primaryGrad,
                  ).createShader(b),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Delivery Address",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.to(() => const AddressView()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGrad,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      address == null ? 'Add' : 'Change',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (address != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Text(
                address.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address.phone,
                style: TextStyle(
                  color: Colors.black.withOpacity(.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                address.fullAddress,
                style: TextStyle(
                  color: Colors.black.withOpacity(.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                "No address added yet. Tap 'Add' to enter your delivery address.",
                style: TextStyle(
                  color: Colors.black.withOpacity(.4),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ─── PRICE SUMMARY ────────────────────────────────────────────────────────────
class _PriceSummary extends StatelessWidget {
  final OrderController ctrl;
  const _PriceSummary({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _Row(label: 'Subtotal', value: '₹${ctrl.subtotal.toInt()}'),
            const SizedBox(height: 12),
            _Row(
              label: 'Delivery Charges',
              value: '₹${OrderController.deliveryCharge.toInt()}',
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'Payment Method',
              value: 'Cash on Delivery',
              valueColor: const Color(0xFF00796B),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                color: Colors.black.withOpacity(.08),
                thickness: 1,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: AppColors.primaryGrad,
                  ).createShader(b),
                  child: Text(
                    '₹${ctrl.grandTotal.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.black.withOpacity(.45), fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── PLACE ORDER BUTTON ───────────────────────────────────────────────────────
class _PlaceOrderButton extends StatelessWidget {
  final OrderController ctrl;
  const _PlaceOrderButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = ctrl.isPlacingOrder.value;
      return GestureDetector(
        onTap: loading ? null : ctrl.placeOrder,
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
                : Obx(
                    () => Text(
                      'Place Order  •  ₹${ctrl.grandTotal.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/cart_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final VoidCallback onCenterTap;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color teal = Color(0xFF00796B);
  static const Color orange = Color(0xFFFF5722);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(.12),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home_rounded, title: "Home", index: 0),

              _navItem(
                icon: Icons.inventory_2_outlined,
                title: "Cart",
                index: 1,
                iconWidget: Obx(() {
                  final count = CartController.to.totalItems;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 24,
                        color: selectedIndex == 1 ? primaryRed : Colors.black,
                      ),

                      if (count > 0)
                        Positioned(
                          top: -5,
                          right: -8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),

              const SizedBox(width: 80),

              _navItem(
                icon: Icons.favorite_border_rounded,
                title: "Wishlist",
                index: 2,
              ),

              _navItem(
                icon: Icons.person_outline_rounded,
                title: "Profile",
                index: 3,
              ),
            ],
          ),

          Positioned(
            top: -25,
            child: GestureDetector(
              onTap: onCenterTap,

              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00796B),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00796B).withOpacity(.30),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.print_rounded, color: Colors.white, size: 24),
                    SizedBox(height: 2),
                    Text(
                      "Print",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? primaryRed : Colors.black,
                ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? primaryRed : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart';

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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final navHeight = 62.0 + bottomPad;

    return Container(
      height: navHeight,
      padding: EdgeInsets.only(bottom: bottomPad > 0 ? bottomPad * 0.75 : 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Row(
            children: [
              Expanded(
                child: _navItem(
                  icon: Icons.home_rounded,
                  title: "Home",
                  index: 0,
                ),
              ),
              Expanded(
                child: _navItem(
                  icon: Icons.inventory_2_outlined,
                  title: "Cart",
                  index: 1,
                  iconWidget: Obx(() {
                    final count = OrderController.to.totalItems;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 24,
                          color: selectedIndex == 1 ? primaryRed : const Color(0xFF222222),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -5,
                            right: -8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: primaryRed,
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
              ),

              // Responsive center gap for floating Print button
              const Expanded(
                child: SizedBox(),
              ),

              Expanded(
                child: _navItem(
                  icon: Icons.favorite_border_rounded,
                  title: "Wishlist",
                  index: 2,
                ),
              ),
              Expanded(
                child: _navItem(
                  icon: Icons.person_outline_rounded,
                  title: "Profile",
                  index: 3,
                ),
              ),
            ],
          ),

          // Elevated Center Floating Print Button
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: onCenterTap,
              child: Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00796B),
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00796B).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.print_rounded, color: Colors.white, size: 22),
                    SizedBox(height: 1),
                    Text(
                      "Print",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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

    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? primaryRed : const Color(0xFF333333),
                ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryRed : const Color(0xFF333333),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

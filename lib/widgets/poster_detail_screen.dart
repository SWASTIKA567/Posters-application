import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import '../controller/wishlist_controller.dart';
import '../controller/order_controller.dart';
import '../themes/app_colors.dart';
import '../views/cart_view.dart';

class PosterDetailScreen extends StatefulWidget {
  final String title;
  final String image;
  final String price; // e.g. "₹49" — treated as the A4 base price

  const PosterDetailScreen({
    super.key,
    required this.title,
    required this.image,
    required this.price,
  });

  @override
  State<PosterDetailScreen> createState() => _PosterDetailScreenState();
}

class _PosterDetailScreenState extends State<PosterDetailScreen> {
  // Available sizes
  static const List<String> _sizes = ['A5', 'A4', 'A3'];

  // Selected size — default A4
  String _selectedSize = 'A4';

  /// Parses "₹49" → 49.0  (this is the A4 base price)
  double get _basePrice =>
      double.tryParse(widget.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

  /// Price multiplier per size
  double _multiplierFor(String size) {
    switch (size) {
      case 'A5':
        return 0.75; // cheaper — smaller
      case 'A4':
        return 1.0;
      case 'A3':
        return 1.5; // bigger — pricier
      default:
        return 1.0;
    }
  }

  double get _currentPrice => _basePrice * _multiplierFor(_selectedSize);

  String get _currentPriceFormatted => '₹${_currentPrice.toStringAsFixed(0)}';

  /// Approximate physical dimensions label
  String _dimensionFor(String size) {
    switch (size) {
      case 'A5':
        return '148 × 210 mm';
      case 'A4':
        return '210 × 297 mm';
      case 'A3':
        return '297 × 420 mm';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistCtrl = WishlistController.to;
    final orderCtrl = OrderController.to;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            // ── TOP: IMAGE (55% of screen) ──────────────────────────────
            Expanded(
              flex: 65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero image
                  Hero(
                    tag: 'poster_${widget.title}',
                    child: Image.asset(widget.image, fit: BoxFit.cover),
                  ),

                  // Top gradient for back/wishlist button legibility
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topPad + 70,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.45),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Back button
                  Positioned(
                    top: topPad + 10,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF1A1A1A),
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Wishlist button — top right
                  Positioned(
                    top: topPad + 10,
                    right: 16,
                    child: Obx(() {
                      final isLiked = wishlistCtrl.isWishlisted(widget.title);
                      return GestureDetector(
                        onTap: () async {
                          if (isLiked) {
                            final item = wishlistCtrl.wishlist.firstWhereOrNull(
                              (e) => e.title == widget.title,
                            );
                            if (item != null) {
                              await wishlistCtrl.removeWishlist(item.docId);
                            }
                          } else {
                            await wishlistCtrl.addToWishlist(
                              title: widget.title,
                              image: widget.image,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLiked
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: isLiked
                                    ? AppColors.primary.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ── BOTTOM: INFO PANEL (45% of screen) ─────────────────────
            Expanded(
              flex: 35,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 16),
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title + Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Animated price — gradient shader
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: ShaderMask(
                            key: ValueKey(_currentPriceFormatted),
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF00796B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              _currentPriceFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Text(
                      'High-quality print  •  ${_dimensionFor(_selectedSize)}',
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── SIZE SELECTOR ────────────────────────────────────
                    const Text(
                      'Select Size',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: _sizes.map((size) {
                        final isSelected = size == _selectedSize;
                        final sizePrice = (_basePrice * _multiplierFor(size))
                            .toStringAsFixed(0);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSize = size),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              margin: EdgeInsets.only(
                                right: size != _sizes.last ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: AppColors.primaryGrad,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected ? null : Colors.white,
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFE8E8E8),
                                        width: 1.5,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.30,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    size,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹$sizePrice',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.85)
                                          : const Color(0xFF9E9E9E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    // ── ADD TO ORDER BUTTON ───────────────────────────
                    Obx(() {
                      // Check if this poster (same image AND same size) is already in cart
                      final inOrder = orderCtrl.items.any(
                        (e) =>
                            e.imageUrl == widget.image &&
                            e.size == _selectedSize,
                      );

                      return GestureDetector(
                        onTap: () {
                          if (!inOrder) {
                            orderCtrl.addItem(
                              CartItem(
                                imageUrl: widget.image,
                                size: _selectedSize,
                                quantity: 1,
                                totalPrice: _currentPrice,
                                addedAt: DateTime.now(),
                              ),
                            );
                            Get.snackbar(
                              '',
                              '',
                              titleText: const Text(
                                'Added to Order 🛒',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              messageText: Text(
                                '${widget.title}  •  $_selectedSize  •  $_currentPriceFormatted',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              backgroundColor: const Color(0xFF1A1A1A),
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 14,
                              duration: const Duration(seconds: 2),
                            );
                          } else {
                            Get.to(() => const CartView());
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: inOrder
                                ? null
                                : const LinearGradient(
                                    colors: AppColors.primaryGrad,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: inOrder ? Colors.white : null,
                            border: inOrder
                                ? Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 1.5,
                                  )
                                : null,
                            boxShadow: inOrder
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                inOrder
                                    ? Icons.shopping_cart_rounded
                                    : Icons.add_shopping_cart_rounded,
                                color: inOrder
                                    ? AppColors.primary
                                    : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                inOrder ? 'Go to Orders' : 'Add to Order',
                                style: TextStyle(
                                  color: inOrder
                                      ? AppColors.primary
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

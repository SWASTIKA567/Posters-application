import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';
import '../controller/address_controller.dart';

class AddressView extends StatelessWidget {
  const AddressView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AddressController>()) Get.put(AddressController());
    final ctrl = AddressController.to;

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
                  // Header
                  Row(
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
                            border: Border.all(
                              color: Colors.black.withOpacity(.08),
                            ),
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
                      const SizedBox(width: 16),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: AppColors.logoGrad,
                        ).createShader(b),
                        child: const Text(
                          "Delivery Address",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // NCR Region Delivery Notice Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00796B).withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.local_shipping_rounded,
                          size: 20,
                          color: Color(0xFF00796B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Delhi-NCR Service Area",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "We currently deliver exclusively across the whole region of Delhi-NCR.",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black.withOpacity(0.65),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Form(
                    key: ctrl.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormField(
                          controller: ctrl.nameCtrl,
                          label: "Full Name",
                          hint: "e.g. Rahul Sharma",
                          icon: Icons.person_outline_rounded,
                          validator: (v) =>
                              v!.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        _FormField(
                          controller: ctrl.phoneCtrl,
                          label: "Phone Number",
                          hint: "10-digit mobile number",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (v) => v!.length != 10
                              ? 'Enter a valid 10-digit number'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Pincode with Auto District & State Lookup
                        Obx(() {
                          final loading = ctrl.isLoadingPincode.value;
                          final isNcr = ctrl.isDeliverableInNcr.value;

                          Widget? suffix;
                          if (loading) {
                            suffix = const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                            );
                          } else if (isNcr == true) {
                            suffix = const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            );
                          } else if (isNcr == false) {
                            suffix = const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFF8B0000),
                              size: 20,
                            );
                          }

                          return _FormField(
                            controller: ctrl.pincodeCtrl,
                            label: "Pincode",
                            hint: "Enter 6-digit Pincode (e.g. 110001, 122001)",
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            suffixIcon: suffix,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: ctrl.onPincodeChanged,
                            validator: (v) => v!.length != 6
                                ? 'Enter a valid 6-digit pincode'
                                : null,
                          );
                        }),

                        // Pincode Status Feedback / NCR Deliverable Info
                        Obx(() {
                          final isNcr = ctrl.isDeliverableInNcr.value;
                          final feedback = ctrl.pincodeFeedback.value;

                          if (feedback.isEmpty && isNcr == null) {
                            return const SizedBox.shrink();
                          }

                          final isSuccess = isNcr == true;

                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : const Color(0xFF8B0000).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSuccess
                                    ? const Color(0xFF10B981).withOpacity(0.3)
                                    : const Color(0xFF8B0000).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSuccess
                                      ? Icons.verified_rounded
                                      : Icons.access_time_rounded,
                                  size: 16,
                                  color: isSuccess
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF8B0000),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isSuccess
                                        ? "✅ $feedback • Delivery available"
                                        : "⏳ $feedback • Delivery coming soon!",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSuccess
                                          ? const Color(0xFF047857)
                                          : const Color(0xFF8B0000),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 16),
                        _FormField(
                          controller: ctrl.addressCtrl,
                          label: "Address (House/Flat, Street, Area)",
                          hint: "House no., Building name, Street",
                          icon: Icons.home_outlined,
                          maxLines: 2,
                          validator: (v) =>
                              v!.isEmpty ? 'Please enter your address' : null,
                        ),
                        const SizedBox(height: 16),

                        // Auto-populated City / District & State
                        Row(
                          children: [
                            Expanded(
                              child: _FormField(
                                controller: ctrl.cityCtrl,
                                label: "District / City",
                                hint: "Enter",
                                icon: Icons.location_city_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter district/city' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _FormField(
                                controller: ctrl.stateCtrl,
                                label: "State",
                                hint: "Enter",
                                icon: Icons.map_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter state' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        Obx(() {
                          final loading = ctrl.isSaving.value;
                          final isNonNcr =
                              ctrl.isDeliverableInNcr.value == false;

                          return GestureDetector(
                            onTap: loading ? null : ctrl.saveAddress,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 62,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: isNonNcr
                                    ? LinearGradient(
                                        colors: [
                                          Colors.grey.shade600,
                                          Colors.grey.shade700,
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: AppColors.primaryGrad,
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isNonNcr
                                                ? Colors.grey
                                                : AppColors.primary)
                                            .withOpacity(.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isNonNcr
                                                ? Icons.access_time_rounded
                                                : Icons.check_circle_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            isNonNcr
                                                ? "Coming Soon to Your Location"
                                                : "Save & Continue",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(.55),
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(.3),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.black.withOpacity(.4),
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.black.withOpacity(.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF00796B),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

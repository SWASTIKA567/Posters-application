import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poster_application/themes/app_colors.dart';
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

                  const SizedBox(height: 28),

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
                          validator: (v) => v!.length != 10
                              ? 'Enter a valid 10-digit number'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _FormField(
                          controller: ctrl.addressCtrl,
                          label: "Address",
                          hint: "House no., Street, Area",
                          icon: Icons.home_outlined,
                          maxLines: 2,
                          validator: (v) =>
                              v!.isEmpty ? 'Please enter your address' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _FormField(
                                controller: ctrl.cityCtrl,
                                label: "City",
                                hint: "e.g. Mumbai",
                                icon: Icons.location_city_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter city' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _FormField(
                                controller: ctrl.stateCtrl,
                                label: "State",
                                hint: "e.g. Maharashtra",
                                icon: Icons.map_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter state' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FormField(
                          controller: ctrl.pincodeCtrl,
                          label: "Pincode",
                          hint: "6-digit pincode",
                          icon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.length != 6
                              ? 'Enter a valid 6-digit pincode'
                              : null,
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        Obx(() {
                          final loading = ctrl.isSaving.value;
                          return GestureDetector(
                            onTap: loading ? null : ctrl.saveAddress,
                            child: Container(
                              height: 62,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: AppColors.primaryGrad,
                                ),
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
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Save & Continue",
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
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
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

// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../controller/profile_controller.dart';
import '../controller/navigation_controller.dart';
import 'login_view.dart' show LoginScreen;
import '../themes/app_colors.dart';
import 'orders_view.dart';
import 'select_address_view.dart';
import 'address_view.dart';
import '../controller/address_controller.dart';
import 'admin_posters_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: true);
    controller.loadProfile();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return CustomScrollView(
          slivers: [
            _buildAppBar(context, controller),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildAvatarSection(controller),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildOrderHistoryCard(),
                        Obx(() {
                          if (!controller.isAdminUser.value) return const SizedBox.shrink();
                          return Column(
                            children: [
                              const SizedBox(height: 12),
                              _buildAdminPortalCard(controller),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                        _buildSection(
                          title: 'Personal info',
                          icon: Icons.person_outline,
                          accentColor: AppColors.primary,
                          children: [
                            _buildFieldRow(
                              icon: Icons.badge_outlined,
                              label: 'Full name',
                              controller: controller.nameCtrl,
                              isEditing: controller.isEditMode.value,
                              accentColor: AppColors.primary,
                            ),
                            _buildFieldRow(
                              icon: Icons.mail_outline,
                              label: 'Email',
                              controller: controller.emailCtrl,
                              isEditing: false,
                              accentColor: AppColors.primary,
                            ),
                            _buildFieldRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              controller: controller.phoneCtrl,
                              isEditing: controller.isEditMode.value,
                              accentColor: AppColors.primary,
                              keyboardType: TextInputType.phone,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDeliveryAddressSection(controller),
                        const SizedBox(height: 16),
                        _buildSaveButton(controller),
                        const SizedBox(height: 14),
                        _buildLegalAndSupportSection(),
                        const SizedBox(height: 14),
                        _buildLogoutCard(),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onLongPress: () => _showSecretAdminLoginDialog(controller),
                            child: const Text(
                              'Kechi • Version 1.0.0',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFCCCCCC),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, ProfileController controller) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Center(
        child: GestureDetector(
          onTap: () => NavigationController.to.handleBack(context),
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
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: AppColors.primaryGrad,
        ).createShader(bounds),
        child: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        Obx(
          () => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: controller.toggleEditMode,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.isEditMode.value
                      ? Icons.close
                      : Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFF0F0F0)),
      ),
    );
  }

  Widget _buildAvatarSection(ProfileController controller) {
    final name = controller.nameCtrl.text;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.primaryGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name.isEmpty ? 'User' : name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            controller.emailCtrl.text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressSection(ProfileController controller) {
    return Obx(() {
      final selected = controller.selectedAddress.value;
      final isEditing = controller.isEditMode.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00796B)),
                  const SizedBox(width: 5),
                  const Text(
                    "DELIVERY ADDRESS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00796B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.to(() => const SelectAddressView()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00796B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected != null ? Icons.swap_horiz_rounded : Icons.add_rounded,
                            size: 14,
                            color: const Color(0xFF00796B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selected != null ? "Change" : "Add",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00796B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (selected != null) ...[
              // Active Selected Address Card
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00796B).withOpacity(0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selected.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                                SizedBox(width: 3),
                                Text(
                                  "Active",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12, color: Colors.black.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            selected.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selected.fullAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.75),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons row: "Change Address" & "+ Add Other Address"
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(() => const SelectAddressView()),
                        icon: const Icon(Icons.check_box_outlined, size: 14, color: Color(0xFF00796B)),
                        label: const Text(
                          "Change Address",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF00796B)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: const Color(0xFF00796B).withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!Get.isRegistered<AddressController>()) Get.put(AddressController());
                          AddressController.to.clearFields();
                          AddressController.to.prefillFromProfile();
                          Get.to(() => const AddressView());
                        },
                        icon: const Icon(Icons.add_location_alt_outlined, size: 14, color: Colors.white),
                        label: const Text(
                          "Add Other",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Empty State
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "No delivery address added yet.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!Get.isRegistered<AddressController>()) Get.put(AddressController());
                        AddressController.to.clearFields();
                        AddressController.to.prefillFromProfile();
                        Get.to(() => const AddressView());
                      },
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        "Add Address",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isEditing) ...[
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _buildFieldRow(
                icon: Icons.home_outlined,
                label: 'Address Line',
                controller: controller.addressCtrl,
                isEditing: true,
                accentColor: const Color(0xFF00796B),
                maxLines: 2,
              ),
              _buildFieldRow(
                icon: Icons.location_city_outlined,
                label: 'City',
                controller: controller.cityCtrl,
                isEditing: true,
                accentColor: const Color(0xFF00796B),
              ),
              _buildFieldRow(
                icon: Icons.map_outlined,
                label: 'State',
                controller: controller.stateCtrl,
                isEditing: true,
                accentColor: const Color(0xFF00796B),
              ),
              _buildFieldRow(
                icon: Icons.pin_outlined,
                label: 'Pincode',
                controller: controller.pincodeCtrl,
                isEditing: true,
                accentColor: const Color(0xFF00796B),
                keyboardType: TextInputType.number,
                isLast: true,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon, size: 13, color: accentColor),
                const SizedBox(width: 5),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isLast = false,
  }) {
    final iconBg = accentColor == AppColors.primary
        ? const Color(0xFFFFF3F0)
        : const Color(0xFFE8F5F0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFF5F5F5), width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF222222),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: label,
                          labelStyle: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 10,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1,
                            ),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFFEEEEEE),
                              width: 0.5,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            controller.text.isEmpty
                                ? 'Not added yet'
                                : controller.text,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: controller.text.isEmpty
                                  ? const Color(0xFFBBBBBB)
                                  : const Color(0xFF222222),
                              fontStyle: controller.text.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ProfileController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGrad),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: controller.isSaving.value
                ? null
                : controller.saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: controller.isSaving.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.to(() => const OrdersView()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'View all your placed poster orders',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFBBBBBB),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPortalCard(ProfileController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E28), Color(0xFF2D1525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (controller.isAdminUnlocked.value) {
              Get.to(() => const AdminPostersView());
            } else {
              _showAdminPasswordPrompt(controller);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Store Manager / Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Obx(() => Icon(
                                controller.isAdminUnlocked.value
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_outline_rounded,
                                color: controller.isAdminUnlocked.value ? Colors.green : Colors.amber,
                                size: 14,
                              )),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Add new posters & categories to catalog',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white54,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminPasswordPrompt(ProfileController controller) {
    final pwdCtrl = TextEditingController();
    final isVerifying = false.obs;
    final errorMsg = ''.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Admin Verification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Admin Password to access Store Manager:',
              style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Admin Password',
                prefixIcon: const Icon(Icons.key_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            Obx(() => errorMsg.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMsg.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isVerifying.value
                  ? null
                  : () async {
                      if (pwdCtrl.text.isEmpty) {
                        errorMsg.value = 'Password cannot be empty';
                        return;
                      }
                      isVerifying.value = true;
                      errorMsg.value = '';

                      final success = await controller.verifyAdminPassword(
                        controller.emailCtrl.text,
                        pwdCtrl.text,
                      );
                      isVerifying.value = false;

                      if (success) {
                        Get.back();
                        Get.to(() => const AdminPostersView());
                      } else {
                        errorMsg.value = 'Invalid password. Access denied.';
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isVerifying.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Unlock', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecretAdminLoginDialog(ProfileController controller) {
    final emailCtrl = TextEditingController(text: controller.emailCtrl.text);
    final pwdCtrl = TextEditingController();
    final isVerifying = false.obs;
    final errorMsg = ''.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Admin Login', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign in to Store Manager Portal:',
              style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Admin Email',
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Admin Password',
                prefixIcon: const Icon(Icons.key_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            Obx(() => errorMsg.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMsg.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isVerifying.value
                  ? null
                  : () async {
                      if (emailCtrl.text.isEmpty || pwdCtrl.text.isEmpty) {
                        errorMsg.value = 'Please enter both email and password';
                        return;
                      }
                      isVerifying.value = true;
                      errorMsg.value = '';

                      final success = await controller.verifyAdminPassword(
                        emailCtrl.text,
                        pwdCtrl.text,
                      );
                      isVerifying.value = false;

                      if (success) {
                        Get.back();
                        Get.to(() => const AdminPostersView());
                      } else {
                        errorMsg.value = 'Invalid admin credentials. Access denied.';
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isVerifying.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Authenticate', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalAndSupportSection() {
    return _buildSection(
      title: 'Legal, Policies & Support',
      icon: Icons.shield_outlined,
      accentColor: AppColors.primary,
      children: [
        _buildPolicyRow(
          icon: Icons.local_shipping_outlined,
          title: 'Shipping & Delivery Policy',
          subtitle: 'Dispatched in 24-48h • ₹39 flat fee (Free on 7+)',
          onTap: () => _showPolicyModal(
            title: 'Shipping & Delivery Policy',
            content: '''
• Courier Partner: We partner with Shadowfax Express for reliable, tracked pan-India delivery.

• Dispatch Timeline: Custom posters are printed, quality inspected, and packaged in rigid protective safety tubes within 24 to 48 hours of order confirmation.

• Delivery Time: Estimated delivery takes 3 to 5 business days depending on destination pincode.

• Shipping Charges: Standard flat delivery fee of ₹39. Orders with 7 or more posters receive 100% FREE Delivery across India.

• Real-Time Tracking: A live Shadowfax AWB tracking code and direct tracking link are provided in the app for every order.
''',
          ),
        ),
        _buildPolicyRow(
          icon: Icons.currency_rupee_rounded,
          title: 'Cancellation & Replacement Policy',
          subtitle: '2-hour free cancellation • Free replacement for defects',
          onTap: () => _showPolicyModal(
            title: 'Cancellation & Replacement Policy',
            content: '''
• 2-Hour Cancellation Window: You can cancel your order directly from the app within 2 hours of placing it. After 2 hours, custom posters automatically enter high-definition printing production and cancellation is locked.

• Personalized Custom Products: Because posters are custom-printed on demand with personalized dimensions and graphics, sales are final once production begins.

• Defective / Damaged Posters (Strict 24-Hour Reporting): In the rare event your poster arrives damaged, bent, or with a printing defect, report it to support.kechi@gmail.com within 24 hours of delivery along with unboxing photos/video. Claims reported after 24 hours of delivery cannot be accepted.

• 100% Free Replacement: For any verified genuine defect or damage, we ship an immediate 100% Free Replacement (Reprint) to your doorstep at zero extra charge. No monetary refunds are issued after delivery.
''',
          ),
        ),
        _buildPolicyRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Awaiting merchant content • Tap to view',
          isGrey: true,
          onTap: () => _showPolicyModal(
            title: 'Privacy Policy',
            content: '''
[Privacy Policy - Awaiting Content Update]

This section is prepared for Kechi Posters Privacy Policy.
Your custom content will be inserted here.
''',
          ),
        ),
        _buildPolicyRow(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          subtitle: 'Awaiting merchant content • Tap to view',
          isGrey: true,
          onTap: () => _showPolicyModal(
            title: 'Terms & Conditions',
            content: '''
[Terms & Conditions - Awaiting Content Update]

This section is prepared for Kechi Posters Terms & Conditions.
Your custom content will be inserted here.
''',
          ),
        ),
        _buildPolicyRow(
          icon: Icons.headset_mic_outlined,
          title: 'Contact & Customer Support',
          subtitle: 'support.kechi@gmail.com • Mon-Sat 10am-7pm',
          isLast: true,
          onTap: () => _showPolicyModal(
            title: 'Contact Us',
            content: '''
• Business Name: Kechi Posters
• Customer Support Email: support.kechi@gmail.com
• Operating Hours: Monday to Saturday, 10:00 AM – 7:00 PM IST
• Response Time: We typically respond to queries within 2 to 4 business hours.
• Grievance Redressal: For any unresolved order concerns, write to us directly at support.kechi@gmail.com with your Order / Tracking ID.
''',
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
    bool isGrey = false,
  }) {
    final iconBg = isGrey ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.08);
    final iconColor = isGrey ? Colors.grey.shade600 : AppColors.primary;
    final titleColor = isGrey ? Colors.grey.shade700 : const Color(0xFF222222);
    final subColor = isGrey ? Colors.grey.shade500 : const Color(0xFF888888);

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                    border: isGrey ? Border.all(color: Colors.grey.shade300, width: 0.8) : null,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          if (isGrey) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Pending Content",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isGrey ? Colors.grey.shade400 : const Color(0xFFCCCCCC),
                  size: 12,
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              indent: 58,
              endIndent: 14,
              color: Color(0xFFF0F0F0),
            ),
        ],
      ),
    );
  }

  void _showPolicyModal({required String title, required String content}) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(height: 12),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF444444),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildLogoutCard() {
    final controller = Get.find<ProfileController>();
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await ApiService.setAuthToken(null);
              Get.offAll(() => const LoginScreen());
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.primary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.shade200, width: 0.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _confirmDeleteAccount(controller),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_forever_rounded, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteAccount(ProfileController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Account?",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          "This will permanently delete your account, saved addresses, cart items, and wishlist. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Delete Permanently", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

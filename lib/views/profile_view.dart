// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/profile_controller.dart';
import '../views/home_view.dart';
import '../themes/app_colors.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

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
            _buildAppBar(controller),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildAvatarSection(controller),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
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
                        _buildSection(
                          title: 'Delivery address',
                          icon: Icons.location_on_outlined,
                          accentColor: const Color(0xFF00796B),
                          children: [
                            _buildFieldRow(
                              icon: Icons.home_outlined,
                              label: 'Address',
                              controller: controller.addressCtrl,
                              isEditing: controller.isEditMode.value,
                              accentColor: const Color(0xFF00796B),
                              maxLines: 2,
                            ),
                            _buildFieldRow(
                              icon: Icons.location_city_outlined,
                              label: 'City',
                              controller: controller.cityCtrl,
                              isEditing: controller.isEditMode.value,
                              accentColor: const Color(0xFF00796B),
                            ),
                            _buildFieldRow(
                              icon: Icons.map_outlined,
                              label: 'State',
                              controller: controller.stateCtrl,
                              isEditing: controller.isEditMode.value,
                              accentColor: const Color(0xFF00796B),
                            ),
                            _buildFieldRow(
                              icon: Icons.pin_outlined,
                              label: 'Pincode',
                              controller: controller.pincodeCtrl,
                              isEditing: controller.isEditMode.value,
                              accentColor: const Color(0xFF00796B),
                              keyboardType: TextInputType.number,
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSaveButton(controller),
                        const SizedBox(height: 12),
                        _buildLogoutCard(),
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

  SliverAppBar _buildAppBar(ProfileController controller) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF555555)),
        onPressed: () => Get.back(),
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

  Widget _buildLogoutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          Get.offAll(() => const HomeView());
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
    );
  }
}

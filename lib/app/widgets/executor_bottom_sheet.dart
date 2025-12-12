import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';

class ExecutorBottomSheet {
  // Warna pastel untuk background kartu (4 warna pertama)
  static final List<Color> _cardBackgroundColors = [
    const Color(0xFFE3F2FD), // Biru muda
    const Color(0xFFFFCDD2), // Merah muda
    const Color(0xFFFFF8E1), // Kuning muda
    const Color(0xFFF3E5F5), // Ungu muda
  ];

  // Warna solid untuk avatar (sesuai dengan background)
  static final List<Color> _avatarColors = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFFE53935), // Red
    const Color(0xFFFFB300), // Yellow/Orange
    const Color(0xFF8E24AA), // Purple
  ];

  static Color _getCardBackgroundColor(int index) {
    return _cardBackgroundColors[index % _cardBackgroundColors.length];
  }

  static Color _getAvatarColor(int index) {
    return _avatarColors[index % _avatarColors.length];
  }

  static Future<List<String>?> pick({
    required List<String> members,
    String allTeamLabel = 'Semua Tim (Gotong Royong)',
  }) {
    final selectedExecutors = <String>[].obs;
    final isAllTeamSelected = false.obs;

    return Get.bottomSheet<List<String>>(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Siapa yang mengerjakan?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih anggota yang mengerjakan tugas ini (bisa lebih dari satu)',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Grid 2 kolom untuk semua anggota (scrollable jika lebih dari 4)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(
                    () => GridView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.8,
                          ),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final bgColor = _getCardBackgroundColor(index);
                        final avatarColor = _getAvatarColor(index);

                        return Obx(() {
                          // Pindahkan perhitungan isSelected ke dalam Obx agar reactive
                          final isSelected = selectedExecutors.contains(member);

                          return InkWell(
                            onTap: () {
                              if (isAllTeamSelected.value) {
                                return; // Disable jika all team selected
                              }

                              if (isSelected) {
                                selectedExecutors.remove(member);
                              } else {
                                selectedExecutors.add(member);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isAllTeamSelected.value
                                    ? Colors.grey[200]
                                    : bgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? avatarColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? avatarColor
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? avatarColor
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    // Avatar Lingkaran
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isAllTeamSelected.value
                                            ? Colors.grey
                                            : avatarColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          member[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Nama User
                                    Expanded(
                                      child: Text(
                                        member,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isAllTeamSelected.value
                                              ? Colors.grey
                                              : avatarColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol All Team (Full Width)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => InkWell(
                    onTap: () {
                      isAllTeamSelected.value = !isAllTeamSelected.value;
                      if (isAllTeamSelected.value) {
                        selectedExecutors.assignAll(members);
                      } else {
                        selectedExecutors.clear();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isAllTeamSelected.value
                            ? const Color(0xFF1A237E).withValues(
                                alpha: 0.8,
                              ) // Biru tua/Dark Navy (selected)
                            : const Color(0xFF1A237E), // Biru tua/Dark Navy
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAllTeamSelected.value
                                ? Icons.check_circle
                                : Icons.people,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            allTeamLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tombol Konfirmasi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => ElevatedButton(
                    onPressed: selectedExecutors.isEmpty
                        ? null
                        : () => Get.back(result: selectedExecutors.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      selectedExecutors.isEmpty
                          ? 'Pilih minimal 1 anggota'
                          : 'Konfirmasi (${selectedExecutors.length} orang)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

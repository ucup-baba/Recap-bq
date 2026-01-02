import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'nalya_checkin_controller.dart';

class NalyaCheckInView extends GetView<NalyaCheckInController> {
  const NalyaCheckInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: Obx(() => _buildQuestionContent(context))),
          _buildNavigationButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      decoration: BoxDecoration(
        gradient: AppColors.getHeaderGradient(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top row with title and close button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hai! Aku Nalya 👋',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Yuk cerita tentang minggu ini!',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Close button
              IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
                tooltip: 'Tutup',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress indicator
          Obx(
            () => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pertanyaan ${controller.currentQuestion.value + 1} dari ${controller.totalQuestions}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${((controller.currentQuestion.value + 1) / controller.totalQuestions * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        (controller.currentQuestion.value + 1) /
                        controller.totalQuestions,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(BuildContext context) {
    // If first time user (no nickname), question 0 is nickname
    if (!controller.hasExistingNickname.value) {
      switch (controller.currentQuestion.value) {
        case 0:
          return _buildNicknameQuestion(context);
        case 1:
          return _buildQuestion1(context);
        case 2:
          return _buildQuestion2(context);
        case 3:
          return _buildQuestion3(context);
        case 4:
          return _buildQuestion4(context);
        case 5:
          return _buildQuestion5(context);
        case 6:
          return _buildQuestion6(context);
        default:
          return const SizedBox();
      }
    }

    // Returning user - regular flow (6 questions)
    switch (controller.currentQuestion.value) {
      case 0:
        return _buildQuestion1(context);
      case 1:
        return _buildQuestion2(context);
      case 2:
        return _buildQuestion3(context);
      case 3:
        return _buildQuestion4(context);
      case 4:
        return _buildQuestion5(context);
      case 5:
        return _buildQuestion6(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildNicknameQuestion(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perkenalan 👋',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hai! Aku Nalya, mau panggil kamu siapa?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nama panggilan ini akan aku gunakan setiap kali menyapa kamu 😊',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (value) => controller.nickname.value = value,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Contoh: Adi, Kak Rahma, dll',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion1(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan 1/6',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gimana perasaanmu hari ini?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 32),
          Obx(
            () => Row(
              children: [
                _buildMoodOption(context, '😊', 'Semangat', 'semangat'),
                const SizedBox(width: 16),
                _buildMoodOption(context, '😐', 'Biasa', 'biasa'),
                const SizedBox(width: 16),
                _buildMoodOption(context, '😔', 'Kurang Fit', 'kurang_fit'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodOption(
    BuildContext context,
    String emoji,
    String label,
    String value,
  ) {
    final isSelected = controller.selectedMood.value == value;
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectMood(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryBlue : context.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion2(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan 2/6',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ada target khusus minggu ini?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (value) => controller.weeklyTarget.value = value,
            decoration: InputDecoration(
              hintText: 'Contoh: Istiqomah Subuh berjamaah',
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion3(BuildContext context) {
    final amalanOptions = [
      {'icon': '🌅', 'label': 'Subuh Tepat Waktu', 'value': 'subuh'},
      {'icon': '🌄', 'label': 'Tahajud', 'value': 'tahajud'},
      {'icon': '☀️', 'label': 'Dhuha', 'value': 'dhuha'},
      {'icon': '💪', 'label': 'Push-up Konsisten', 'value': 'pushup'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan 3/6',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Amalan mana yang mau difokuskan?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih minimal 1, bisa lebih',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Obx(
            () => Column(
              children: amalanOptions
                  .map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAmalanOption(
                        context,
                        option['icon']!,
                        option['label']!,
                        option['value']!,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmalanOption(
    BuildContext context,
    String icon,
    String label,
    String value,
  ) {
    final isSelected = controller.selectedFocusAmalan.contains(value);
    return InkWell(
      onTap: () => controller.toggleFocusAmalan(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primaryBlue)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryBlue : context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion4(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan 4/6',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tantangan terbesar minggu lalu?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (value) => controller.challenges.value = value,
            decoration: InputDecoration(
              hintText: 'Contoh: Susah bangun pagi untuk Subuh',
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion5(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan 5/6',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mau diingatkan jam berapa?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: Get.context!,
                initialTime: TimeOfDay(
                  hour: int.parse(controller.reminderTime.value.split(':')[0]),
                  minute: int.parse(
                    controller.reminderTime.value.split(':')[1],
                  ),
                ),
              );
              if (time != null) {
                controller.reminderTime.value =
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alarm,
                    color: AppColors.primaryBlue,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Obx(
                    () => Text(
                      controller.reminderTime.value,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, color: AppColors.primaryBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion6(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan 6/6 📚',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buku apa yang akan kamu baca minggu ini?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 24),
          if (controller.lastBook != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pekan lalu kamu baca:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${controller.lastBook}" - ${controller.lastBookProgress}/${controller.readingTarget.value} halaman',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildBookOption(
                      context,
                      'Ya, lanjut buku yang sama',
                      true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBookOption(
                      context,
                      'Tidak, ganti buku baru',
                      false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (!controller.continueLastBook.value) ...[
            TextField(
              onChanged: (value) => controller.selectedBook.value = value,
              decoration: InputDecoration(
                labelText: 'Judul Buku',
                hintText: 'Contoh: Atomic Habits',
                prefixIcon: const Icon(Icons.book),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Target halaman minggu ini:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (controller.readingTarget.value > 10) {
                    controller.readingTarget.value -= 10;
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primaryBlue,
              ),
              Obx(
                () => Text(
                  '${controller.readingTarget.value}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const Text(
                ' halaman',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  controller.readingTarget.value += 10;
                },
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookOption(
    BuildContext context,
    String label,
    bool continueBook,
  ) {
    final isSelected = controller.continueLastBook.value == continueBook;
    return InkWell(
      onTap: () => controller.continueLastBook.value = continueBook,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primaryBlue : context.textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (controller.currentQuestion.value > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: controller.previousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ),
          if (controller.currentQuestion.value > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(() {
              final isLastQuestion =
                  controller.currentQuestion.value ==
                  controller.totalQuestions - 1;
              return ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : (controller.canProceed
                          ? (isLastQuestion
                                ? controller.submitCheckIn
                                : controller.nextQuestion)
                          : null),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isLastQuestion ? 'Selesai ✓' : 'Lanjut'),
                          if (!isLastQuestion) const SizedBox(width: 8),
                          if (!isLastQuestion)
                            const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

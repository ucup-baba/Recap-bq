import 'package:get/get.dart';

import '../../data/services/weekend_rotation_service.dart';

class WeekendScheduleController extends GetxController {
  final _rotationService = WeekendRotationService.instance;

  // Current viewing date (Saturday)
  final Rx<DateTime> currentWeekend = DateTime.now().obs;

  // Current schedule
  final Rx<WeekendSchedule?> schedule = Rx<WeekendSchedule?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadCurrentWeekend();
  }

  void _loadCurrentWeekend() {
    final saturday = _rotationService.getSaturdayForDate(DateTime.now());
    currentWeekend.value = saturday;
    schedule.value = _rotationService.getScheduleForDate(saturday);
  }

  void goToPreviousWeekend() {
    final prevSaturday = currentWeekend.value.subtract(const Duration(days: 7));
    currentWeekend.value = prevSaturday;
    schedule.value = _rotationService.getScheduleForDate(prevSaturday);
  }

  void goToNextWeekend() {
    final nextSaturday = currentWeekend.value.add(const Duration(days: 7));
    currentWeekend.value = nextSaturday;
    schedule.value = _rotationService.getScheduleForDate(nextSaturday);
  }

  void goToToday() {
    _loadCurrentWeekend();
  }

  String formatWeekendRange() {
    return _rotationService.formatWeekendRange(currentWeekend.value);
  }

  bool isCurrentWeekend() {
    final today = DateTime.now();
    final thisSaturday = _rotationService.getSaturdayForDate(today);
    return currentWeekend.value.year == thisSaturday.year &&
        currentWeekend.value.month == thisSaturday.month &&
        currentWeekend.value.day == thisSaturday.day;
  }

  String getSlotName(int slotIndex) {
    switch (slotIndex) {
      case 0:
        return 'Sabtu Pagi';
      case 1:
        return 'Sabtu Malam';
      case 2:
        return 'Ahad Pagi';
      case 3:
        return 'Ahad Malam';
      case 4:
        return 'Dapur';
      default:
        return '';
    }
  }

  String getPiketArea(int slotIndex) {
    switch (slotIndex) {
      case 0:
        return 'Halaman';
      case 1:
        return 'Kamar Aula';
      case 2:
        return 'Wudhu / Rongsokan';
      case 3:
        return 'Masjid';
      case 4:
        return 'Dapur';
      default:
        return '';
    }
  }

  bool hasCooking(int slotIndex) {
    return slotIndex < 4;
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/interfaces/ibadah_controller_interface.dart';
import '../data/models/daily_ibadah_model.dart';
import '../data/services/ibadah_tracking_service.dart';
import '../modules/santri_dashboard/santri_dashboard_controller.dart';
import '../modules/admin_ibadah/admin_ibadah_controller.dart';
import '../modules/kedisiplinan_ibadah/kedisiplinan_ibadah_controller.dart';

class SholatWajibCard extends StatelessWidget {
  final DailyIbadahModel? ibadahData;
  final Function(DailyIbadahModel) onUpdate;

  const SholatWajibCard({
    super.key,
    required this.ibadahData,
    required this.onUpdate,
  });

  // Helper method untuk mendapatkan controller yang tersedia
  IbadahControllerInterface _getIbadahController() {
    if (Get.isRegistered<SantriDashboardController>()) {
      return Get.find<SantriDashboardController>();
    } else if (Get.isRegistered<AdminIbadahController>()) {
      return Get.find<AdminIbadahController>();
    } else if (Get.isRegistered<KedisiplinanIbadahController>()) {
      return Get.find<KedisiplinanIbadahController>();
    } else {
      throw Exception('No ibadah controller found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _getIbadahController();
    final service = IbadahTrackingService.instance;

    final Color jamaahColor = Colors.purple.shade400;
    final Color qobliyahColor = Colors.blue.shade400;
    final Color badiyahColor = Colors.deepOrange.shade400;

    final Color defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Get.isDarkMode
                ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
                : [Colors.white, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 4.0,
                  bottom: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sholat Wajib',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber.shade700,
                      ),
                      onPressed: () {
                        controller.showSholatMotivation();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Obx(() {
                final data = controller.todayIbadah();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: _buildSholatItem(
                        context,
                        'ISYA',
                        service,
                        onUpdate,
                        data,
                        defaultTextColor,
                        jamaah: data?.isyaJamaah ?? false,
                        jamaahKey: 'isyaJamaah',
                        jamaahColor: jamaahColor,
                        badiyah: data?.isyaBadiyah ?? false,
                        badiyahKey: 'isyaBadiyah',
                        badiyahColor: badiyahColor,
                      ),
                    ),
                    Flexible(
                      child: _buildSholatItem(
                        context,
                        'SHUBUH',
                        service,
                        onUpdate,
                        data,
                        defaultTextColor,
                        qobliyah: data?.subuhQobliyah ?? false,
                        qobliyahKey: 'subuhQobliyah',
                        qobliyahColor: qobliyahColor,
                        jamaah: data?.subuhJamaah ?? false,
                        jamaahKey: 'subuhJamaah',
                        jamaahColor: jamaahColor,
                      ),
                    ),
                    Flexible(
                      child: _buildSholatItem(
                        context,
                        'DHUHUR',
                        service,
                        onUpdate,
                        data,
                        defaultTextColor,
                        jamaah: data?.dzuhurJamaah ?? false,
                        jamaahKey: 'dzuhurJamaah',
                        jamaahColor: jamaahColor,
                        badiyah: data?.dzuhurBadiyah ?? false,
                        badiyahKey: 'dzuhurBadiyah',
                        badiyahColor: badiyahColor,
                      ),
                    ),
                    Flexible(
                      child: _buildSholatItem(
                        context,
                        'ASHAR',
                        service,
                        onUpdate,
                        data,
                        defaultTextColor,
                        jamaah: data?.asharJamaah ?? false,
                        jamaahKey: 'asharJamaah',
                        jamaahColor: jamaahColor,
                      ),
                    ),
                    Flexible(
                      child: _buildSholatItem(
                        context,
                        'MAGRIB',
                        service,
                        onUpdate,
                        data,
                        defaultTextColor,
                        jamaah: data?.maghribJamaah ?? false,
                        jamaahKey: 'maghribJamaah',
                        jamaahColor: jamaahColor,
                        badiyah: data?.maghribBadiyah ?? false,
                        badiyahKey: 'maghribBadiyah',
                        badiyahColor: badiyahColor,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSholatItem(
    BuildContext context,
    String title,
    IbadahTrackingService service,
    Function(DailyIbadahModel) onUpdate,
    DailyIbadahModel? data,
    Color defaultTextColor, {
    bool? qobliyah,
    String? qobliyahKey,
    Color? qobliyahColor,
    bool? jamaah,
    String? jamaahKey,
    Color? jamaahColor,
    bool? badiyah,
    String? badiyahKey,
    Color? badiyahColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Judul (ISYA, SHUBUH, ...)
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: defaultTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Tombol (Q, J, B)
        Wrap(
          spacing: 3,
          alignment: WrapAlignment.center,
          children: [
            if (qobliyah != null &&
                qobliyahKey != null &&
                qobliyahColor != null)
              _buildSholatButton(
                'Q',
                qobliyah,
                qobliyahKey,
                qobliyahColor,
                defaultTextColor,
                service,
                onUpdate,
                data,
              ),
            if (jamaah != null && jamaahKey != null && jamaahColor != null)
              _buildSholatButton(
                'J',
                jamaah,
                jamaahKey,
                jamaahColor,
                defaultTextColor,
                service,
                onUpdate,
                data,
              ),
            if (badiyah != null && badiyahKey != null && badiyahColor != null)
              _buildSholatButton(
                'B',
                badiyah,
                badiyahKey,
                badiyahColor,
                defaultTextColor,
                service,
                onUpdate,
                data,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSholatButton(
    String label,
    bool isActive,
    String fieldKey,
    Color color,
    Color defaultTextColor,
    IbadahTrackingService service,
    Function(DailyIbadahModel) onUpdate,
    DailyIbadahModel? currentData,
  ) {
    return GestureDetector(
      onTap: () async {
        final newValue = !isActive;
        switch (fieldKey) {
          case 'subuhQobliyah':
            await service.updateSubuhQobliyah(newValue);
            break;
          case 'subuhJamaah':
            await service.updateSubuhJamaah(newValue);
            break;
          case 'dzuhurJamaah':
            await service.updateDzuhurJamaah(newValue);
            break;
          case 'dzuhurBadiyah':
            await service.updateDzuhurBadiyah(newValue);
            break;
          case 'asharJamaah':
            await service.updateAsharJamaah(newValue);
            break;
          case 'maghribJamaah':
            await service.updateMaghribJamaah(newValue);
            break;
          case 'maghribBadiyah':
            await service.updateMaghribBadiyah(newValue);
            break;
          case 'isyaJamaah':
            await service.updateIsyaJamaah(newValue);
            break;
          case 'isyaBadiyah':
            await service.updateIsyaBadiyah(newValue);
            break;
        }
        // Reload data untuk update UI
        final controller = _getIbadahController();
        await controller.loadTodayIbadah();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 28,
        height: 28,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 204)],
                )
              : null,
          color: isActive
              ? null
              : (Get.isDarkMode
                    ? Colors.grey.shade800
                    : const Color(0xFFEFEFEF)),
          borderRadius: BorderRadius.circular(7),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 102),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 13),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : defaultTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

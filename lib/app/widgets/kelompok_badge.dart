import 'package:flutter/material.dart';

class KelompokBadge extends StatelessWidget {
  final int kelompokId;

  const KelompokBadge({
    super.key,
    required this.kelompokId,
  });

  Color _getKelompokColor(int id) {
    switch (id) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getKelompokColor(kelompokId).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getKelompokColor(kelompokId),
          width: 1,
        ),
      ),
      child: Text(
        'Kelompok $kelompokId',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getKelompokColor(kelompokId),
        ),
      ),
    );
  }
}


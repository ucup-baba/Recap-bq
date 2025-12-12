import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ValidationDialog {
  static Future<String?> reject({String title = 'Alasan Penolakan'}) async {
    final noteController = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tuliskan catatan revisi',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Get.back(result: noteController.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    return result;
  }
}

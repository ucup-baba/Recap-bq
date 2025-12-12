import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MemberFormDialog {
  static Future<String?> open({String? initialValue}) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text(initialValue == null ? 'Tambah Anggota' : 'Edit Anggota'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Anggota'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null && result.isEmpty) return null;
    return result;
  }
}

import 'dart:async';

import 'package:get/get.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/kelompok_members_model.dart';
import '../../data/services/firestore_service.dart';
import '../../widgets/member_form_dialog.dart';

class ManageMembersController extends GetxController {
  final _firestore = FirestoreService.instance;

  final kelompokList = List.generate(5, (index) => index + 1);
  final selectedKelompok = 1.obs;
  final members = <String>[].obs;

  StreamSubscription<KelompokMembersModel?>? _membersSubscription;

  @override
  void onInit() {
    super.onInit();
    loadMembers(selectedKelompok.value);
  }

  @override
  void onClose() {
    _membersSubscription?.cancel();
    super.onClose();
  }

  void loadMembers(int kelompokId) {
    selectedKelompok.value = kelompokId;
    _membersSubscription?.cancel();
    _membersSubscription = _firestore
        .watchMembers(kelompokId)
        .listen(
          (KelompokMembersModel? data) {
            members.assignAll(data?.members ?? []);
          },
          onError: (error) {
            Logger.error('Error loading members', error);
            SnackbarHelper.showError(ErrorHandler.getErrorMessage(error));
          },
        );
  }

  Future<void> addMember() async {
    final name = await MemberFormDialog.open();
    if (name == null) return;
    final oldMembers = List<String>.from(members);
    try {
      members.add(name);
      await _firestore.upsertMembers(selectedKelompok.value, members);
      Logger.info('Member added: $name');
      SnackbarHelper.showSuccess('Anggota berhasil ditambahkan');

      // Sync users collection (terpisah, jangan block success message)
      try {
        await _firestore.syncUsersWithMembers(
          selectedKelompok.value,
          members,
          oldMembers,
        );
      } catch (syncError) {
        Logger.error('Error syncing users after add', syncError);
        // Tidak tampilkan error karena data anggota sudah tersimpan
      }
    } catch (e) {
      Logger.error('Error adding member', e);
      members.assignAll(oldMembers); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> editMember(int index) async {
    final name = await MemberFormDialog.open(initialValue: members[index]);
    if (name == null) return;
    final oldName = members[index];
    final oldMembers = List<String>.from(members);
    try {
      members[index] = name;
      await _firestore.upsertMembers(selectedKelompok.value, members);
      Logger.info('Member updated: $oldName -> $name');
      SnackbarHelper.showSuccess('Anggota berhasil diperbarui');

      // Sync users collection (terpisah, jangan block success message)
      try {
        await _firestore.syncUsersWithMembers(
          selectedKelompok.value,
          members,
          oldMembers,
        );
      } catch (syncError) {
        Logger.error('Error syncing users after edit', syncError);
        // Tidak tampilkan error karena data anggota sudah tersimpan
      }
    } catch (e) {
      Logger.error('Error editing member', e);
      members.assignAll(oldMembers); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> deleteMember(int index) async {
    final deletedMember = members[index];
    final oldMembers = List<String>.from(members);
    try {
      members.removeAt(index);
      await _firestore.upsertMembers(selectedKelompok.value, members);
      Logger.info('Member deleted: $deletedMember');
      SnackbarHelper.showSuccess('Anggota berhasil dihapus');

      // Sync users collection (terpisah, jangan block success message)
      try {
        await _firestore.syncUsersWithMembers(
          selectedKelompok.value,
          members,
          oldMembers,
        );
      } catch (syncError) {
        Logger.error('Error syncing users after delete', syncError);
        // Tidak tampilkan error karena data anggota sudah tersimpan
      }
    } catch (e) {
      Logger.error('Error deleting member', e);
      members.assignAll(oldMembers); // Rollback
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }
}

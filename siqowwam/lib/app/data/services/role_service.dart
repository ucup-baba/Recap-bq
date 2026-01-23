import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role_model.dart';
import '../../core/constants/app_constants.dart';

/// Role Service for SIQowwam
/// Handles CRUD operations for roles in Firestore
class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rolesRef =>
      _firestore.collection(AppConstants.rolesCollection);

  /// Get all roles
  Stream<List<RoleModel>> getRolesStream() {
    return _rolesRef
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => RoleModel.fromFirestore(doc)).toList(),
        );
  }

  /// Get all roles (one-time fetch)
  Future<List<RoleModel>> getAllRoles() async {
    final snapshot = await _rolesRef.orderBy('name').get();
    return snapshot.docs.map((doc) => RoleModel.fromFirestore(doc)).toList();
  }

  /// Get role by ID
  Future<RoleModel?> getRoleById(String roleId) async {
    final doc = await _rolesRef.doc(roleId).get();
    if (doc.exists) {
      return RoleModel.fromFirestore(doc);
    }
    return null;
  }

  /// Create new role
  Future<RoleModel> createRole({
    required String name,
    required String iconName,
    required int iconColor,
    required Map<String, List<String>> allowedCategories,
  }) async {
    final docRef = _rolesRef.doc();
    final role = RoleModel(
      id: docRef.id,
      name: name,
      iconName: iconName,
      iconColor: iconColor,
      allowedCategories: allowedCategories,
      createdAt: DateTime.now(),
    );

    await docRef.set(role.toFirestore());
    return role;
  }

  /// Update existing role
  Future<void> updateRole(RoleModel role) async {
    final updatedRole = role.copyWith(updatedAt: DateTime.now());
    await _rolesRef.doc(role.id).update(updatedRole.toFirestore());
  }

  /// Delete role
  Future<void> deleteRole(String roleId) async {
    await _rolesRef.doc(roleId).delete();
  }

  /// Check if role name already exists
  Future<bool> isRoleNameExists(String name, {String? excludeId}) async {
    final query = await _rolesRef.where('name', isEqualTo: name).get();

    if (query.docs.isEmpty) return false;
    if (excludeId != null && query.docs.first.id == excludeId) return false;
    return true;
  }
}

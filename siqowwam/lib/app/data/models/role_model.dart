import 'package:cloud_firestore/cloud_firestore.dart';

/// Role Model for SIQowwam
/// Defines a role with specific expense categories access
class RoleModel {
  final String id;
  final String name;
  final String iconName;
  final int iconColor;
  final Map<String, List<String>>
  allowedCategories; // category -> subcategories
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoleModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.iconColor,
    required this.allowedCategories,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse allowedCategories from Firestore format
    final rawCategories =
        data['allowedCategories'] as Map<String, dynamic>? ?? {};
    final Map<String, List<String>> parsedCategories = {};
    rawCategories.forEach((key, value) {
      if (value is List) {
        parsedCategories[key] = List<String>.from(value);
      }
    });

    return RoleModel(
      id: doc.id,
      name: data['name'] ?? '',
      iconName: data['iconName'] ?? 'category',
      iconColor: data['iconColor'] ?? 0xFF4CAF50,
      allowedCategories: parsedCategories,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconName': iconName,
      'iconColor': iconColor,
      'allowedCategories': allowedCategories,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  RoleModel copyWith({
    String? id,
    String? name,
    String? iconName,
    int? iconColor,
    Map<String, List<String>>? allowedCategories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      iconColor: iconColor ?? this.iconColor,
      allowedCategories: allowedCategories ?? this.allowedCategories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get all allowed category names
  List<String> get allowedCategoryNames => allowedCategories.keys.toList();

  /// Check if a category is allowed
  bool isCategoryAllowed(String category) {
    return allowedCategories.containsKey(category);
  }

  /// Check if a subcategory is allowed within a category
  bool isSubcategoryAllowed(String category, String subcategory) {
    final subs = allowedCategories[category];
    return subs != null && subs.contains(subcategory);
  }

  /// Get formatted categories display string
  String get categoriesDisplayString {
    if (allowedCategories.isEmpty) return 'Tidak ada kategori';
    return allowedCategories.keys.join(', ');
  }
}

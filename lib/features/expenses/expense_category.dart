import '../../core/models/base_model.dart';

class ExpenseCategory extends BaseModel {
  final String name;
  final String? description;

  ExpenseCategory({
    super.id,
    super.cloudId,
    required this.name,
    this.description,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> m) => ExpenseCategory(
    id: m['id'],
    cloudId: m['cloud_id'],
    name: m['name'],
    description: m['description'],
    createdAt: BaseModel.parseDate(m['created_at']),
    updatedAt: BaseModel.parseDate(m['updated_at']),
    isDeleted: (m['is_deleted'] as int) == 1,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'cloud_id': cloudId,
    'name': name,
    'description': description,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': BaseModel.formatDate(createdAt),
    'updated_at': BaseModel.formatDate(updatedAt),
  };

  ExpenseCategory copyWith({
    int? id,
    String? cloudId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => ExpenseCategory(
    id: id ?? this.id,
    cloudId: cloudId ?? this.cloudId,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
}

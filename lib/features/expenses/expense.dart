import '../../core/models/base_model.dart';

class Expense extends BaseModel {
  final int expenseCategoryId;
  final String description;
  final double amount;
  final DateTime date;
  final String? notes;
  // Joined field for display purposes
  final String? categoryName;

  Expense({
    super.id,
    super.cloudId,
    required this.expenseCategoryId,
    required this.description,
    required this.amount,
    required this.date,
    this.notes,
    this.categoryName,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'],
    cloudId: m['cloud_id'],
    expenseCategoryId: m['expense_category_id'],
    description: m['description'] ?? '',
    amount: (m['amount'] as num).toDouble(),
    date: BaseModel.parseDate(m['date']),
    notes: m['notes'],
    categoryName: m['category_name'],
    createdAt: BaseModel.parseDate(m['created_at']),
    updatedAt: BaseModel.parseDate(m['updated_at']),
    isDeleted: (m['is_deleted'] as int) == 1,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'cloud_id': cloudId,
    'expense_category_id': expenseCategoryId,
    'description': description,
    'amount': amount,
    'date': BaseModel.formatDate(date),
    'notes': notes,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': BaseModel.formatDate(createdAt),
    'updated_at': BaseModel.formatDate(updatedAt),
  };

  Expense copyWith({
    int? id,
    String? cloudId,
    int? expenseCategoryId,
    String? description,
    double? amount,
    DateTime? date,
    String? notes,
    String? categoryName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => Expense(
    id: id ?? this.id,
    cloudId: cloudId ?? this.cloudId,
    expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    notes: notes ?? this.notes,
    categoryName: categoryName ?? this.categoryName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
}

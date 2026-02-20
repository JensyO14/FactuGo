import '../../core/models/base_model.dart';

class Product extends BaseModel {
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final double stock;
  final String? sku;

  Product({
    super.id,
    super.cloudId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.sku,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'],
    cloudId: m['cloud_id'],
    categoryId: m['category_id'],
    name: m['name'],
    description: m['description'],
    price: m['price'],
    stock: m['stock'],
    sku: m['sku'],
    createdAt: BaseModel.parseDate(m['created_at']),
    updatedAt: BaseModel.parseDate(m['updated_at']),
    isDeleted: (m['is_deleted'] as int) == 1,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'cloud_id': cloudId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'sku': sku,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': BaseModel.formatDate(createdAt),
    'updated_at': BaseModel.formatDate(updatedAt),
  };

  Product copyWith({
    int? id,
    String? cloudId,
    int? categoryId,
    String? name,
    String? description,
    double? price,
    double? stock,
    String? sku,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => Product(
    id: id ?? this.id,
    cloudId: cloudId ?? this.cloudId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    stock: stock ?? this.stock,
    sku: sku ?? this.sku,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
}

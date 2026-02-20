import '../../core/models/base_model.dart';

class BusinessProfile extends BaseModel {
  final String? name;
  final String? address;
  final String? phone;
  final String? email;
  final String? taxId;
  final String? logoPath;
  final String? entityType;
  final String currency;
  final String? timezone;
  final bool useInventory;
  final bool requireStock;
  final bool allowNegativeStock;
  final int lowStockLimit;

  BusinessProfile({
    super.id,
    super.cloudId,
    this.name,
    this.address,
    this.phone,
    this.email,
    this.taxId,
    this.logoPath,
    this.entityType,
    this.currency = 'DOP',
    this.timezone,
    this.useInventory = true,
    this.requireStock = true,
    this.allowNegativeStock = false,
    this.lowStockLimit = 5,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> m) => BusinessProfile(
    id: m['id'],
    cloudId: m['cloud_id'],
    name: m['name'],
    address: m['address'],
    phone: m['phone'],
    email: m['email'],
    taxId: m['tax_id'],
    logoPath: m['logo_path'],
    entityType: m['entity_type'],
    currency: m['currency'] ?? 'DOP',
    timezone: m['timezone'],
    useInventory: (m['use_inventory'] as int?) == 1,
    requireStock: (m['require_stock'] as int?) == 1,
    allowNegativeStock: (m['allow_negative_stock'] as int?) == 1,
    lowStockLimit: m['low_stock_limit'] ?? 5,
    createdAt: BaseModel.parseDate(m['created_at']),
    updatedAt: BaseModel.parseDate(m['updated_at']),
    isDeleted: (m['is_deleted'] as int) == 1,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'cloud_id': cloudId,
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'tax_id': taxId,
    'logo_path': logoPath,
    'entity_type': entityType,
    'currency': currency,
    'timezone': timezone,
    'use_inventory': useInventory ? 1 : 0,
    'require_stock': requireStock ? 1 : 0,
    'allow_negative_stock': allowNegativeStock ? 1 : 0,
    'low_stock_limit': lowStockLimit,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': BaseModel.formatDate(createdAt),
    'updated_at': BaseModel.formatDate(updatedAt),
  };

  BusinessProfile copyWith({
    int? id,
    String? cloudId,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? taxId,
    String? logoPath,
    String? entityType,
    String? currency,
    String? timezone,
    bool? useInventory,
    bool? requireStock,
    bool? allowNegativeStock,
    int? lowStockLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxId: taxId ?? this.taxId,
      logoPath: logoPath ?? this.logoPath,
      entityType: entityType ?? this.entityType,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      useInventory: useInventory ?? this.useInventory,
      requireStock: requireStock ?? this.requireStock,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

import '../../core/models/base_model.dart';

class Client extends BaseModel {
  final String name;
  final String? taxId;
  final String? email;
  final String? phone;
  final String? address;

  Client({
    super.id,
    super.cloudId,
    required this.name,
    this.taxId,
    this.email,
    this.phone,
    this.address,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  factory Client.fromMap(Map<String, dynamic> m) => Client(
    id: m['id'],
    cloudId: m['cloud_id'],
    name: m['name'],
    taxId: m['tax_id'],
    email: m['email'],
    phone: m['phone'],
    address: m['address'],
    createdAt: BaseModel.parseDate(m['created_at']),
    updatedAt: BaseModel.parseDate(m['updated_at']),
    isDeleted: (m['is_deleted'] as int) == 1,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'cloud_id': cloudId,
    'name': name,
    'tax_id': taxId,
    'email': email,
    'phone': phone,
    'address': address,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': BaseModel.formatDate(createdAt),
    'updated_at': BaseModel.formatDate(updatedAt),
  };

  Client copyWith({
    int? id,
    String? cloudId,
    String? name,
    String? taxId,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => Client(
    id: id ?? this.id,
    cloudId: cloudId ?? this.cloudId,
    name: name ?? this.name,
    taxId: taxId ?? this.taxId,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
}

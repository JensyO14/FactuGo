import '../../core/models/base_model.dart';

class InvoiceItem extends BaseModel {
  final int invoiceId;
  final int productId;
  final String? productName; // Loaded via JOIN
  final double quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    super.id,
    super.cloudId,
    required this.invoiceId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
    id: m['id'],
    cloudId: m['cloud_id'],
    invoiceId: m['invoice_id'],
    productId: m['product_id'],
    productName: m['product_name'], // Alias from JOIN
    quantity: m['quantity'],
    unitPrice: m['unit_price'],
    total: m['total'],
    createdAt: BaseModel.parseDate(m['created_at']),
    updatedAt: BaseModel.parseDate(m['updated_at']),
    isDeleted: (m['is_deleted'] as int) == 1,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'cloud_id': cloudId,
    'invoice_id': invoiceId,
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total': total,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': BaseModel.formatDate(createdAt),
    'updated_at': BaseModel.formatDate(updatedAt),
  };
}

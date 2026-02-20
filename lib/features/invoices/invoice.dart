import '../../core/models/base_model.dart';
import '../clients/client.dart';

class Invoice extends BaseModel {
  final int clientId;
  final Client? client; // Loaded from DB join or separate query
  final String number;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double total;
  final double discount; // New field
  final String status; // 'pagada', 'pendiente', 'anulada'

  final String paymentMethod; // 'Contado', 'Credito'
  final double amountTendered;
  final double changeReturned;

  Invoice({
    super.id,
    super.cloudId,
    required this.clientId,
    this.client,
    required this.number,
    required this.date,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.discount = 0.0,
    this.status = 'pagada',
    required this.paymentMethod,
    required this.amountTendered,
    required this.changeReturned,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
  });

  factory Invoice.fromMap(Map<String, dynamic> m, {Client? client}) => Invoice(
    id: m['id'],
    cloudId: m['cloud_id'],
    clientId: m['client_id'],
    client: client,
    number: m['number'],
    date: BaseModel.parseDate(m['date']),
    subtotal: m['subtotal'],
    tax: m['tax'],
    total: m['total'],
    discount: m['discount'] != null
        ? (m['discount'] is int
              ? (m['discount'] as int).toDouble()
              : m['discount'])
        : 0.0,
    status: m['status'] ?? 'pagada',
    paymentMethod: m['payment_method'] ?? 'Contado',
    amountTendered: m['amount_tendered'] ?? 0.0,
    changeReturned: m['change_returned'] ?? 0.0,
    createdAt: BaseModel.parseDate(m['created_at']),
    updatedAt: BaseModel.parseDate(m['updated_at']),
    isDeleted: (m['is_deleted'] as int) == 1,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'cloud_id': cloudId,
    'client_id': clientId,
    'number': number,
    'date': BaseModel.formatDate(date),
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'status': status,
    'payment_method': paymentMethod,
    'amount_tendered': amountTendered,
    'change_returned': changeReturned,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': BaseModel.formatDate(createdAt),
    'updated_at': BaseModel.formatDate(updatedAt),
  };

  Invoice copyWith({
    int? id,
    String? cloudId,
    int? clientId,
    Client? client,
    String? number,
    DateTime? date,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
    String? paymentMethod,
    double? amountTendered,
    double? changeReturned,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => Invoice(
    id: id ?? this.id,
    cloudId: cloudId ?? this.cloudId,
    clientId: clientId ?? this.clientId,
    client: client ?? this.client,
    number: number ?? this.number,
    date: date ?? this.date,
    subtotal: subtotal ?? this.subtotal,
    tax: tax ?? this.tax,
    total: total ?? this.total,
    status: status ?? this.status,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    amountTendered: amountTendered ?? this.amountTendered,
    changeReturned: changeReturned ?? this.changeReturned,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
}

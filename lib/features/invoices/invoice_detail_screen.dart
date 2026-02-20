import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'invoice.dart';
import 'invoice_item.dart';
import 'invoice_repository.dart';
import 'invoice_provider.dart';

final invoiceItemsProvider = FutureProvider.family<List<InvoiceItem>, int>((
  ref,
  invoiceId,
) async {
  return InvoiceRepository().getItemsFor(invoiceId);
});

class InvoiceDetailScreen extends ConsumerWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(invoiceItemsProvider(invoice.id!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Factura ${invoice.number}'),
        actions: [
          if (invoice.status != 'anulada')
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'cancel') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Anular Factura'),
                      content: const Text(
                        '¿Estás seguro de anular esta factura? El stock de los productos será devuelto.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Anular'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(invoiceNotifierProvider.notifier)
                        .cancelInvoice(invoice.id!);
                    if (context.mounted) {
                      Navigator.pop(context); // Volver a lista
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Factura anulada')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Anular Factura',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STATUS: ${invoice.status.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _formatDate(invoice.date),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  invoice.client?.name ?? 'Cliente ${invoice.clientId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (invoice.client?.phone != null)
                  Text(
                    invoice.client!.phone!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            alignment: Alignment.centerLeft,
            child: const Text(
              'PRODUCTOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textHint,
                letterSpacing: 1,
              ),
            ),
          ),

          // Lista de Items
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (items) => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cantidad
                        Container(
                          width: 40,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${item.quantity.toStringAsFixed(0)}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        // Nombre y Precio Unitario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ??
                                    'Producto #${item.productId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '\$${item.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Total Item
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Footer de Totales
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              children: [
                _buildTotalRow('Subtotal', invoice.subtotal),
                if (invoice.discount > 0)
                  _buildTotalRow(
                    'Descuento',
                    -invoice.discount,
                    isDiscount: true,
                  ), // Resta visual
                if (invoice.tax > 0) _buildTotalRow('Impuestos', invoice.tax),

                const Divider(height: 16),
                _buildInfoRow('Método de Pago', invoice.paymentMethod),
                if (invoice.paymentMethod == 'Contado') ...[
                  _buildTotalRow('Monto Recibido', invoice.amountTendered),
                  _buildTotalRow('Devuelta', invoice.changeReturned),
                ],

                const Divider(height: 24),
                _buildTotalRow('TOTAL', invoice.total, isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? AppColors.primary
                  : (isDiscount ? AppColors.success : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

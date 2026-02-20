import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'invoice.dart';
import 'invoice_provider.dart';
import 'invoice_detail_screen.dart';

import 'invoice_filter_provider.dart';
import 'invoice_filter_modal.dart';

class InvoicesBodyWidget extends ConsumerWidget {
  const InvoicesBodyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceNotifierProvider);
    final filter = ref.watch(invoiceFilterProvider);
    final filterNotifier = ref.read(invoiceFilterProvider.notifier);

    return Column(
      children: [
        // Filtros Activos
        if (filter.hasFilters)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                if (filter.searchQuery.isNotEmpty)
                  _FilterChip(
                    label: 'Buscar: "${filter.searchQuery}"',
                    onDeleted: () => filterNotifier.setSearchQuery(''),
                  ),
                if (filter.startDate != null)
                  _FilterChip(
                    label: 'Desde: ${_formatDate(filter.startDate!)}',
                    onDeleted: () =>
                        filterNotifier.setDateRange(null, filter.endDate),
                  ),
                if (filter.endDate != null)
                  _FilterChip(
                    label: 'Hasta: ${_formatDate(filter.endDate!)}',
                    onDeleted: () =>
                        filterNotifier.setDateRange(filter.startDate, null),
                  ),
                for (final status in filter.selectedStatuses)
                  _FilterChip(
                    label: status.toUpperCase(),
                    onDeleted: () => filterNotifier.toggleStatus(status),
                  ),
                if (filter.selectedClient != null)
                  _FilterChip(
                    label: 'Cliente: ${filter.selectedClient!.name}',
                    onDeleted: () => filterNotifier.setClient(null),
                  ),
                TextButton(
                  onPressed: filterNotifier.clearFilters,
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),

        // Lista
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (invoices) => invoices.isEmpty
                ? const _EmptyState()
                : _InvoiceList(invoices: invoices),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class InvoiceFilterAction extends StatelessWidget {
  const InvoiceFilterAction({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search), // Icono de lupa solicitado
      tooltip: 'Buscar y Filtrar',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const InvoiceFilterModal(),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  const _FilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.inputBorder),
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  const _InvoiceList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      separatorBuilder: (ctx, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final invoice = invoices[i];
        final isCanceled = invoice.status == 'anulada';

        return Card(
          // Mostrar si está anulada visualmente (ej. color gris o marca)
          color: isCanceled ? Colors.grey[100] : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: isCanceled
                  ? AppColors.textHint
                  : (invoice.status == 'pagada'
                        ? AppColors.success
                        : AppColors.primaryLight),
              child: Icon(
                isCanceled
                    ? Icons.block
                    : (invoice.status == 'pagada'
                          ? Icons.check
                          : Icons.receipt_long),
                color: Colors.white,
              ),
            ),
            title: Text(
              'Factura #${invoice.number}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isCanceled ? TextDecoration.lineThrough : null,
                color: isCanceled ? AppColors.textHint : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${invoice.date.day}/${invoice.date.month}/${invoice.date.year} - ${invoice.client?.name ?? 'Cliente'}',
                  style: isCanceled
                      ? const TextStyle(color: AppColors.textHint)
                      : null,
                ),
                Text(
                  invoice.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCanceled
                        ? AppColors.textHint
                        : (invoice.status == 'pagada'
                              ? AppColors.success
                              : AppColors.primary),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${invoice.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: isCanceled ? TextDecoration.lineThrough : null,
                    color: isCanceled ? AppColors.textHint : AppColors.primary,
                  ),
                ),
                if (!isCanceled) ...[
                  const SizedBox(width: 4),
                  Consumer(
                    builder: (context, ref, _) {
                      return PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                        ),
                        onSelected: (value) async {
                          if (value == 'pay') {
                            await _confirmPay(context, ref, invoice);
                          } else if (value == 'cancel') {
                            await _confirmCancel(context, ref, invoice);
                          }
                        },
                        itemBuilder: (context) => [
                          if (invoice.status != 'pagada')
                            const PopupMenuItem(
                              value: 'pay',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Marcar como Pagada'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Anular Factura',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceDetailScreen(invoice: invoice),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmPay(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
  ) async {
    final curStatus = invoice.status;
    if (curStatus == 'pagada') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Pagada'),
        content: Text(
          '¿Desea cambiar el estado de la factura #${invoice.number} a PAGADA?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(invoiceNotifierProvider.notifier)
          .changeStatus(invoice.id!, 'pagada');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura marcada como PAGADA')),
        );
      }
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
  ) async {
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura anulada correctamente')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_off, // Icono sugerente de "no hay resultados"
            size: 60,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'No se encontraron facturas',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

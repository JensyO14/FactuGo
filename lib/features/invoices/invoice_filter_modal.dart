import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../clients/client.dart';
import 'client_selection_modal.dart';
import 'invoice_filter_provider.dart';

class InvoiceFilterModal extends ConsumerWidget {
  const InvoiceFilterModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(invoiceFilterProvider);
    final notifier = ref.read(invoiceFilterProvider.notifier);

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtrar Facturas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (filter.hasFilters)
                TextButton(
                  onPressed: () {
                    notifier.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Código
          const Text(
            'Código / Número',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: filter.searchQuery)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: filter.searchQuery.length),
              ),
            onChanged: notifier.setSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Ej: 000123',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),

          // Rango de Fechas
          const Text(
            'Fecha',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: filter.startDate != null
                      ? dateFormat.format(filter.startDate!)
                      : 'Desde',
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: filter.startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      notifier.setDateRange(
                        date,
                        filter.endDate ?? DateTime.now(),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: filter.endDate != null
                      ? dateFormat.format(filter.endDate!)
                      : 'Hasta',
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: filter.endDate ?? DateTime.now(),
                      firstDate: filter.startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      notifier.setDateRange(filter.startDate ?? date, date);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado
          const Text(
            'Estado',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final status in ['pagada', 'pendiente', 'anulada'])
                FilterChip(
                  label: Text(status.toUpperCase()),
                  selected: filter.selectedStatuses.contains(status),
                  onSelected: (_) => notifier.toggleStatus(status),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: filter.selectedStatuses.contains(status)
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Cliente
          const Text(
            'Cliente',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final client = await showModalBottomSheet<Client>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ClientSelectionModal(),
              );
              if (client != null) {
                notifier.setClient(client);
              }
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: filter.selectedClient != null
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filter.selectedClient?.name ?? 'Todos los clientes',
                      style: TextStyle(
                        color: filter.selectedClient != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  if (filter.selectedClient != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => notifier.setClient(null),
                    )
                  else
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textHint,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver Resultados'),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../products/product_provider.dart';
import 'invoice_filter_provider.dart';
import 'invoice.dart';
import 'invoice_item.dart';
import 'invoice_repository.dart';

final _invoiceRepo = InvoiceRepository();

class InvoiceNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() async {
    final filter = ref.watch(invoiceFilterProvider);
    return _invoiceRepo.getFiltered(
      startDate: filter.startDate,
      endDate: filter.endDate,
      statuses: filter.selectedStatuses,
      clientId: filter.selectedClient?.id,
      query: filter.searchQuery,
    );
  }

  /// Crea una factura con sus items en una transacción.
  Future<int> create(
    Invoice invoice,
    List<InvoiceItem> items, {
    bool deductStock = true,
  }) async {
    final id = await _invoiceRepo.createWithItems(
      invoice,
      items,
      deductStock: deductStock,
    );
    ref.invalidateSelf();
    return id;
  }

  Future<void> changeStatus(int id, String status) async {
    await _invoiceRepo.updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> cancelInvoice(int id) async {
    await _invoiceRepo.cancel(id);
    ref.invalidateSelf();
    // Actualizar stock de productos en la UI
    ref.invalidate(productNotifierProvider);
  }
}

final invoiceNotifierProvider =
    AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(InvoiceNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../clients/client.dart';

class InvoiceFilterState {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> selectedStatuses; // ['pagada', 'pendiente', 'anulada']
  final Client? selectedClient;
  final String searchQuery; // Para código de factura

  const InvoiceFilterState({
    this.startDate,
    this.endDate,
    this.selectedStatuses = const [],
    this.selectedClient,
    this.searchQuery = '',
  });

  bool get hasFilters =>
      startDate != null ||
      endDate != null ||
      selectedStatuses.isNotEmpty ||
      selectedClient != null ||
      searchQuery.isNotEmpty;

  InvoiceFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedStatuses,
    Client? selectedClient,
    String? searchQuery,
    bool clearClient = false,
  }) {
    return InvoiceFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedClient: clearClient
          ? null
          : (selectedClient ?? this.selectedClient),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class InvoiceFilterNotifier extends Notifier<InvoiceFilterState> {
  @override
  InvoiceFilterState build() {
    return const InvoiceFilterState();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void toggleStatus(String status) {
    final current = List<String>.from(state.selectedStatuses);
    if (current.contains(status)) {
      current.remove(status);
    } else {
      current.add(status);
    }
    state = state.copyWith(selectedStatuses: current);
  }

  void setClient(Client? client) {
    state = state.copyWith(selectedClient: client, clearClient: client == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = const InvoiceFilterState();
  }
}

final invoiceFilterProvider =
    NotifierProvider<InvoiceFilterNotifier, InvoiceFilterState>(
      InvoiceFilterNotifier.new,
    );

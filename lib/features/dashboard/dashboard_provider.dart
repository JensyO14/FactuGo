import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../invoices/invoice.dart';
import '../invoices/invoice_provider.dart';
import '../products/product_provider.dart';
import '../business/business_provider.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  // Watch these providers so dashboard auto-refreshes when data changes
  ref.watch(invoiceNotifierProvider);
  ref.watch(productNotifierProvider);

  final repo = ref.watch(dashboardRepositoryProvider);
  final businessAsync = ref.watch(businessProvider);

  final business = businessAsync.asData?.value;
  final useInventory = business?.useInventory ?? false;

  return repo.getStats(useInventory: useInventory);
});

final weeklySalesProvider = FutureProvider<List<SalesPoint>>((ref) async {
  ref.watch(invoiceNotifierProvider); // Auto-refresh on invoice changes
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getWeeklySales();
});

final recentInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  ref.watch(invoiceNotifierProvider); // Auto-refresh on invoice changes
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getRecentInvoices();
});

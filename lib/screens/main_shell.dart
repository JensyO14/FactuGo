import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/clients/clients_screen.dart';
import '../features/invoices/invoices_screen.dart';
import '../features/invoices/invoice_form_screen.dart';
import '../features/products/products_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/business/business_screen.dart';
import '../core/providers/navigation_provider.dart';
import 'home_screen.dart';

/// Shell principal — un único Scaffold con Drawer.
/// Las sub-pantallas NO tienen su propio Scaffold;
/// exponen solo su body a través de [ScreenConfig].
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static final List<_NavItem> _items = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      buildConfig: (_) => const ScreenConfig(body: HomeBody()),
    ),
    _NavItem(
      label: 'Nueva Factura',
      icon: Icons.note_add_outlined,
      buildConfig: (_) => const ScreenConfig(body: InvoiceFormBody()),
    ),
    _NavItem(
      label: 'Historial de Ventas',
      icon: Icons.history,
      buildConfig: (_) => const ScreenConfig(
        body: InvoicesBodyWidget(),
        actions: [InvoiceFilterAction()],
      ),
    ),
    _NavItem(
      label: 'Clientes',
      icon: Icons.people_outline,
      buildConfig: (_) => const ScreenConfig(
        body: ClientsBodyWidget(),
        actions: [ClientsSearchAction()],
      ),
    ),
    _NavItem(
      label: 'Productos',
      icon: Icons.inventory_2_outlined,
      buildConfig: (_) => const ScreenConfig(
        body: ProductsBodyWidget(),
        actions: [ProductsSearchAction()],
      ),
    ),
    _NavItem(
      label: 'Categorías',
      icon: Icons.category_outlined,
      buildConfig: (_) => const ScreenConfig(body: CategoriesBodyWidget()),
    ),
    _NavItem(
      label: 'Gastos',
      icon: Icons.account_balance_wallet_outlined,
      buildConfig: (_) => const ScreenConfig(body: ExpensesBodyWidget()),
    ),
    _NavItem(
      label: 'Mi empresa',
      icon: Icons.business_outlined,
      buildConfig: (_) => const ScreenConfig(body: BusinessBodyWidget()),
    ),
  ];

  // IMPORTANTE: este array debe tener exactamente el mismo número
  // de elementos que _items y en el mismo orden.
  static const List<String> _sections = [
    '', // Dashboard
    'VENTAS', // Nueva Factura
    '', // Historial (mantiene Ventas)
    '', // Clientes
    'CATÁLOGO', // Productos
    '', // Categorías
    'GASTOS', // Gastos
    'CONFIGURACIÓN', // Mi empresa
  ];

  void _navigate(int index) {
    ref.read(navigationProvider.notifier).setIndex(index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);
    final item = _items[selectedIndex];
    final config = item.buildConfig(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (selectedIndex != 0) {
          ref.read(navigationProvider.notifier).setIndex(0);
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Salir de la aplicación?'),
            content: const Text('¿Estás seguro de que quieres salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(item.label),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: config.actions,
        ),
        drawer: _AppDrawer(
          items: _items,
          sections: _sections,
          selectedIndex: selectedIndex,
          onSelect: _navigate,
        ),
        body: config.body,
        floatingActionButton: config.fab,
      ),
    );
  }
}

// ─── ScreenConfig — lo que cada pantalla expone al Shell ─────────────────────

class ScreenConfig {
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;

  const ScreenConfig({required this.body, this.fab, this.actions});
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final ScreenConfig Function(BuildContext) buildConfig;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.buildConfig,
  });
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final List<_NavItem> items;
  final List<String> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _AppDrawer({
    required this.items,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'FactuGo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Sistema de facturación',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── Items ─────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final section = sections[i];
                  final item = items[i];
                  final isSelected = i == selectedIndex;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            top: 16,
                            bottom: 4,
                          ),
                          child: Text(
                            section,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                      ListTile(
                        onTap: () => onSelect(i),
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Footer ────────────────────────────────
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'v0.1.0 — beta',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder ─────────────────────────────────────────────────────────────

class _ComingSoonBody extends StatelessWidget {
  final String label;
  const _ComingSoonBody({required this.label});

  ScreenConfig call() => ScreenConfig(body: this);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 56,
            color: AppColors.inputBorder,
          ),
          SizedBox(height: 16),
          Text(
            'Próximamente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../products/product_provider.dart';
import '../business/business_provider.dart';

class ProductSelectionModal extends ConsumerStatefulWidget {
  const ProductSelectionModal({super.key});

  @override
  ConsumerState<ProductSelectionModal> createState() =>
      _ProductSelectionModalState();
}

class _ProductSelectionModalState extends ConsumerState<ProductSelectionModal> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productNotifierProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 48), // spacer
                const Expanded(
                  child: Text(
                    'Seleccionar Producto',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          const SizedBox(height: 10),

          // Lista
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (products) {
                // Business Logic for Selection
                final business = ref.read(businessProvider).asData?.value;
                final useInventory = business?.useInventory ?? false;
                final allowNegative = business?.allowNegativeStock ?? false;
                final requireStock = business?.requireStock ?? true;

                final filtered = products.where((p) {
                  final matchName = p.name.toLowerCase().contains(
                    _query.toLowerCase(),
                  );
                  final matchSku =
                      p.sku?.toLowerCase().contains(_query.toLowerCase()) ??
                      false;
                  return matchName || matchSku;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron productos'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final p = filtered[i];
                    final hasStock = p.stock > 0;

                    // Determine if selectable based on business rules
                    bool isSelectable = true;
                    if (useInventory && requireStock && !allowNegative) {
                      if (!hasStock) isSelectable = false;
                    }

                    return ListTile(
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: hasStock
                            ? AppColors.primaryLight
                            : Colors.grey.shade200,
                        child: Icon(
                          Icons.inventory_2,
                          color: hasStock ? AppColors.primary : Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelectable
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                      subtitle: Text(
                        'Stock: ${p.stock.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: hasStock
                              ? AppColors.textSecondary
                              : AppColors.error,
                        ),
                      ),
                      trailing: Text(
                        '\$${p.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      enabled: isSelectable,
                      onTap: isSelectable
                          ? () => Navigator.pop(context, p)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

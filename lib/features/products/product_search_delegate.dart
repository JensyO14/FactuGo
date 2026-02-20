import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'product.dart';
import 'products_screen.dart'; // import ProductForm

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;

  ProductSearchDelegate(this.products);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final filtered = products.where((p) {
      final q = query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase().contains(q) ?? false) ||
          (p.description?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No se encontraron productos'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final p = filtered[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: const Icon(
              Icons.inventory_2,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(p.name),
          subtitle: Text('Stock: ${p.stock.toStringAsFixed(0)}'),
          trailing: Text('\$${p.price.toStringAsFixed(2)}'),
          onTap: () {
            // Abrir formulario de edición
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ProductForm(product: p),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/base_model.dart';
import '../../core/theme/app_theme.dart';
import 'invoice.dart';

class InvoiceSearchDelegate extends SearchDelegate<Invoice?> {
  final List<Invoice> invoices;

  InvoiceSearchDelegate(this.invoices);

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
    final filtered = invoices.where((inv) {
      final q = query.toLowerCase();
      // Buscar por número
      return inv.number.toLowerCase().contains(q);
      // Podríamos buscar por cliente si tuviéramos el nombre del cliente en Invoice (pero solo tenemos clientId)
      // Para buscar por cliente, necesitaríamos cruzar datos. Por ahora solo número.
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No se encontraron facturas'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final invoice = filtered[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.receipt_long, color: AppColors.primary),
          ),
          title: Text('Factura #${invoice.number}'),
          subtitle: Text(BaseModel.formatDate(invoice.date)),
          trailing: Text(
            '\$${invoice.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () {
            // Quizás detalle?
            close(context, invoice);
          },
        );
      },
    );
  }
}

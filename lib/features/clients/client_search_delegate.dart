import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'client.dart';
import 'clients_screen.dart'; // import ClientForm

class ClientSearchDelegate extends SearchDelegate<Client?> {
  final List<Client> clients;
  final WidgetRef ref;

  ClientSearchDelegate(this.clients, this.ref);

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
    final filtered = clients.where((c) {
      final q = query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.taxId?.toLowerCase().contains(q) ?? false) ||
          (c.phone?.toLowerCase().contains(q) ?? false) ||
          (c.email?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No se encontraron clientes'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final c = filtered[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?'),
          ),
          title: Text(c.name),
          subtitle: Text(c.taxId ?? 'Sin ID'),
          onTap: () {
            // Abrir formulario de edición
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ClientForm(client: c),
            );
          },
        );
      },
    );
  }
}

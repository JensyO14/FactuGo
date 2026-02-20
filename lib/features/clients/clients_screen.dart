import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'client.dart';
import 'client_provider.dart';
import 'client_search_delegate.dart';

// ─── Widgets públicos para MainShell ─────────────────────────────────────────

/// Body de clientes para MainShell (sin Scaffold propio).
class ClientsBodyWidget extends ConsumerWidget {
  const ClientsBodyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientNotifierProvider);
    return Stack(
      children: [
        clientsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (clients) => clients.isEmpty
              ? const _EmptyState()
              : _ClientList(clients: clients),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: Builder(
            builder: (ctx) => FloatingActionButton.extended(
              onPressed: () => _showClientForm(ctx, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Nuevo cliente'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ícono de búsqueda para el AppBar (futuro).
class ClientsSearchAction extends ConsumerWidget {
  const ClientsSearchAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () async {
        final clients = ref.read(clientNotifierProvider).value ?? [];
        await showSearch(
          context: context,
          delegate: ClientSearchDelegate(clients, ref),
        );
      },
    );
  }
}

// ─── Lista ───────────────────────────────────────────────────────────────────

class _ClientList extends ConsumerWidget {
  final List<Client> clients;
  const _ClientList({required this.clients});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: clients.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ClientCard(client: clients[i], ref: ref),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  final WidgetRef ref;
  const _ClientCard({required this.client, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: client.id == 1
            ? null
            : () => _showClientForm(context, ref, client: client),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar con inicial
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (client.taxId != null && client.taxId!.isNotEmpty)
                      _InfoLine(
                        icon: Icons.badge_outlined,
                        text: client.taxId!,
                      ),
                    if (client.phone != null && client.phone!.isNotEmpty)
                      _InfoLine(
                        icon: Icons.phone_outlined,
                        text: client.phone!,
                      ),
                    if (client.email != null && client.email!.isNotEmpty)
                      _InfoLine(
                        icon: Icons.email_outlined,
                        text: client.email!,
                      ),
                  ],
                ),
              ),
              // Eliminar (Ocultar para Consumidor Final)
              if (client.id != 1)
                Column(
                  children: [
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, ref, client),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Eliminar a "${client.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(clientNotifierProvider.notifier).remove(client.id!);
    }
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin clientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Agrega tu primer cliente con el botón +',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Formulario ───────────────────────────────────────────────────────────────

void _showClientForm(BuildContext context, WidgetRef ref, {Client? client}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClientForm(client: client),
  );
}

class ClientForm extends ConsumerStatefulWidget {
  final Client? client;
  const ClientForm({super.key, this.client});

  @override
  ConsumerState<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _taxIdCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;
  String? _errorMsg; // mensaje de error inline

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _taxIdCtrl = TextEditingController(text: c?.taxId ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taxIdCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String? _trim(TextEditingController ctrl) {
    final v = ctrl.text.trim();
    return v.isEmpty ? null : v;
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _errorMsg = msg);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final taxId = _trim(_taxIdCtrl);
    final editId = widget.client?.id;

    try {
      // Obtener lista actual para validar duplicados en el widget
      final clients = await ref.read(clientNotifierProvider.future);

      // Nombre único
      final nameTaken = clients.any(
        (c) => c.name.toLowerCase() == name.toLowerCase() && c.id != editId,
      );
      if (nameTaken) {
        _showError('Ya existe un cliente con el nombre "$name".');
        return;
      }

      // Cédula/RNC único (solo si se ingresó)
      if (taxId != null && taxId.isNotEmpty) {
        final taxIdTaken = clients.any(
          (c) =>
              c.taxId?.toLowerCase() == taxId.toLowerCase() && c.id != editId,
        );
        if (taxIdTaken) {
          _showError('Ya existe un cliente con la cédula/RNC "$taxId".');
          return;
        }
      }

      final now = DateTime.now();
      final notifier = ref.read(clientNotifierProvider.notifier);

      if (widget.client == null) {
        await notifier.add(
          Client(
            name: name,
            taxId: taxId,
            phone: _trim(_phoneCtrl),
            email: _trim(_emailCtrl),
            address: _trim(_addressCtrl),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await notifier.edit(
          widget.client!.copyWith(
            name: name,
            taxId: taxId,
            phone: _trim(_phoneCtrl),
            email: _trim(_emailCtrl),
            address: _trim(_addressCtrl),
            updatedAt: now,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.client != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20, top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Editar cliente' : 'Nuevo cliente',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Nombre *
              _Label('Nombre *'),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Nombre completo o razón social',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              // RNC / Cédula
              _Label('RNC / Cédula (opcional)'),
              TextFormField(
                controller: _taxIdCtrl,
                decoration: const InputDecoration(hintText: 'Ej: J-12345678-9'),
              ),
              const SizedBox(height: 14),

              // Teléfono y email en fila
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Teléfono'),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '0414-0000000',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Email'),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'correo@ejemplo.com',
                          ),
                          validator: (v) {
                            if (v != null &&
                                v.trim().isNotEmpty &&
                                !v.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dirección
              _Label('Dirección (opcional)'),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Dirección del cliente',
                ),
              ),
              const SizedBox(height: 16),

              // Banner de error inline (visible dentro del modal)
              if (_errorMsg != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.inputBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Guardar cambios' : 'Agregar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

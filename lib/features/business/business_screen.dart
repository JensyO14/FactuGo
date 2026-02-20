import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'business_profile.dart';
import 'business_provider.dart';

class BusinessBodyWidget extends ConsumerStatefulWidget {
  const BusinessBodyWidget({super.key});

  @override
  ConsumerState<BusinessBodyWidget> createState() => _BusinessBodyWidgetState();
}

class _BusinessBodyWidgetState extends ConsumerState<BusinessBodyWidget> {
  final _formKey = GlobalKey<FormState>();

  // General Info
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _taxIdCtrl;
  String? _entityType;
  String _currency = 'DOP';

  // Inventory Settings
  bool _useInventory = true;
  bool _requireStock = true;
  bool _allowNegativeStock = false;
  late TextEditingController _lowStockCtrl;

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _taxIdCtrl = TextEditingController();
    _lowStockCtrl = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxIdCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  void _initData(BusinessProfile? profile) {
    if (_isInit) return;
    if (profile != null) {
      _nameCtrl.text = profile.name ?? '';
      _addressCtrl.text = profile.address ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _emailCtrl.text = profile.email ?? '';
      _taxIdCtrl.text = profile.taxId ?? '';
      _entityType = profile.entityType;
      _currency = profile.currency;

      _useInventory = profile.useInventory;
      _requireStock = profile.requireStock;
      _allowNegativeStock = profile.allowNegativeStock;
      _lowStockCtrl.text = profile.lowStockLimit.toString();
    }
    _isInit = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final taxId = _taxIdCtrl.text.trim();
    final lowStock = int.tryParse(_lowStockCtrl.text) ?? 5;

    final profile =
        ref
            .read(businessProvider)
            .value
            ?.copyWith(
              name: name,
              address: address.isEmpty ? null : address,
              phone: phone.isEmpty ? null : phone,
              email: email.isEmpty ? null : email,
              taxId: taxId.isEmpty ? null : taxId,
              entityType: _entityType,
              currency: _currency,
              useInventory: _useInventory,
              requireStock: _requireStock,
              allowNegativeStock: _allowNegativeStock,
              lowStockLimit: lowStock,
              updatedAt: DateTime.now(),
            ) ??
        BusinessProfile(
          name: name,
          address: address.isEmpty ? null : address,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          taxId: taxId.isEmpty ? null : taxId,
          entityType: _entityType,
          currency: _currency,
          useInventory: _useInventory,
          requireStock: _requireStock,
          allowNegativeStock: _allowNegativeStock,
          lowStockLimit: lowStock,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    await ref.read(businessProvider.notifier).save(profile);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessProvider);

    return businessAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (profile) {
        _initData(profile);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Información General'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Comercial *',
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _entityType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Entidad',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Fisica',
                      child: Text('Persona Física'),
                    ),
                    DropdownMenuItem(
                      value: 'Profesional',
                      child: Text('Entidad Profesional'),
                    ),
                    DropdownMenuItem(value: 'SRL', child: Text('SRL')),
                    DropdownMenuItem(value: 'EIRL', child: Text('EIRL')),
                    DropdownMenuItem(value: 'SAS', child: Text('SAS')),
                  ],
                  onChanged: (v) => setState(() => _entityType = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'RNC / Cédula (Opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (Opcional)',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email (Opcional)',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección (Opcional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(labelText: 'Moneda'),
                  items: const [
                    DropdownMenuItem(
                      value: 'DOP',
                      child: Text('Peso Dominicano (DOP)'),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('Dólar Estadounidense (USD)'),
                    ),
                    DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
                  ],
                  onChanged: (v) => setState(() => _currency = v!),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Configuración de Inventario ⚙️'),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('¿Usar inventario?'),
                  subtitle: const Text('Permite controlar stock y alertas'),
                  value: _useInventory,
                  onChanged: (v) => setState(() => _useInventory = v),
                ),

                if (_useInventory) ...[
                  SwitchListTile(
                    title: const Text('¿Obligar stock para facturar?'),
                    subtitle: const Text(
                      'Impide facturar si no hay suficiente existencia',
                    ),
                    value: _requireStock,
                    onChanged: (v) {
                      setState(() {
                        _requireStock = v;
                        if (v)
                          _allowNegativeStock = false; // Mutually exclusive
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('¿Permitir stock negativo?'),
                    subtitle: const Text('El inventario podrá bajar de cero'),
                    value: _allowNegativeStock,
                    onChanged: (v) {
                      setState(() {
                        _allowNegativeStock = v;
                        if (v) _requireStock = false; // Mutually exclusive
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextFormField(
                      controller: _lowStockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alerta de stock mínimo',
                        helperText: 'Avisar cuando quede esta cantidad o menos',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Opciones de control: FIFO y Promedio (Próximamente)',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ),
                ] else ...[
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: const Text(
                      'Al desactivar el inventario:\n\n'
                      '• No se validará stock al facturar.\n'
                      '• No se descontará stock automáticamente.\n'
                      '• No se mostrarán alertas de stock bajo.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Configuración'),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(),
      ],
    );
  }
}

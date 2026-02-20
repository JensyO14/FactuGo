import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../clients/client.dart';
import '../products/product.dart';
import 'client_selection_modal.dart';
import 'invoice_draft_provider.dart';
import 'product_selection_modal.dart';

class InvoiceFormBody extends ConsumerWidget {
  const InvoiceFormBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(invoiceDraftProvider);
    final notifier = ref.read(invoiceDraftProvider.notifier);

    // Escuchar errores
    ref.listen(invoiceDraftProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        notifier.clearError();
      }
      // Escuchar éxito (reset)
      if (previous?.isSaving == true &&
          next.isSaving == false &&
          next.items.isEmpty &&
          next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada exitosamente')),
        );
      }
    });

    return Column(
      children: [
        // Header: Cliente + Buscador
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              _ClientSelector(
                selectedClient: draft.client,
                onSelect: () => _pickClient(context, ref),
                onClear: () => notifier.setClient(null),
              ),
              const SizedBox(height: 8),
              // "Buscador" Falso que abre el modal de productos
              InkWell(
                onTap: () => _showProductSelection(context, ref),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Buscar productos...',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.add, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Lista de Items
        Expanded(
          child: draft.items.isEmpty
              ? _EmptyCartState(
                  onTap: () => _showProductSelection(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: draft.items.length,
                  separatorBuilder: (ctx, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = draft.items[i];
                    return Dismissible(
                      key: ValueKey('item_${item.product.id}_$i'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => notifier.removeItem(i),
                      child: _ItemCard(
                        index: i,
                        item: item,
                        onIncrement: () => notifier.incrementQuantity(i),
                        onDecrement: () => notifier.decrementQuantity(i),
                        onRemove: () => notifier.removeItem(i),
                        onUpdate: (val) => notifier.updateQuantity(i, val),
                      ),
                    );
                  },
                ),
        ),

        // Barra Inferior de Cobro
        _BottomCheckoutBar(
          total: draft.total,
          itemCount: draft.items.length,
          onCheckout: draft.items.isNotEmpty
              ? () => _showCheckoutModal(context, ref)
              : null,
        ),
      ],
    );
  }

  Future<void> _pickClient(BuildContext context, WidgetRef ref) async {
    final Client? client = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ClientSelectionModal(),
    );
    if (client != null) {
      ref.read(invoiceDraftProvider.notifier).setClient(client);
    }
  }

  Future<void> _showProductSelection(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final Product? product = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProductSelectionModal(),
    );
    if (product != null) {
      ref.read(invoiceDraftProvider.notifier).addItem(product);
    }
  }

  void _showCheckoutModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CheckoutModal(),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyCartState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_shopping_cart,
              size: 64,
              color: AppColors.primary.withAlpha(50),
            ),
            const SizedBox(height: 16),
            const Text(
              'El carrito está vacío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca aquí para agregar productos',
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCheckoutBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final VoidCallback? onCheckout;

  const _BottomCheckoutBar({
    required this.total,
    required this.itemCount,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$itemCount items',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'COBRAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutModal extends ConsumerStatefulWidget {
  const _CheckoutModal();
  @override
  ConsumerState<_CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends ConsumerState<_CheckoutModal> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(invoiceDraftProvider);
    final notifier = ref.read(invoiceDraftProvider.notifier);
    final isSaving = draft.isSaving;
    final isContado = draft.paymentMethod == 'Contado';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirmar Venta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Total Large
            Center(
              child: Text(
                '\$${draft.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Contado / Crédito ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'Contado',
                    groupValue: draft.paymentMethod,
                    title: const Text(
                      'Contado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => notifier.setPaymentMethod(val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'Credito',
                    groupValue: draft.paymentMethod,
                    title: const Text(
                      'Crédito',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      notifier.setPaymentMethod(val!);
                      _amountController.clear();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Tipo de Pago (solo Contado) ───────────────────────────────
            if (isContado) ...[
              const Text(
                'Forma de pago',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PaymentTypeChip(
                    label: 'Efectivo',
                    icon: Icons.payments_outlined,
                    selected: draft.paymentType == 'Efectivo',
                    onTap: () => notifier.setPaymentType('Efectivo'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentTypeChip(
                    label: 'Tarjeta',
                    icon: Icons.credit_card,
                    selected: draft.paymentType == 'Tarjeta',
                    onTap: () => notifier.setPaymentType('Tarjeta'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentTypeChip(
                    label: 'Transfer.',
                    icon: Icons.account_balance_outlined,
                    selected: draft.paymentType == 'Transferencia',
                    onTap: () => notifier.setPaymentType('Transferencia'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Descuento ─────────────────────────────────────────────────
            TextField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Descuento Global',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.local_offer, size: 18),
              ),
              onChanged: (value) {
                final discount = double.tryParse(value) ?? 0.0;
                notifier.setDiscount(discount);
              },
            ),
            const SizedBox(height: 16),

            // ── Monto Recibido + Devuelta (solo Contado + Efectivo) ───────
            if (isContado && draft.paymentType == 'Efectivo') ...[
              TextField(
                controller: _amountController,
                autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto Recibido',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0.0;
                  notifier.setAmountTendered(amount);
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Devuelta:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '\$${draft.changeReturned.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: draft.changeReturned >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else ...[
              const SizedBox(height: 8),
            ],

            // ── Confirmar ─────────────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        await notifier.saveInvoice();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR VENTA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Type Chip ──────────────────────────────────────────────────────────

class _PaymentTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.inputBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientSelector extends StatelessWidget {
  final Client? selectedClient;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  const _ClientSelector({
    required this.selectedClient,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  selectedClient?.name ?? 'Consumidor Final (Venta Rápida)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (selectedClient != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textHint),
              onPressed: onClear,
            )
          else
            TextButton(onPressed: onSelect, child: const Text('Seleccionar')),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final int index;
  final InvoiceItemDraft item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final ValueChanged<int> onUpdate;

  const _ItemCard({
    required this.index,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onUpdate,
  });

  void _showQuantityDialog(
    BuildContext context,
    int current,
    ValueChanged<int> onConfirm,
  ) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cantidad'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nueva cantidad',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                onConfirm(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '\$${p.price.toStringAsFixed(2)} x ${item.quantity}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: onDecrement,
                  color: AppColors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                InkWell(
                  onTap: () =>
                      _showQuantityDialog(context, item.quantity, (val) {
                        onUpdate(val);
                      }),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: onIncrement,
                  color: AppColors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              '\$${item.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

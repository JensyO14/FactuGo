import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../clients/client.dart';
import '../clients/client_provider.dart';
import '../products/product.dart';
import '../products/product_provider.dart';
import 'invoice.dart';
import 'invoice_item.dart';
import 'invoice_provider.dart';
import '../business/business_provider.dart';
import '../business/business_profile.dart';

class InvoiceItemDraft {
  final Product product;
  int quantity;
  double get total => product.price * quantity;

  InvoiceItemDraft({required this.product, this.quantity = 1});
}

class InvoiceDraftState {
  final Client? client;
  final List<InvoiceItemDraft> items;
  final bool isSaving;
  final String? error;
  final BusinessProfile? businessProfile; // Add profile to state

  final String paymentMethod;
  final double amountTendered;
  final double discount; // New field

  const InvoiceDraftState({
    this.client,
    this.items = const [],
    this.paymentMethod = 'Contado',
    this.amountTendered = 0.0,
    this.discount = 0.0,
    this.isSaving = false,
    this.error,
    this.businessProfile,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get tax => 0; // Por ahora 0
  double get total => (subtotal + tax - discount).clamp(0.0, double.infinity);
  double get changeReturned =>
      amountTendered >= total ? amountTendered - total : 0.0;

  InvoiceDraftState copyWith({
    Client? client,
    List<InvoiceItemDraft>? items,
    String? paymentMethod,
    double? amountTendered,
    double? discount,
    bool? isSaving,
    String? error,
    bool clearClient = false,
    BusinessProfile? businessProfile,
  }) {
    return InvoiceDraftState(
      client: clearClient ? null : (client ?? this.client),
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountTendered: amountTendered ?? this.amountTendered,
      discount: discount ?? this.discount,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      businessProfile: businessProfile ?? this.businessProfile,
    );
  }
}

class InvoiceDraftNotifier extends Notifier<InvoiceDraftState> {
  @override
  InvoiceDraftState build() {
    return const InvoiceDraftState();
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setAmountTendered(double amount) {
    state = state.copyWith(amountTendered: amount);
  }

  void setDiscount(double discount) {
    // Validar que no sea mayor al subtotal (opcional, o clamps en total)
    // Aquí permitimos input libre, el total se clampa a 0.
    state = state.copyWith(discount: discount);
  }

  // ... (existing methods setClient, addItem, incrementQuantity, decrementQuantity, removeItem, clearError, reset)

  void setClient(Client? client) {
    state = state.copyWith(client: client, clearClient: client == null);
  }

  void addItem(Product product) {
    final items = List<InvoiceItemDraft>.from(state.items);
    final index = items.indexWhere((i) => i.product.id == product.id);

    // Business Logic: Read on demand
    final business = ref.read(businessProvider).asData?.value;

    // Default to PERMISSIVE (false) if business is null (not configured yet)
    // This ensures new users can sell immediately.
    final useInventory = business?.useInventory ?? false;
    final allowNegative = business?.allowNegativeStock ?? false;
    final requireStock = business?.requireStock ?? true;

    debugPrint('InvoiceDraft: business=$business');
    debugPrint(
      'InvoiceDraft: useInv=$useInventory, reqStock=$requireStock, allowNeg=$allowNegative, stock=${product.stock}',
    );

    // Check availability
    bool canAdd = true;
    if (useInventory && requireStock && !allowNegative) {
      if (index >= 0) {
        if (items[index].quantity >= product.stock) canAdd = false;
      } else {
        if (product.stock <= 0) canAdd = false;
      }
    }

    if (index >= 0) {
      if (canAdd) {
        items[index].quantity++;
        state = state.copyWith(items: items, error: null);
      } else {
        state = state.copyWith(
          error: 'Stock máximo alcanzado para ${product.name}',
        );
      }
    } else {
      if (canAdd) {
        items.add(InvoiceItemDraft(product: product));
        state = state.copyWith(items: items, error: null);
      } else {
        state = state.copyWith(error: 'Producto sin stock');
      }
    }
  }

  void incrementQuantity(int index) {
    final items = List<InvoiceItemDraft>.from(state.items);
    final item = items[index];

    // Business Logic
    final business = ref.read(businessProvider).asData?.value;
    final useInventory = business?.useInventory ?? false;
    final allowNegative = business?.allowNegativeStock ?? false;
    final requireStock = business?.requireStock ?? true;

    bool canIncrement = true;
    if (useInventory && requireStock && !allowNegative) {
      if (item.quantity >= item.product.stock) canIncrement = false;
    }

    if (canIncrement) {
      item.quantity++;
      state = state.copyWith(items: items);
    }
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final items = List<InvoiceItemDraft>.from(state.items);
    final item = items[index];

    // Business Logic
    final business = ref.read(businessProvider).asData?.value;
    final useInventory = business?.useInventory ?? false;
    final allowNegative = business?.allowNegativeStock ?? false;
    final requireStock = business?.requireStock ?? true;

    bool canUpdate = true;
    if (useInventory && requireStock && !allowNegative) {
      if (newQuantity > item.product.stock) canUpdate = false;
    }

    if (canUpdate) {
      item.quantity = newQuantity;
      state = state.copyWith(items: items, error: null);
    } else {
      state = state.copyWith(
        error:
            'Stock insuficiente para ${item.product.name} (Max: ${item.product.stock})',
      );
    }
  }

  void decrementQuantity(int index) {
    final items = List<InvoiceItemDraft>.from(state.items);
    if (items[index].quantity > 1) {
      items[index].quantity--;
      state = state.copyWith(items: items);
    } else {
      removeItem(index);
    }
  }

  void removeItem(int index) {
    final items = List<InvoiceItemDraft>.from(state.items);
    items.removeAt(index);
    state = state.copyWith(items: items);
  }

  void clearError() {
    state = state.copyWith(error: null); // Reset error msg after showing
  }

  void reset() {
    state = const InvoiceDraftState();
  }

  Future<bool> saveInvoice() async {
    if (state.items.isEmpty) return false;

    // Validar pago si es contado
    if (state.paymentMethod == 'Contado' &&
        state.amountTendered < state.total) {
      state = state.copyWith(error: 'El monto pagado es menor al total');
      return false;
    }

    // Validar cliente obligatoriamente si es a crédito
    // No permitir null ni "Consumidor Final" (ID 1)
    if (state.paymentMethod == 'Credito' &&
        (state.client == null || state.client?.id == 1)) {
      state = state.copyWith(
        error:
            'Debe seleccionar un cliente real para ventas a crédito (no Consumidor Final)',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      int clientId;
      if (state.client != null) {
        clientId = state.client!.id!;
      } else {
        clientId = await ref
            .read(clientNotifierProvider.notifier)
            .ensureDefaultClient();
      }

      final now = DateTime.now();

      final invoice = Invoice(
        clientId: clientId,
        number:
            'F-${now.millisecondsSinceEpoch}', // Will be overwritten by repo sequential logic but we keep placeholder
        date: now,
        subtotal: state.subtotal,
        tax: state.tax,
        total: state.total,
        discount: state.discount,
        status: state.paymentMethod == 'Contado' ? 'pagada' : 'pendiente',
        paymentMethod: state.paymentMethod,
        amountTendered: state.amountTendered,
        changeReturned: state.changeReturned,
        createdAt: now,
        updatedAt: now,
      );

      final invoiceItems = state.items
          .map(
            (draft) => InvoiceItem(
              invoiceId: 0,
              productId: draft.product.id!,
              quantity: draft.quantity.toDouble(),
              unitPrice: draft.product.price,
              total: draft.total,
              createdAt: now,
              updatedAt: now,
            ),
          )
          .toList();

      final business = ref.read(businessProvider).asData?.value;
      await ref
          .read(invoiceNotifierProvider.notifier)
          .create(
            invoice,
            invoiceItems,
            deductStock: business?.useInventory ?? false,
          );

      // Actualizar stock de productos
      ref.invalidate(productNotifierProvider);

      // Reset draft after success (keeping profile)
      reset();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final invoiceDraftProvider =
    NotifierProvider.autoDispose<InvoiceDraftNotifier, InvoiceDraftState>(
      InvoiceDraftNotifier.new,
    );

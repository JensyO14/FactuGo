import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'product.dart';
import 'product_provider.dart';
import 'product_search_delegate.dart';
import '../categories/category.dart';
import '../categories/category_provider.dart';

/// Body de productos para MainShell.
class ProductsBodyWidget extends ConsumerWidget {
  const ProductsBodyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productNotifierProvider);
    return Stack(
      children: [
        productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (products) => products.isEmpty
              ? const _EmptyState()
              : _ProductList(products: products),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showProductForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo producto'),
          ),
        ),
      ],
    );
  }
}

/// Botón de búsqueda para el AppBar de Productos.
class ProductsSearchAction extends ConsumerWidget {
  const ProductsSearchAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () async {
        final products = ref.read(productNotifierProvider).value ?? [];
        await showSearch(
          context: context,
          delegate: ProductSearchDelegate(products),
        );
      },
    );
  }
}

// ─── Lista ───────────────────────────────────────────────────────────────────

class _ProductList extends ConsumerWidget {
  final List<Product> products;
  const _ProductList({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ProductCard(product: products[index]),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Category> categories =
        ref.watch(categoryNotifierProvider).asData?.value ?? const [];

    // Find category name or use default
    String categoryName = '';
    if (product.categoryId != null) {
      try {
        final category = categories.firstWhere(
          (c) => c.id == product.categoryId,
        );
        categoryName = category.name;
      } catch (_) {
        // Category not found
      }
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showProductForm(context, ref, product: product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono / indicador
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Tag(
                          label: 'Stock: ${product.stock.toStringAsFixed(0)}',
                          color: product.stock > 0
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          textColor: product.stock > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        if (product.sku != null) ...[
                          const SizedBox(width: 6),
                          _Tag(
                            label: 'SKU: ${product.sku}',
                            color: AppColors.surfaceVariant,
                            textColor: AppColors.textSecondary,
                          ),
                        ],
                        if (categoryName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _Tag(
                            label: categoryName,
                            color: AppColors.primaryLight,
                            textColor: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Precio
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                        ),
                        onPressed: () =>
                            _showAddStockDialog(context, ref, product),
                        tooltip: 'Sumar Stock',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 30),
                        ),
                        onPressed: () => _confirmDelete(context, ref, product),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
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
      await ref.read(productNotifierProvider.notifier).remove(product.id!);
    }
  }
}

// ─── Tag ─────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Tag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

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
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin productos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Agrega tu primer producto con el botón +',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error: $message',
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }
}

// ─── Formulario (Modal Bottom Sheet) ─────────────────────────────────────────

void _showProductForm(BuildContext context, WidgetRef ref, {Product? product}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProductForm(product: product),
  );
}

class ProductForm extends ConsumerStatefulWidget {
  final Product? product;
  const ProductForm({super.key, this.product});

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _skuCtrl;
  int? _categoryId;
  bool _saving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _stockCtrl = TextEditingController(
      text: p != null ? p.stock.toString() : '0',
    );
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _categoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    final sku = _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim();
    final editId = widget.product?.id;

    try {
      // Validar nombre único contra la lista ya cargada
      final products = await ref.read(productNotifierProvider.future);
      final nameTaken = products.any(
        (p) => p.name.toLowerCase() == name.toLowerCase() && p.id != editId,
      );
      if (nameTaken) {
        if (mounted) {
          setState(
            () => _errorMsg = 'Ya existe un producto con el nombre "$name".',
          );
        }
        return;
      }

      final now = DateTime.now();
      final notifier = ref.read(productNotifierProvider.notifier);

      if (widget.product == null) {
        await notifier.add(
          Product(
            name: name,
            description: desc,
            price: double.parse(_priceCtrl.text.trim()),
            stock: double.parse(_stockCtrl.text.trim()),
            sku: sku,
            categoryId: _categoryId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await notifier.edit(
          widget.product!.copyWith(
            name: name,
            description: desc,
            price: double.parse(_priceCtrl.text.trim()),
            stock: double.parse(_stockCtrl.text.trim()),
            sku: sku,
            categoryId: _categoryId,
            updatedAt: now,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMsg = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
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
                isEdit ? 'Editar producto' : 'Nuevo producto',
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
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Ej: Camisa azul'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              // Descripción
              _Label('Descripción (opcional)'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Descripción del producto',
                ),
              ),
              const SizedBox(height: 14),

              // Precio y stock en fila
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Precio *'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(prefixText: '\$ '),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requerido';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Stock'),
                        TextFormField(
                          controller: _stockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(hintText: '0'),
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                double.tryParse(v) == null) {
                              return 'Inválido';
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

              // SKU (opcional)
              _Label('SKU / Código (opcional)'),
              TextFormField(
                controller: _skuCtrl,
                decoration: const InputDecoration(hintText: 'Ej: PROD-001'),
              ),
              const SizedBox(height: 10),

              // Selector de Categoría
              Consumer(
                builder: (context, ref, child) {
                  final categoriesAsync = ref.watch(categoryNotifierProvider);
                  return categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                    data: (categories) {
                      // Validar que el valor seleccionado exista en la lista
                      final exists = categories.any((c) => c.id == _categoryId);
                      // Si no existe (y no es nulo), resetear a null para evitar crash
                      if (_categoryId != null && !exists) {
                        // Podríamos avisar o simplemente asignarlo a null visualmente
                        // Mantenerlo en _categoryId variable PERO pasar null al widget
                      }
                      final effectiveValue = exists ? _categoryId : null;

                      return DropdownButtonFormField<int>(
                        value: effectiveValue,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _categoryId = val);
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Banner de error inline
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

void _showAddStockDialog(BuildContext context, WidgetRef ref, Product product) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Sumar Stock: ${product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Stock actual: ${product.stock}'),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Cantidad a agregar',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.add),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final quantity = int.tryParse(controller.text);
            if (quantity != null && quantity > 0) {
              await ref
                  .read(productNotifierProvider.notifier)
                  .addStock(product.id!, quantity);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Se agregaron $quantity unidades a ${product.name}',
                    ),
                  ),
                );
              }
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    ),
  );
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

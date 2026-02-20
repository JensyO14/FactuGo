import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'expense.dart';
import 'expense_category.dart';
import 'expense_provider.dart';

class ExpensesBodyWidget extends ConsumerWidget {
  const ExpensesBodyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseNotifierProvider);

    return Stack(
      children: [
        expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (expenses) {
            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay gastos registrados',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toca el botón + para registrar un gasto',
                      style: TextStyle(fontSize: 14, color: AppColors.textHint),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return _ExpenseCard(expense: expense);
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showExpenseForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo gasto'),
          ),
        ),
      ],
    );
  }

  void _showExpenseForm(
    BuildContext context,
    WidgetRef ref, {
    Expense? expense,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpenseFormSheet(expense: expense),
    );
  }
}

// ─── Expense Card ────────────────────────────────────────────────────────────

class _ExpenseCard extends ConsumerWidget {
  final Expense expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountStr = NumberFormat.simpleCurrency(
      decimalDigits: 2,
    ).format(expense.amount);
    final dateStr = DateFormat('dd/MM/yyyy').format(expense.date);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(
            Icons.trending_down,
            color: AppColors.error,
            size: 22,
          ),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${expense.categoryName ?? 'Sin categoría'} • $dateStr',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amountStr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => _ExpenseFormSheet(expense: expense),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context, ref, expense);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${expense.description}"?'),
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
      await ref.read(expenseNotifierProvider.notifier).remove(expense.id!);
    }
  }
}

// ─── Expense Form Bottom Sheet ───────────────────────────────────────────────

class _ExpenseFormSheet extends ConsumerStatefulWidget {
  final Expense? expense;
  const _ExpenseFormSheet({this.expense});

  @override
  ConsumerState<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _selectedDate;
  int? _selectedCategoryId;
  bool _isCreatingCategory = false;
  late TextEditingController _newCatNameCtrl;
  late TextEditingController _newCatDescCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _selectedDate = e?.date ?? DateTime.now();
    _selectedCategoryId = e?.expenseCategoryId;
    _newCatNameCtrl = TextEditingController();
    _newCatDescCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _newCatNameCtrl.dispose();
    _newCatDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Normalize selected date to local date-only to avoid UTC timezone issues
    final initDate = DateTime(
      _selectedDate.toLocal().year,
      _selectedDate.toLocal().month,
      _selectedDate.toLocal().day,
    );
    // Clamp to today if somehow initDate is in the future
    final safeInitDate = initDate.isAfter(today) ? today : initDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitDate,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    int categoryId = _selectedCategoryId ?? 0;

    // If creating a new category inline
    if (_isCreatingCategory) {
      final catName = _newCatNameCtrl.text.trim();
      if (catName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre de la categoría es requerido'),
          ),
        );
        return;
      }
      final now = DateTime.now();
      final newCat = ExpenseCategory(
        name: catName,
        description: _newCatDescCtrl.text.trim().isEmpty
            ? null
            : _newCatDescCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      categoryId = await ref
          .read(expenseCategoryNotifierProvider.notifier)
          .add(newCat);
    }

    if (categoryId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona o crea una categoría')),
      );
      return;
    }

    final now = DateTime.now();
    final notifier = ref.read(expenseNotifierProvider.notifier);

    if (widget.expense != null) {
      // Edit existing
      await notifier.edit(
        widget.expense!.copyWith(
          expenseCategoryId: categoryId,
          description: _descCtrl.text.trim(),
          amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
          date: _selectedDate,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          updatedAt: now,
        ),
      );
    } else {
      // Create new
      await notifier.add(
        Expense(
          expenseCategoryId: categoryId,
          description: _descCtrl.text.trim(),
          amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
          date: _selectedDate,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;
    final categoriesAsync = ref.watch(expenseCategoryNotifierProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Handle bar ──
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

                // ── Title ──
                Text(
                  isEdit ? 'Editar Gasto' : 'Nuevo Gasto',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Descripción ──
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción *',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // ── Monto ──
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Monto *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Fecha ──
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha *',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Categoría ──
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error cargando categorías'),
                  data: (categories) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int>(
                          value: _isCreatingCategory ? -1 : _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoría *',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: [
                            ...categories.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                            const DropdownMenuItem(
                              value: -1,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Crear nueva categoría',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == -1) {
                                _isCreatingCategory = true;
                                _selectedCategoryId = null;
                              } else {
                                _isCreatingCategory = false;
                                _selectedCategoryId = value;
                              }
                            });
                          },
                          validator: (v) {
                            if (!_isCreatingCategory &&
                                _selectedCategoryId == null) {
                              return 'Selecciona una categoría';
                            }
                            return null;
                          },
                        ),
                        // ── Inline new category fields ──
                        if (_isCreatingCategory) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(60),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.new_label_outlined,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Nueva categoría de gasto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _newCatNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre de categoría *',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _newCatDescCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción (opcional)',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Notas ──
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // ── Actions ──
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
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: Icon(isEdit ? Icons.save : Icons.add),
                        label: Text(isEdit ? 'Guardar' : 'Registrar gasto'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

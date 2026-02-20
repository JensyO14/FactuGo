import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expense.dart';
import 'expense_category.dart';
import 'expense_repository.dart';
import 'expense_category_repository.dart';

final _expenseRepo = ExpenseRepository();
final _expenseCategoryRepo = ExpenseCategoryRepository();

// ─── Expense Category Providers ──────────────────────────────────────────────

class ExpenseCategoryNotifier extends AsyncNotifier<List<ExpenseCategory>> {
  @override
  Future<List<ExpenseCategory>> build() => _expenseCategoryRepo.getAll();

  Future<int> add(ExpenseCategory category) async {
    final id = await _expenseCategoryRepo.insert(category);
    ref.invalidateSelf();
    return id;
  }

  Future<void> edit(ExpenseCategory category) async {
    await _expenseCategoryRepo.update(category);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _expenseCategoryRepo.delete(id);
    ref.invalidateSelf();
  }
}

final expenseCategoryNotifierProvider =
    AsyncNotifierProvider<ExpenseCategoryNotifier, List<ExpenseCategory>>(
      ExpenseCategoryNotifier.new,
    );

// ─── Expense Providers ───────────────────────────────────────────────────────

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() => _expenseRepo.getAll();

  Future<void> add(Expense expense) async {
    await _expenseRepo.insert(expense);
    ref.invalidateSelf();
  }

  Future<void> edit(Expense expense) async {
    await _expenseRepo.update(expense);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _expenseRepo.delete(id);
    ref.invalidateSelf();
  }
}

final expenseNotifierProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(ExpenseNotifier.new);

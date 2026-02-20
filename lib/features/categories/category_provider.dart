import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category.dart';
import 'category_repository.dart';

final _categoryRepo = CategoryRepository();

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return _categoryRepo.getAll();
});

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() => _categoryRepo.getAll();

  Future<void> add(Category category) async {
    await _categoryRepo.insert(category);
    ref.invalidateSelf();
  }

  Future<void> edit(Category category) async {
    await _categoryRepo.update(category);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _categoryRepo.delete(id);
    ref.invalidateSelf();
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
      CategoryNotifier.new,
    );

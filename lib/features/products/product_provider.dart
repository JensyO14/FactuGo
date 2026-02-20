import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product.dart';
import 'product_repository.dart';

final _productRepo = ProductRepository();

class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() => _productRepo.getAll();

  Future<void> add(Product product) async {
    await _productRepo.insert(product);
    ref.invalidateSelf();
  }

  Future<void> edit(Product product) async {
    await _productRepo.update(product);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _productRepo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> addStock(int id, int quantity) async {
    await _productRepo.addStock(id, quantity);
    ref.invalidateSelf();
  }
}

final productNotifierProvider =
    AsyncNotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);

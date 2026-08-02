import 'package:signals_flutter/signals_flutter.dart';
import '../core/database/change_tracker.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';

class ProductController {
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final DatabaseChangeTracker _changeTracker = DatabaseChangeTracker();

  ProductController(this._productRepository, this._categoryRepository);

  final products = listSignal<ProductModel>([]);
  final categories = listSignal<CategoryModel>([]);
  final isLoading = signal(false);
  final error = signal<String?>(null);

  final searchFilter = signal<String>('');
  final categoryFilter = signal<int?>(null);

  Future<void> init() async {
    await loadCategories();
    await loadProducts();
  }

  Future<void> loadCategories() async {
    try {
      final list = await _categoryRepository.getAll();
      categories.value = list;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    error.value = null;
    try {
      final list = await _productRepository.getAll(
        search: searchFilter.value,
        categoryId: categoryFilter.value,
      );
      products.value = list;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String query) {
    searchFilter.value = query;
    loadProducts();
  }

  void updateCategoryFilter(int? catId) {
    categoryFilter.value = catId;
    loadProducts();
  }

  /// Adiciona um novo produto. Não recebe mais quantity nem unidade de medida,
  /// pois o saldo é calculado dinamicamente pelas movimentações.
  Future<void> addProduct({
    required String name,
    required int categoryId,
    String? volume,
  }) async {
    isLoading.value = true;
    error.value = null;
    try {
      final prod = ProductModel(
        name: name,
        categoryId: categoryId,
        volume: volume?.trim().isEmpty == true ? null : volume?.trim(),
      );
      await _productRepository.insert(prod);
      _changeTracker.markChanged();
      await loadProducts();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Cria ou seleciona uma categoria inline no formulário de produto.
  Future<CategoryModel> addCategoryIfNeeded(String name) async {
    final existing = categories.value.where(
      (c) => c.name.toLowerCase() == name.trim().toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;

    final id = await _categoryRepository.insert(
      CategoryModel(name: name.trim()),
    );
    _changeTracker.markChanged();
    await loadCategories();
    return categories.value.firstWhere((c) => c.id == id);
  }

  Future<void> editProduct(ProductModel product) async {
    isLoading.value = true;
    error.value = null;
    try {
      await _productRepository.update(product);
      _changeTracker.markChanged();
      await loadProducts();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(int id) async {
    isLoading.value = true;
    error.value = null;
    try {
      await _productRepository.delete(id);
      _changeTracker.markChanged();
      await loadProducts();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}

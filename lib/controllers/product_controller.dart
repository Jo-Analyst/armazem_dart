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

  static const int _pageSize = 10;
  int _productPage = 0;
  final hasMoreProducts = signal(true);
  bool _isLoadingMoreProducts = false;

  bool get isLoadingMoreProducts => _isLoadingMoreProducts;

  Future<void> init() async {
    resetFilters();
    await loadCategories();
    await loadProducts(reset: true);
  }

  void resetFilters() {
    searchFilter.value = '';
    categoryFilter.value = null;
  }

  Future<void> loadCategories() async {
    try {
      final list = await _categoryRepository.getAll();
      categories.value = list;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> loadProducts({bool reset = true}) async {
    if (reset) {
      _productPage = 0;
      hasMoreProducts.value = true;
      products.value = [];
    }

    if (!hasMoreProducts.value || _isLoadingMoreProducts) return;

    if (reset) {
      isLoading.value = true;
    } else {
      _isLoadingMoreProducts = true;
    }
    error.value = null;

    try {
      final list = await _productRepository.getAll(
        search: searchFilter.value,
        categoryId: categoryFilter.value,
        limit: _pageSize,
        offset: _productPage * _pageSize,
      );

      if (reset) {
        products.value = list;
      } else {
        products.value = [...products.value, ...list];
      }

      hasMoreProducts.value = list.length == _pageSize;
      if (hasMoreProducts.value) {
        _productPage++;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        _isLoadingMoreProducts = false;
      }
    }
  }

  void updateSearch(String query) {
    searchFilter.value = query;
    loadProducts(reset: true);
  }

  void updateCategoryFilter(int? catId) {
    categoryFilter.value = catId;
    loadProducts(reset: true);
  }

  /// Adiciona um novo produto. Não recebe mais quantity nem unidade de medida,
  /// pois o saldo é calculado dinamicamente pelas movimentações.
  Future<void> addProduct({
    required String name,
    required int categoryId,
    String? volume,
  }) async {
    // Verifica se já existe produto com mesmo nome e volume
    final exists = await _productRepository.existsByNameAndVolume(name, volume);
    if (exists) {
      throw Exception('Já existe um produto com este nome e volume.');
    }
    
    final prod = ProductModel(
      name: name,
      categoryId: categoryId,
      volume: volume?.trim().isEmpty == true ? null : volume?.trim(),
    );
    await _productRepository.insert(prod);
    _changeTracker.markChanged();
    await loadProducts();
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
    // Verifica se já existe produto com mesmo nome e volume (excluindo o próprio)
    final exists = await _productRepository.existsByNameAndVolume(
      product.name,
      product.volume,
      excludeId: product.id,
    );
    if (exists) {
      throw Exception('Já existe um produto com este nome e volume.');
    }
    
    await _productRepository.update(product);
    _changeTracker.markChanged();
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _productRepository.delete(id);
    _changeTracker.markChanged();
    await loadProducts();
  }
}

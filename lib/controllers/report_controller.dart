import 'package:signals_flutter/signals_flutter.dart';
import '../models/movement_model.dart';
import '../models/product_model.dart';
import '../repositories/movement_repository.dart';
import '../repositories/product_repository.dart';

class ProductFilterOption {
  final String name;
  final List<int> productIds;

  ProductFilterOption({required this.name, required this.productIds});
}

List<ProductFilterOption> buildProductFilterOptions(
  List<ProductModel> products,
) {
  final groupedProducts = <String, List<ProductModel>>{};

  for (final product in products) {
    final key = product.name.trim().toLowerCase();
    groupedProducts.putIfAbsent(key, () => <ProductModel>[]).add(product);
  }

  final options = groupedProducts.entries.map((entry) {
    final matchingProducts = entry.value;
    final firstProduct = matchingProducts.first;

    return ProductFilterOption(
      name: firstProduct.name,
      productIds: matchingProducts
          .map((product) => product.id)
          .whereType<int>()
          .toList(),
    );
  }).toList();

  options.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return options;
}

List<MovementModel> filterMovementsByProductName(
  List<MovementModel> movements,
  String? selectedProductName,
  List<ProductFilterOption> filterOptions,
) {
  if (selectedProductName == null || selectedProductName.isEmpty) {
    return movements;
  }

  final selectedOption = filterOptions.firstWhere(
    (option) => option.name == selectedProductName,
    orElse: () => ProductFilterOption(name: '', productIds: const []),
  );

  if (selectedOption.productIds.isEmpty) {
    return movements;
  }

  return movements
      .where(
        (movement) => selectedOption.productIds.contains(movement.productId),
      )
      .toList();
}

class ReportController {
  final MovementRepository _movementRepository;
  final ProductRepository _productRepository;

  ReportController(this._movementRepository, this._productRepository);

  final movements = listSignal<MovementModel>([]);
  final products = listSignal<ProductFilterOption>([]);
  final isLoading = signal(false);
  final error = signal<String?>(null);
  final selectedProductName = signal<String?>(null);

  final startDate = signal<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month, 1),
  );
  final endDate = signal<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  Future<void> init() async {
    resetFilters();
    await _loadProducts();
    await loadReport();
  }

  void resetFilters() {
    selectedProductName.value = null;
    startDate.value = DateTime(DateTime.now().year, DateTime.now().month, 1);
    endDate.value = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  }

  Future<void> _loadProducts() async {
    try {
      final allProducts = await _productRepository.getAll();
      products.value = buildProductFilterOptions(allProducts);
    } catch (_) {
      products.value = [];
    }
  }

  Future<void> loadReport() async {
    isLoading.value = true;
    error.value = null;
    try {
      final startStr = startDate.value.toIso8601String().split('T').first;
      final endStr = endDate.value.toIso8601String().split('T').first;
      var list = await _movementRepository.getByPeriod(startStr, endStr);

      list = filterMovementsByProductName(
        list,
        selectedProductName.value,
        products.value,
      );

      movements.value = list;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void updatePeriod(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    loadReport();
  }

  void updateProductFilter(String? productName) {
    selectedProductName.value = productName;
    loadReport();
  }

  double get totalEntradas => movements.value
      .where((m) => m.type == 'ENTRADA')
      .fold(0.0, (sum, m) => sum + m.quantity);

  double get totalSaidas => movements.value
      .where((m) => m.type == 'SAIDA')
      .fold(0.0, (sum, m) => sum + m.quantity);
}

import 'package:signals_flutter/signals_flutter.dart';
import '../core/utils/error_utils.dart';
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

  static const int _pageSize = 10;
  int _reportPage = 0;
  final hasMoreReport = signal(true);
  bool _isLoadingMoreReport = false;

  bool get isLoadingMoreReport => _isLoadingMoreReport;

  final startDate = signal<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month, 1),
  );
  final endDate = signal<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  Future<void> init() async {
    resetFilters();
    await _loadProducts();
    await loadReport(reset: true);
  }

  void resetFilters() {
    selectedProductName.value = null;
    _reportPage = 0;
    hasMoreReport.value = true;
    _isLoadingMoreReport = false;
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

  Future<void> loadReport({bool reset = true}) async {
    if (reset) {
      _reportPage = 0;
      hasMoreReport.value = true;
      movements.value = [];
    }

    if (!hasMoreReport.value || _isLoadingMoreReport) return;

    if (reset) {
      isLoading.value = true;
    } else {
      _isLoadingMoreReport = true;
    }
    error.value = null;

    try {
      final startStr = startDate.value.toIso8601String().split('T').first;
      final endStr = endDate.value.toIso8601String().split('T').first;
      final productIds = _getSelectedProductIds();

      final list = await _movementRepository.getByPeriod(
        startStr,
        endStr,
        productIds: productIds,
        limit: _pageSize,
        offset: _reportPage * _pageSize,
      );

      if (reset) {
        movements.value = list;
      } else {
        movements.value = [...movements.value, ...list];
      }

      hasMoreReport.value = list.length == _pageSize;
      if (hasMoreReport.value) {
        _reportPage++;
      }
    } catch (e) {
      error.value = cleanErrorMessage(e);
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        _isLoadingMoreReport = false;
      }
    }
  }

  List<int>? _getSelectedProductIds() {
    if (selectedProductName.value == null ||
        selectedProductName.value!.isEmpty) {
      return null;
    }

    final selectedOption = products.value.firstWhere(
      (option) => option.name == selectedProductName.value,
      orElse: () => ProductFilterOption(name: '', productIds: const []),
    );

    return selectedOption.productIds.isEmpty ? null : selectedOption.productIds;
  }

  void updatePeriod(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    loadReport(reset: true);
  }

  void updateProductFilter(String? productName) {
    selectedProductName.value = productName;
    loadReport(reset: true);
  }

  Future<List<MovementModel>> fetchFullReport() async {
    final startStr = startDate.value.toIso8601String().split('T').first;
    final endStr = endDate.value.toIso8601String().split('T').first;
    final productIds = _getSelectedProductIds();

    return await _movementRepository.getByPeriod(
      startStr,
      endStr,
      productIds: productIds,
    );
  }

  double get totalEntradas => movements.value
      .where((m) => m.type == 'ENTRADA')
      .fold(0.0, (sum, m) => sum + m.quantity);

  double get totalSaidas => movements.value
      .where((m) => m.type == 'SAIDA')
      .fold(0.0, (sum, m) => sum + m.quantity);
}

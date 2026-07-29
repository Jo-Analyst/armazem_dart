import 'package:signals_flutter/signals_flutter.dart';
import '../models/movement_model.dart';
import '../models/product_model.dart';
import '../repositories/movement_repository.dart';
import '../repositories/product_repository.dart';

class ReportController {
  final MovementRepository _movementRepository;
  final ProductRepository _productRepository;

  ReportController(this._movementRepository, this._productRepository);

  final movements = listSignal<MovementModel>([]);
  final products = listSignal<ProductModel>([]); // Para filtro por produto
  final isLoading = signal(false);
  final error = signal<String?>(null);
  final selectedProductId = signal<int?>(null);

  final startDate = signal<DateTime>(
    DateTime.now().subtract(const Duration(days: 30)),
  );
  final endDate = signal<DateTime>(DateTime.now());

  Future<void> init() async {
    await _loadProducts();
    await loadReport();
  }

  Future<void> _loadProducts() async {
    try {
      products.value = await _productRepository.getAll();
    } catch (_) {}
  }

  Future<void> loadReport() async {
    isLoading.value = true;
    error.value = null;
    try {
      final startStr = startDate.value.toIso8601String().split('T').first;
      final endStr = endDate.value.toIso8601String().split('T').first;
      var list = await _movementRepository.getByPeriod(startStr, endStr);

      // Filtro opcional por produto
      if (selectedProductId.value != null) {
        list = list
            .where((m) => m.produtoId == selectedProductId.value)
            .toList();
      }

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

  void updateProductFilter(int? productId) {
    selectedProductId.value = productId;
    loadReport();
  }

  double get totalEntradas => movements.value
      .where((m) => m.tipo == 'ENTRADA')
      .fold(0.0, (sum, m) => sum + m.quantidade);

  double get totalSaidas => movements.value
      .where((m) => m.tipo == 'SAIDA')
      .fold(0.0, (sum, m) => sum + m.quantidade);
}

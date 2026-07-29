import 'package:signals_flutter/signals_flutter.dart';
import '../models/movement_model.dart';
import '../models/product_model.dart';
import '../repositories/movement_repository.dart';
import '../repositories/product_repository.dart';

class MovementController {
  final MovementRepository _movementRepository;
  final ProductRepository _productRepository;

  MovementController(this._movementRepository, this._productRepository);

  final movements = listSignal<MovementModel>([]);
  final products = listSignal<ProductModel>([]);
  final isLoading = signal(false);
  final error = signal<String?>(null);

  Future<void> init() async {
    await loadProducts();
    await loadMovements();
  }

  Future<void> loadProducts() async {
    try {
      final list = await _productRepository.getAll();
      products.value = list;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> loadMovements() async {
    isLoading.value = true;
    error.value = null;
    try {
      final list = await _movementRepository.getAll();
      movements.value = list;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifica o saldo atual de um produto antes de permitir SAIDA na UI
  Future<double> getSaldoProduto(int produtoId) async {
    return await _movementRepository.getSaldoProduto(produtoId);
  }

  /// Registra uma nova movimentação com todas as validações de negócio.
  /// Lança [Exception] em caso de violação de regras.
  Future<void> registerMovement({
    required int produtoId,
    required String tipo,
    required double quantidade,
    required String unidadeMedida,
    required String dataEntrada,
    String? dataSaida,
    String? observacao,
  }) async {
    isLoading.value = true;
    error.value = null;
    try {
      // Validação prévia de saldo na UI (antes de chegar ao repositório)
      if (tipo == 'SAIDA') {
        final saldo = await getSaldoProduto(produtoId);
        if (saldo <= 0) {
          throw Exception(
            'Saldo zerado. Registre uma nova ENTRADA antes de registrar saída.',
          );
        }
      }

      final mov = MovementModel(
        produtoId: produtoId,
        tipo: tipo,
        quantidade: quantidade,
        unidadeMedida: unidadeMedida,
        dataEntrada: dataEntrada,
        dataSaida: dataSaida,
        observacao: observacao,
      );

      await _movementRepository.createMovement(mov);
      await loadMovements();
      await loadProducts(); // Atualiza saldo exibido nos produtos
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}

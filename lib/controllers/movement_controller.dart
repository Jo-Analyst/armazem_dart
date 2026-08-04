import 'package:signals_flutter/signals_flutter.dart';
import '../core/database/change_tracker.dart';
import '../core/utils/error_utils.dart';
import '../models/movement_model.dart';
import '../models/product_model.dart';
import '../repositories/movement_repository.dart';
import '../repositories/product_repository.dart';

class MovementController {
  final MovementRepository _movementRepository;
  final ProductRepository _productRepository;
  final DatabaseChangeTracker _changeTracker = DatabaseChangeTracker();

  MovementController(this._movementRepository, this._productRepository);

  final movements = listSignal<MovementModel>([]);
  final products = listSignal<ProductModel>([]);
  final isLoading = signal(false);
  final error = signal<String?>(null);

  static const int _pageSize = 10;
  int _movementPage = 0;
  final hasMoreMovements = signal(true);
  bool _isLoadingMoreMovements = false;

  bool get isLoadingMoreMovements => _isLoadingMoreMovements;

  Future<void> init() async {
    await loadProducts();
    await loadMovements(reset: true);
  }

  Future<void> loadProducts() async {
    try {
      final list = await _productRepository.getAll();
      products.value = list;
    } catch (e) {
      error.value = cleanErrorMessage(e);
    }
  }

  Future<void> loadMovements({bool reset = true}) async {
    if (reset) {
      _movementPage = 0;
      hasMoreMovements.value = true;
      movements.value = [];
    }

    if (!hasMoreMovements.value || _isLoadingMoreMovements) return;

    if (reset) {
      isLoading.value = true;
    } else {
      _isLoadingMoreMovements = true;
    }
    error.value = null;

    try {
      final list = await _movementRepository.getAll(
        limit: _pageSize,
        offset: _movementPage * _pageSize,
      );

      if (reset) {
        movements.value = list;
      } else {
        movements.value = [...movements.value, ...list];
      }

      hasMoreMovements.value = list.length == _pageSize;
      if (hasMoreMovements.value) {
        _movementPage++;
      }
    } catch (e) {
      error.value = cleanErrorMessage(e);
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        _isLoadingMoreMovements = false;
      }
    }
  }

  /// Verifica o saldo atual de um produto antes de permitir SAIDA na UI
  Future<double> getSaldoProduto(int productId) async {
    return await _movementRepository.getSaldoProduto(productId);
  }

  /// Registra uma nova movimentação com todas as validações de negócio.
  /// Lança [Exception] em caso de violação de regras.
  Future<void> registerMovement({
    required int productId,
    required String type,
    required double quantity,
    required String unitOfMeasurement,
    required String dataEntry,
    String? dataExit,
    String? observation,
  }) async {
    // Validação prévia de saldo na UI (antes de chegar ao repositório)
    if (type == 'SAIDA') {
      final saldo = await getSaldoProduto(productId);
      if (saldo <= 0) {
        throw Exception(
          'Saldo zerado. Registre uma nova ENTRADA antes de registrar saída.',
        );
      }
    }

    final mov = MovementModel(
      productId: productId,
      type: type,
      quantity: quantity,
      unitOfMeasurement: unitOfMeasurement,
      dataEntry: dataEntry,
      dataExit: dataExit,
      observation: observation,
    );

    await _movementRepository.createMovement(mov);
    _changeTracker.markChanged();
    await loadMovements();
    await loadProducts(); // Atualiza saldo exibido nos produtos
  }

  /// Atualiza uma movimentação existente com as mesmas validações de negócio.
  /// Lança [Exception] em caso de violação de regras.
  Future<void> updateMovement(MovementModel movement) async {
    if (movement.id == null) {
      throw Exception('ID da movimentação é obrigatório para atualização.');
    }

    // Validação prévia de saldo na UI (antes de chegar ao repositório)
    if (movement.type == 'SAIDA') {
      final saldo = await getSaldoProduto(movement.productId);
      final movAtual = movements.value
          .where((m) => m.id == movement.id)
          .firstOrNull;
      double saldoDisponivel = saldo;
      if (movAtual != null && movAtual.type == 'SAIDA') {
        saldoDisponivel += movAtual.quantity;
      }
      if (saldoDisponivel <= 0) {
        throw Exception(
          'Saldo zerado. Registre uma nova ENTRADA antes de registrar saída.',
        );
      }
    }

    await _movementRepository.update(movement);
    _changeTracker.markChanged();
    await loadMovements();
    await loadProducts(); // Atualiza saldo exibido nos produtos
  }

  /// Remove uma movimentação pelo ID.
  Future<void> deleteMovement(int id) async {
    await _movementRepository.delete(id);
    _changeTracker.markChanged();
    await loadMovements();
    await loadProducts(); // Atualiza saldo exibido nos produtos
  }
}

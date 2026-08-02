import '../core/database/database_helper.dart';
import '../models/movement_model.dart';

class MovementRepository {
  final DatabaseHelper _dbHelper;

  MovementRepository(this._dbHelper);

  /// Retorna o saldo atual calculado de um produto (SUM ENTRADA - SUM SAIDA)
  Future<double> getSaldoProduto(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'ENTRADA' THEN quantity ELSE 0 END), 0.0) -
        COALESCE(SUM(CASE WHEN type = 'SAIDA' THEN quantity ELSE 0 END), 0.0) AS saldo
      FROM movements
      WHERE product_id = ?
    ''',
      [productId],
    );

    return (result.first['saldo'] as num?)?.toDouble() ?? 0.0;
  }

  /// Cria uma nova movimentação aplicando as regras de negócio:
  /// - SAIDA: bloqueia se saldo == 0
  /// - SAIDA: data_exit não pode ser anterior à data_entry
  Future<void> createMovement(MovementModel movement) async {
    final db = await _dbHelper.database;

    if (movement.type == 'SAIDA') {
      if (movement.dataExit == null || movement.dataExit!.isEmpty) {
        throw Exception(
          'A data de saída é obrigatória para movimentação de SAÍDA.',
        );
      }
      if (movement.dataEntry.isNotEmpty) {
        final entrada = DateTime.parse(movement.dataEntry);
        final saida = DateTime.parse(movement.dataExit!);
        if (saida.isBefore(entrada)) {
          throw Exception(
            'A data de saída (${_formatDate(movement.dataExit!)}) não pode ser '
            'anterior à data de entrada (${_formatDate(movement.dataEntry)}).',
          );
        }
      }

      // Validação: saldo deve ser > 0 para registrar saída
      final saldo = await getSaldoProduto(movement.productId);
      if (saldo <= 0) {
        throw Exception(
          'Saldo zerado. Não é possível registrar saída. '
          'Registre uma nova entrada antes de continuar.',
        );
      }
      if (movement.quantity > saldo) {
        throw Exception(
          'Quantidade de saída (${movement.quantity}) '
          'maior que o saldo disponível ($saldo).',
        );
      }
    } else if (movement.type == 'ENTRADA') {
      if (movement.dataEntry.isEmpty) {
        throw Exception(
          'A data de entrada é obrigatória para movimentação de ENTRADA.',
        );
      }
    } else {
      throw Exception('Tipo de movimentação inválido: ${movement.type}');
    }

    await db.insert('movements', movement.toMap());
  }

  Future<List<MovementModel>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.*, p.name AS product_name, p.volume AS product_volume
      FROM movements m
      INNER JOIN products p ON m.product_id = p.id
      ORDER BY m.data_entry DESC
    ''');
    return List.generate(maps.length, (i) => MovementModel.fromMap(maps[i]));
  }

  Future<List<MovementModel>> getByPeriod(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.*, p.name AS product_name, p.volume AS product_volume
      FROM movements m
      INNER JOIN products p ON m.product_id = p.id
      WHERE DATE(
        CASE
          WHEN m.type = 'SAIDA' AND (m.data_entry IS NULL OR m.data_entry = '')
            THEN m.data_exit
          ELSE m.data_entry
        END
      ) >= DATE(?)
        AND DATE(
          CASE
            WHEN m.type = 'SAIDA' AND (m.data_entry IS NULL OR m.data_entry = '')
              THEN m.data_exit
            ELSE m.data_entry
          END
        ) <= DATE(?)
      ORDER BY
        CASE
          WHEN m.type = 'SAIDA' AND (m.data_entry IS NULL OR m.data_entry = '')
            THEN m.data_exit
          ELSE m.data_entry
        END DESC
    ''',
      [startDate, endDate],
    );
    return List.generate(maps.length, (i) => MovementModel.fromMap(maps[i]));
  }

  Future<List<MovementModel>> getByProduto(int productId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.*, p.name AS product_name, p.volume AS product_volume
      FROM movements m
      INNER JOIN products p ON m.product_id = p.id
      WHERE m.product_id = ?
      ORDER BY m.data_entry DESC
    ''',
      [productId],
    );
    return List.generate(maps.length, (i) => MovementModel.fromMap(maps[i]));
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('movements', where: 'id = ?', whereArgs: [id]);
  }

  /// Atualiza uma movimentação existente aplicando as mesmas regras de negócio
  /// do [createMovement]. O [movement] deve conter o `id` da movimentação a ser
  /// alterada.
  Future<int> update(MovementModel movement) async {
    final db = await _dbHelper.database;

    if (movement.id == null) {
      throw Exception('ID da movimentação é obrigatório para atualização.');
    }

    if (movement.type == 'SAIDA') {
      if (movement.dataExit == null || movement.dataExit!.isEmpty) {
        throw Exception(
          'A data de saída é obrigatória para movimentação de SAÍDA.',
        );
      }
      if (movement.dataEntry.isNotEmpty) {
        final entrada = DateTime.parse(movement.dataEntry);
        final saida = DateTime.parse(movement.dataExit!);
        if (saida.isBefore(entrada)) {
          throw Exception(
            'A data de saída (${_formatDate(movement.dataExit!)}) não pode ser '
            'anterior à data de entrada (${_formatDate(movement.dataEntry)}).',
          );
        }
      }

      // Validação de saldo: desconsidera a própria movimentação que está sendo
      // editada, somando de volta a quantity antiga caso seja SAIDA.
      final saldo = await getSaldoProduto(movement.productId);
      final movAtual = await _getById(movement.id!);
      double saldoDisponivel = saldo;
      if (movAtual != null && movAtual.type == 'SAIDA') {
        saldoDisponivel += movAtual.quantity;
      }

      if (saldoDisponivel <= 0) {
        throw Exception(
          'Saldo zerado. Não é possível registrar saída. '
          'Registre uma nova entrada antes de continuar.',
        );
      }
      if (movement.quantity > saldoDisponivel) {
        throw Exception(
          'Quantidade de saída (${movement.quantity}) '
          'maior que o saldo disponível ($saldoDisponivel).',
        );
      }
    } else if (movement.type == 'ENTRADA') {
      if (movement.dataEntry.isEmpty) {
        throw Exception(
          'A data de entrada é obrigatória para movimentação de ENTRADA.',
        );
      }
    } else {
      throw Exception('Tipo de movimentação inválido: ${movement.type}');
    }

    return await db.update(
      'movements',
      movement.toMap(),
      where: 'id = ?',
      whereArgs: [movement.id],
    );
  }

  Future<MovementModel?> _getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.*, p.name AS product_name
      FROM movements m
      INNER JOIN products p ON m.product_id = p.id
      WHERE m.id = ?
    ''',
      [id],
    );
    if (maps.isEmpty) return null;
    return MovementModel.fromMap(maps.first);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

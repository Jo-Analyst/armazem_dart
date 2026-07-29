import '../core/database/database_helper.dart';
import '../models/movement_model.dart';

class MovementRepository {
  final DatabaseHelper _dbHelper;

  MovementRepository(this._dbHelper);

  /// Retorna o saldo atual calculado de um produto (SUM ENTRADA - SUM SAIDA)
  Future<double> getSaldoProduto(int produtoId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN tipo = 'ENTRADA' THEN quantidade ELSE 0 END), 0.0) -
        COALESCE(SUM(CASE WHEN tipo = 'SAIDA' THEN quantidade ELSE 0 END), 0.0) AS saldo
      FROM movimentacoes
      WHERE produto_id = ?
    ''',
      [produtoId],
    );

    return (result.first['saldo'] as num?)?.toDouble() ?? 0.0;
  }

  /// Cria uma nova movimentação aplicando as regras de negócio:
  /// - SAIDA: bloqueia se saldo == 0
  /// - SAIDA: data_saida não pode ser anterior à data_entrada
  Future<void> createMovement(MovementModel movement) async {
    final db = await _dbHelper.database;

    if (movement.tipo == 'SAIDA') {
      if (movement.dataSaida == null || movement.dataSaida!.isEmpty) {
        throw Exception(
          'A data de saída é obrigatória para movimentação de SAÍDA.',
        );
      }
      if (movement.dataEntrada.isNotEmpty) {
        final entrada = DateTime.parse(movement.dataEntrada);
        final saida = DateTime.parse(movement.dataSaida!);
        if (saida.isBefore(entrada)) {
          throw Exception(
            'A data de saída (${_formatDate(movement.dataSaida!)}) não pode ser '
            'anterior à data de entrada (${_formatDate(movement.dataEntrada)}).',
          );
        }
      }

      // Validação: saldo deve ser > 0 para registrar saída
      final saldo = await getSaldoProduto(movement.produtoId);
      if (saldo <= 0) {
        throw Exception(
          'Saldo zerado. Não é possível registrar saída. '
          'Registre uma nova entrada antes de continuar.',
        );
      }
      if (movement.quantidade > saldo) {
        throw Exception(
          'Quantidade de saída (${movement.quantidade}) '
          'maior que o saldo disponível ($saldo).',
        );
      }
    } else if (movement.tipo == 'ENTRADA') {
      if (movement.dataEntrada.isEmpty) {
        throw Exception(
          'A data de entrada é obrigatória para movimentação de ENTRADA.',
        );
      }
    } else {
      throw Exception('Tipo de movimentação inválido: ${movement.tipo}');
    }

    await db.insert('movimentacoes', movement.toMap());
  }

  Future<List<MovementModel>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.*, p.nome AS produto_nome
      FROM movimentacoes m
      INNER JOIN produtos p ON m.produto_id = p.id
      ORDER BY m.data_entrada DESC
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
      SELECT m.*, p.nome AS produto_nome
      FROM movimentacoes m
      INNER JOIN produtos p ON m.produto_id = p.id
      WHERE DATE(
        CASE
          WHEN m.tipo = 'SAIDA' AND (m.data_entrada IS NULL OR m.data_entrada = '')
            THEN m.data_saida
          ELSE m.data_entrada
        END
      ) >= DATE(?)
        AND DATE(
          CASE
            WHEN m.tipo = 'SAIDA' AND (m.data_entrada IS NULL OR m.data_entrada = '')
              THEN m.data_saida
            ELSE m.data_entrada
          END
        ) <= DATE(?)
      ORDER BY
        CASE
          WHEN m.tipo = 'SAIDA' AND (m.data_entrada IS NULL OR m.data_entrada = '')
            THEN m.data_saida
          ELSE m.data_entrada
        END DESC
    ''',
      [startDate, endDate],
    );
    return List.generate(maps.length, (i) => MovementModel.fromMap(maps[i]));
  }

  Future<List<MovementModel>> getByProduto(int produtoId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.*, p.nome AS produto_nome
      FROM movimentacoes m
      INNER JOIN produtos p ON m.produto_id = p.id
      WHERE m.produto_id = ?
      ORDER BY m.data_entrada DESC
    ''',
      [produtoId],
    );
    return List.generate(maps.length, (i) => MovementModel.fromMap(maps[i]));
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('movimentacoes', where: 'id = ?', whereArgs: [id]);
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

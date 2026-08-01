class ProductModel {
  final int? id;
  final String nome;
  final int categoriaId;
  final String? categoriaNome;
  final String? volume; // Volume do produto (ex: "1 KG", "500 ML")

  // Campos calculados dinamicamente (SUM entradas - SUM saídas)
  final double saldo;
  final String? unidadeSaldo; // unidade da última movimentação de entrada

  ProductModel({
    this.id,
    required this.nome,
    required this.categoriaId,
    this.categoriaNome,
    this.volume,
    this.saldo = 0.0,
    this.unidadeSaldo,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'categoria_id': categoriaId,
      if (volume != null) 'volume': volume,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      categoriaId: map['categoria_id'] as int,
      categoriaNome: map['categoria_nome'] as String?,
      volume: map['volume'] as String?,
      saldo: (map['saldo'] as num?)?.toDouble() ?? 0.0,
      unidadeSaldo: map['unidade_saldo'] as String?,
    );
  }

  /// Retorna o saldo formatado com unidade de medida
  String get saldoFormatado {
    final unit = unidadeSaldo ?? '';
    return '${_formatarNumero(saldo)} $unit'.trim();
  }

  static String _formatarNumero(double valor) {
    if (valor == valor.truncate()) {
      return valor.truncate().toString();
    }
    return valor
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

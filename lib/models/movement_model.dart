/// Unidades de medida disponíveis para movimentações
enum UnidadeMedida {
  kg('KG'),
  un('UN'),
  pct('PC'),
  mala('ML'),
  fardo('FD'),
  cx('CX'),
  lt('LT');

  final String label;
  const UnidadeMedida(this.label);

  static UnidadeMedida fromLabel(String label) {
    return UnidadeMedida.values.firstWhere(
      (e) => e.label == label.toUpperCase(),
      orElse: () => UnidadeMedida.un,
    );
  }
}

class MovementModel {
  final int? id;
  final int produtoId;
  final String tipo; // 'ENTRADA' | 'SAIDA'
  final double quantidade;
  final String unidadeMedida; // KG, UN, PCT, MALA, FARDO, CX, LT, OUTROS
  final String dataEntrada; // ISO8601 — obrigatória
  final String? dataSaida; // ISO8601 — obrigatória apenas em SAIDA
  final String? observacao;

  // Campos de UI (via JOIN)
  final String? productName;
  final String? productVolume;

  MovementModel({
    this.id,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    required this.unidadeMedida,
    required this.dataEntrada,
    this.dataSaida,
    this.observacao,
    this.productName,
    this.productVolume,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'produto_id': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
      'unidade_medida': unidadeMedida,
      'data_entrada': dataEntrada,
      'data_saida': dataSaida,
      'observacao': observacao,
    };
  }

  factory MovementModel.fromMap(Map<String, dynamic> map) {
    return MovementModel(
      id: map['id'] as int?,
      produtoId: map['produto_id'] as int,
      tipo: map['tipo'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      unidadeMedida: map['unidade_medida'] as String? ?? 'UN',
      dataEntrada:
          map['data_entrada'] as String? ??
          map['data'] as String? ??
          DateTime.now().toIso8601String(),
      dataSaida: map['data_saida'] as String?,
      observacao: map['observacao'] as String?,
      productName: map['product_name'] as String?,
      productVolume: map['product_volume'] as String?,
    );
  }

  bool get isEntrada => tipo == 'ENTRADA';
  bool get isSaida => tipo == 'SAIDA';

  /// Formata a quantidade com unidade
  String get quantidadeFormatada => '$quantidade $unidadeMedida';
}

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
  final int productId;
  final String type; // 'ENTRADA' | 'SAIDA'
  final double quantity;
  final String unitOfMeasurement; // KG, UN, PCT, MALA, FARDO, CX, LT, OUTROS
  final String dataEntry; // ISO8601 — obrigatória
  final String? dataExit; // ISO8601 — obrigatória apenas em SAIDA
  final String? observation;

  // Campos de UI (via JOIN)
  final String? productName;
  final String? productVolume;

  MovementModel({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.unitOfMeasurement,
    required this.dataEntry,
    this.dataExit,
    this.observation,
    this.productName,
    this.productVolume,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'unit_of_measurement': unitOfMeasurement,
      'data_entry': dataEntry,
      'data_exit': dataExit,
      'observation': observation,
    };
  }

  factory MovementModel.fromMap(Map<String, dynamic> map) {
    return MovementModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitOfMeasurement: map['unit_of_measurement'] as String? ?? 'UN',
      dataEntry:
          map['data_entry'] as String? ??
          map['data'] as String? ??
          DateTime.now().toIso8601String(),
      dataExit: map['data_exit'] as String?,
      observation: map['observation'] as String?,
      productName: map['product_name'] as String?,
      productVolume: map['product_volume'] as String?,
    );
  }

  bool get isEntrada => type == 'ENTRADA';
  bool get isSaida => type == 'SAIDA';

  /// Formata a quantity com unidade
  String get quantityFormated => '$quantity $unitOfMeasurement';
}

class ProductModel {
  final int? id;
  final String name;
  final int categoryId;
  final String? categoryName;
  final String? volume; // Volume do produto (ex: "1 KG", "500 ML")
  final String? description;

  // Campos calculados dinamicamente (SUM entradas - SUM saídas)
  final double balance;
  final String? unitaryBalance; // unidade da última movimentação de entrada

  ProductModel({
    this.id,
    required this.name,
    required this.categoryId,
    this.categoryName,
    this.volume,
    this.balance = 0.0,
    this.unitaryBalance,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category_id': categoryId,
      if (volume != null) 'volume': volume,
      if (description != null) 'description': description,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String?,
      volume: map['volume'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      unitaryBalance: map['unit_of_measurement'] as String?,
      description: map['description'] as String?,
    );
  }

  /// Retorna o saldo formatado com unidade de medida
  String get balanceFormatado {
    final unit = unitaryBalance ?? '';
    return '${_formatarNumero(balance)} $unit'.trim();
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

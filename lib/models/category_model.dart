class CategoryModel {
  final int? id;
  final String nome;

  CategoryModel({
    this.id,
    required this.nome,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      nome: map['nome'] as String,
    );
  }
}

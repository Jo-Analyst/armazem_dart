// TODO Implement this library.
import 'package:flutter/material.dart';
import '../../../models/product_model.dart';

class ProductItemCard extends StatelessWidget {
  final ProductModel product;
  final bool isSelected;
  final VoidCallback onLongPress;

  const ProductItemCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saldoPositivo = product.saldo > 0;

    return Card(
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey),
            )
          : const Border(bottom: BorderSide(color: Colors.grey)),
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 1,
      color: isSelected ? Colors.grey.shade50 : null,
      child: ListTile(
        onLongPress: onLongPress,
        leading: CircleAvatar(
          backgroundColor: saldoPositivo
              ? theme.colorScheme.primaryContainer
              : Colors.orange.shade100,
          child: Icon(
            Icons.inventory_2,
            color: saldoPositivo
                ? theme.colorScheme.onPrimaryContainer
                : Colors.orange.shade800,
          ),
        ),
        title: Text(
          product.nome,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : null,
          ),
        ),
        subtitle: Text(
          'Categoria: ${product.categoriaNome ?? "Sem categoria"}',
          style: TextStyle(color: isSelected ? Colors.black : null),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: saldoPositivo
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: saldoPositivo
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Text(
                  saldoPositivo ? product.saldoFormatado : 'Sem estoque',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: saldoPositivo
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
      ),
    );
  }
}

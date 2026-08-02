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
    final balancePositivo = product.balance > 0;

    return Card(
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey),
            )
          : null,
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 1,
      color: isSelected ? Colors.grey.shade50 : null,
      child: ListTile(
        onLongPress: onLongPress,
        leading: CircleAvatar(
          backgroundColor: balancePositivo
              ? theme.colorScheme.primaryContainer
              : Colors.orange.shade100,
          child: Icon(
            Icons.inventory_2,
            color: balancePositivo
                ? theme.colorScheme.onPrimaryContainer
                : Colors.orange.shade800,
          ),
        ),
        title: Text(
          product.volume != null && product.volume!.isNotEmpty
              ? '${product.name} (${product.volume})'
              : product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : null,
          ),
        ),
        subtitle: Text(
          'Categoria: ${product.categoryName ?? "Sem categoria"}',
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
                  color: balancePositivo
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: balancePositivo
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Text(
                  balancePositivo ? product.balanceFormatado : 'Sem estoque',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: balancePositivo
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../core/routes/app_routes.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _controller = locator<ProductController>();
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
    });
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Produto'),
          content: Text(
            'Deseja excluir "${product.nome}"?\n\n'
            'Todas as movimentações associadas também serão removidas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _controller.deleteProduct(product.id!);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produto excluído.')),
                );
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          _selectedProduct != null ? 'Produto Selecionado' : 'Produtos',
        ),
        elevation: 2,
        actions: _selectedProduct != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.productForm,
                      arguments: _selectedProduct,
                    );
                    if (result == true) {
                      _controller.init();
                    }
                    setState(() => _selectedProduct = null);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Excluir',
                  onPressed: () {
                    _confirmDelete(_selectedProduct!);
                    setState(() => _selectedProduct = null);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar seleção',
                  onPressed: () => setState(() => _selectedProduct = null),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _controller.updateSearch,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SignalBuilder(
                    builder: (context) {
                      return DropdownButtonFormField<int?>(
                        initialValue: _controller.categoryFilter.value,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ..._controller.categories.value.map((cat) {
                            return DropdownMenuItem<int?>(
                              value: cat.id,
                              child: Text(cat.nome),
                            );
                          }),
                        ],
                        onChanged: _controller.updateCategoryFilter,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                if (_controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.error.value != null) {
                  return Center(
                    child: Text(
                      'Erro: ${_controller.error.value}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final list = _controller.products.value;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum produto cadastrado.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final prod = list[index];
                    final saldoPositivo = prod.saldo > 0;

                    return Card(
                      shape: _selectedProduct?.id == prod.id
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey),
                            )
                          : Border(bottom: BorderSide(color: Colors.grey)),
                      margin: const EdgeInsets.only(bottom: 10.0),
                      elevation: 1,
                      color: _selectedProduct?.id == prod.id
                          ? Colors.grey.shade50
                          : null,
                      child: ListTile(
                        onLongPress: () =>
                            setState(() => _selectedProduct = prod),
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
                          prod.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedProduct?.id == prod.id
                                ? Colors.black
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          'Categoria: ${prod.categoriaNome ?? "Sem categoria"}',
                          style: TextStyle(
                            color: _selectedProduct?.id == prod.id
                                ? Colors.black
                                : null,
                          ),
                        ),
                        trailing: _selectedProduct?.id == prod.id
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Chip de saldo calculado
                                  Container(
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
                                      saldoPositivo
                                          ? prod.saldoFormatado
                                          : 'Sem estoque',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: saldoPositivo
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.productForm,
          );
          if (result == true) {
            _controller.init();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Produto'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../core/routes/app_routes.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import 'widgets/product_item_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _controller = locator<ProductController>();
  final _searchController = TextEditingController();
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Barra de busca e filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      final hasText = value.text.isNotEmpty;

                      return TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome...',
                          border: const OutlineInputBorder(),
                          suffixIcon: hasText
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Limpar busca',
                                  onPressed: () {
                                    _searchController.clear();
                                    _controller.updateSearch('');
                                  },
                                )
                              : const Icon(Icons.search),
                        ),
                        onChanged: _controller.updateSearch,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SignalBuilder(
                    builder: (context) {
                      return DropdownButtonFormField<int?>(
                        value: _controller.categoryFilter.value,
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

          // Lista de Produtos / Estados da UI
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
                    final isSelected = _selectedProduct?.id == prod.id;

                    return ProductItemCard(
                      product: prod,
                      isSelected: isSelected,
                      onLongPress: () {
                        setState(() => _selectedProduct = prod);
                      },
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
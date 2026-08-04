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
  final ScrollController _scrollController = ScrollController();
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 150 &&
        _controller.hasMoreProducts.value &&
        !_controller.isLoading.value &&
        !_controller.isLoadingMoreProducts) {
      _controller.loadProducts(reset: false);
    }
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Produto'),
          content: Text(
            'Deseja excluir "${product.name}"?\n\n'
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
              child: Text('Excluir', style: TextStyle(color: Colors.white)),
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
        foregroundColor: Colors.white,
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
      // 1. ADICIONADO: SafeArea para garantir que o conteúdo não fique sob os botões do Android
      body: SafeArea(
        child: Column(
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
                          initialValue: _controller.categoryFilter.value,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._controller.categories.value.map((cat) {
                              return DropdownMenuItem<int?>(
                                value: cat.id,
                                child: Text(cat.name),
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
            SignalBuilder(
              builder: (context) {
                return _controller.isLoading.value
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink();
              },
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
                    controller: _scrollController,
                    // 2. ALTERADO: Espaço extra no final (bottom: 80.0) para não cobrir o último item com o FAB
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 0.0,
                      bottom: 80.0,
                    ),
                    itemCount:
                        list.length +
                        (_controller.hasMoreProducts.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= list.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Carregando mais produtos...'),
                              ],
                            ),
                          ),
                        );
                      }

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
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

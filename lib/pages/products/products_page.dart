import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _controller = locator<ProductController>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newCategoryController = TextEditingController();

  int? _selectedCategoryId;
  bool _addingNewCategory = false;
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
    _nameController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([ProductModel? product]) {
    _nameController.text = product?.nome ?? '';
    _selectedCategoryId =
        product?.categoriaId ??
        (_controller.categories.value.isNotEmpty
            ? _controller.categories.value.first.id
            : null);
    _addingNewCategory = false;
    _newCategoryController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(product == null ? 'Novo Produto' : 'Editar Produto'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome do Produto
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Produto *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Por favor, insira o nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Categoria — Selecionar existente ou criar nova
                        if (!_addingNewCategory) ...[
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedCategoryId,
                                  decoration: const InputDecoration(
                                    labelText: 'Categoria *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _controller.categories.value.map((
                                    cat,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: cat.id,
                                      child: Text(cat.nome),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      _selectedCategoryId = val;
                                    });
                                  },
                                  validator: (val) {
                                    if (val == null && !_addingNewCategory) {
                                      return 'Selecione uma categoria';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: () {
                                  setDialogState(() {
                                    _addingNewCategory = true;
                                    _selectedCategoryId = null;
                                  });
                                },
                                icon: const Icon(Icons.add),
                                tooltip: 'Criar nova categoria',
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _newCategoryController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome da Nova Categoria *',
                                    border: OutlineInputBorder(),
                                    hintText: 'Ex: Laticínios',
                                  ),
                                  validator: (val) {
                                    if (_addingNewCategory &&
                                        (val == null || val.trim().isEmpty)) {
                                      return 'Informe o nome da categoria';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    _addingNewCategory = false;
                                    _newCategoryController.clear();
                                  });
                                },
                                icon: const Icon(Icons.close),
                                tooltip: 'Cancelar nova categoria',
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'O saldo do produto é calculado automaticamente pelas movimentações de entrada e saída.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    try {
                      // Criar nova categoria se necessário
                      if (_addingNewCategory &&
                          _newCategoryController.text.trim().isNotEmpty) {
                        final newCat = await _controller.addCategoryIfNeeded(
                          _newCategoryController.text.trim(),
                        );
                        _selectedCategoryId = newCat.id;
                      }

                      if (_selectedCategoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecione ou crie uma categoria.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (product == null) {
                        await _controller.addProduct(
                          nome: _nameController.text.trim(),
                          categoriaId: _selectedCategoryId!,
                        );
                      } else {
                        await _controller.editProduct(
                          ProductModel(
                            id: product.id,
                            nome: _nameController.text.trim(),
                            categoriaId: _selectedCategoryId!,
                          ),
                        );
                      }
                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            product == null
                                ? 'Produto adicionado!'
                                : 'Produto atualizado!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
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
        title: Text(
          _selectedProduct != null ? 'Produto Selecionado' : 'Produtos',
        ),
        elevation: 2,
        actions: _selectedProduct != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () {
                    _showAddEditDialog(_selectedProduct);
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
        onPressed: _showAddEditDialog,
        icon: const Icon(Icons.add),
        label: const Text('Novo Produto'),
      ),
    );
  }
}

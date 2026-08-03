import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _controller = locator<ProductController>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final _volumeController = TextEditingController();

  int? _selectedCategoryId;
  bool _addingNewCategory = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.product != null;

    // Listeners para reconstruir o widget e exibir/ocultar o botão de limpar em tempo real
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
    _newCategoryController.addListener(() {
      if (mounted) setState(() {});
    });
    _volumeController.addListener(() {
      if (mounted) setState(() {});
    });

    if (isEditing) {
      _nameController.text = widget.product!.name;
      _selectedCategoryId = widget.product!.categoryId;
      _volumeController.text = widget.product!.volume ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.init();

      if (!isEditing) {
        setState(() {
          _selectedCategoryId = _controller.categories.value.isNotEmpty
              ? _controller.categories.value.first.id
              : null;
        });
      }
    });

    _addingNewCategory = false;
    _newCategoryController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newCategoryController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Criar nova categoria se necessário
      if (_addingNewCategory && _newCategoryController.text.trim().isNotEmpty) {
        final newCat = await _controller.addCategoryIfNeeded(
          _newCategoryController.text.trim(),
        );
        _selectedCategoryId = newCat.id;
      }

      if (_selectedCategoryId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione ou crie uma categoria.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (widget.product == null) {
        await _controller.addProduct(
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          volume: _volumeController.text.trim().isEmpty
              ? null
              : _volumeController.text.trim(),
        );
      } else {
        await _controller.editProduct(
          ProductModel(
            id: widget.product?.id ?? 0,
            name: _nameController.text.trim(),
            categoryId: _selectedCategoryId!,
            volume: _volumeController.text.trim().isEmpty
                ? null
                : _volumeController.text.trim(),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? 'Produto adicionado!'
                : 'Produto atualizado!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(widget.product == null ? 'Novo Produto' : 'Editar Produto'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do Produto
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome do Produto *',
                  border: const OutlineInputBorder(),
                  suffixIcon: _nameController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _nameController.clear(),
                        )
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor, insira o name';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _saveProduct(),
              ),
              const SizedBox(height: 16),

              // Volume (opcional)
              TextFormField(
                controller: _volumeController,
                decoration: InputDecoration(
                  labelText: 'Volume (opcional)',
                  hintText: 'Ex: 1 KG, 500 ML, 12 Unidades',
                  border: const OutlineInputBorder(),
                  suffixIcon: _volumeController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _volumeController.clear(),
                        )
                      : null,
                ),
                onFieldSubmitted: (_) => _saveProduct(),
              ),
              const SizedBox(height: 16),

              // Categoria — Selecionar existente ou criar nova
              if (!_addingNewCategory) ...[
                Row(
                  children: [
                    Expanded(
                      child: SignalBuilder(
                        builder: (context) {
                          return DropdownButtonFormField<int>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Categoria *',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            items: _controller.categories.value.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat.id,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                            validator: (val) {
                              if (val == null && !_addingNewCategory) {
                                return 'Selecione uma categoria';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        setState(() {
                          _addingNewCategory = true;
                          _selectedCategoryId = null;
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
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
                        decoration: InputDecoration(
                          labelText: 'Nome da Nova Categoria *',
                          border: const OutlineInputBorder(),
                          hintText: 'Ex: Laticínios',
                          suffixIcon: _newCategoryController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      _newCategoryController.clear(),
                                )
                              : null,
                        ),
                        onFieldSubmitted: (_) => _saveProduct(),
                        validator: (val) {
                          if (_addingNewCategory &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Informe o name da categoria';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red, // Cor de fundo do botão
                        foregroundColor:
                            Colors.white, // Cor do ícone (opcional)
                      ),
                      onPressed: () {
                        setState(() {
                          _addingNewCategory = false;
                          _newCategoryController.clear();
                          _selectedCategoryId =
                              _controller.categories.value.isNotEmpty
                              ? _controller.categories.value.first.id
                              : null;
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
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

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

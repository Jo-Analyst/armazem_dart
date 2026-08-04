import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../controllers/category_controller.dart';
import '../../models/category_model.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _controller = locator<CategoryController>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> addCategory(
    CategoryModel? category,
    void Function() onTextChanged,
  ) async {
    if (_formKey.currentState!.validate()) {
      try {
        if (category == null) {
          await _controller.addCategory(_nameController.text);
        } else {
          await _controller.editCategory(
            CategoryModel(id: category.id, name: _nameController.text),
          );
        }
        _nameController.removeListener(onTextChanged);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              category == null
                  ? 'Categoria adicionada!'
                  : 'Categoria atualizada!',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEditDialog([CategoryModel? category]) {
    _nameController.text = category?.name ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Listener temporário para atualizar o estado interno do Dialog ao digitar/apagar
            void onTextChanged() {
              setDialogState(() {});
            }

            _nameController.addListener(onTextChanged);

            return AlertDialog(
              title: Text(
                category == null ? 'Nova Categoria' : 'Editar Categoria',
              ),
              content: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nome da Categoria',
                    border: const OutlineInputBorder(),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _nameController.clear();
                              _nameFocusNode.requestFocus();
                              setDialogState(() {});
                            },
                          )
                        : null,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor, insira o name';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => addCategory(category, onTextChanged),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _nameController.removeListener(onTextChanged);
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await addCategory(category!, onTextChanged);
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

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Categoria'),
          content: Text(
            'Deseja realmente excluir a categoria "${category.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await _controller.deleteCategory(category.id!);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoria excluída com sucesso!'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Não é possível excluir: existem produtos associados a esta categoria.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
        foregroundColor: Colors.white,
        title: Text(
          _selectedCategory != null ? 'Categoria Selecionada' : 'Categorias',
        ),
        elevation: 2,
        actions: _selectedCategory != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () {
                    _showAddEditDialog(_selectedCategory);
                    setState(() => _selectedCategory = null);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Excluir',
                  onPressed: () {
                    _confirmDelete(_selectedCategory!);
                    setState(() => _selectedCategory = null);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar seleção',
                  onPressed: () => setState(() => _selectedCategory = null),
                ),
              ]
            : null,
      ),
      body: SignalBuilder(
        builder: (context) {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error.value != null) {
            return Center(
              child: Text(
                'Erro ao carregar categorias: ${_controller.error.value}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final categoriesList = _controller.categories.value;

          if (categoriesList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: theme.hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma categoria cadastrada.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: categoriesList.length,
            itemBuilder: (context, index) {
              final cat = categoriesList[index];
              return Card(
                shape: _selectedCategory?.id == cat.id
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      )
                    : null,
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 1,
                color: _selectedCategory?.id == cat.id
                    ? Colors.grey.shade50
                    : null,
                child: ListTile(
                  onLongPress: () => setState(() => _selectedCategory = cat),
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 226, 178, 116),
                    foregroundColor: Colors.black,
                    child: Icon(Icons.category_outlined),
                  ),
                  title: Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedCategory?.id == cat.id
                          ? Colors.black
                          : null,
                    ),
                  ),
                  trailing: _selectedCategory?.id == cat.id
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }
}

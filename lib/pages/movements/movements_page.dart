import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../controllers/movement_controller.dart';
import '../../models/movement_model.dart';
import '../../models/product_model.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({super.key});

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  final _controller = locator<MovementController>();
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _obsController = TextEditingController();

  ProductModel? _selectedProduct;
  String _selectedType = 'ENTRADA';
  String _selectedUnit = UnidadeMedida.un.label;
  DateTime? _dataEntrada;
  DateTime? _dataSaida;
  double _saldoAtual = 0.0;

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _atualizarSaldo(ProductModel? produto) async {
    if (produto == null) {
      _saldoAtual = 0.0;
      return;
    }
    _saldoAtual = await _controller.getSaldoProduto(produto.id!);
  }

  Future<DateTime?> _pickDate(
    BuildContext ctx, {
    DateTime? initial,
    DateTime? firstDate,
  }) async {
    return await showDatePicker(
      context: ctx,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  void _showAddDialog([MovementModel? movement]) {
    final isEditing = movement != null;
    _quantityController.text = isEditing ? movement.quantidade.toString() : '';
    _obsController.text = isEditing ? (movement.observacao ?? '') : '';
    _selectedType = isEditing ? movement.tipo : 'ENTRADA';
    _selectedUnit = isEditing ? movement.unidadeMedida : UnidadeMedida.un.label;
    _dataEntrada = isEditing
        ? (movement.dataEntrada.isNotEmpty
              ? DateTime.tryParse(movement.dataEntrada)
              : null)
        : DateTime.now();
    _dataSaida = isEditing ? DateTime.tryParse(movement.dataSaida ?? '') : null;
    _selectedProduct = isEditing
        ? _controller.products.value
              .where((p) => p.id == movement.produtoId)
              .firstOrNull
        : (_controller.products.value.isNotEmpty
              ? _controller.products.value.first
              : null);
    _saldoAtual = _selectedProduct?.saldo ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSaida = _selectedType == 'SAIDA';
            final saldoZerado = isSaida && _saldoAtual <= 0;

            return AlertDialog(
              title: Text(
                isEditing ? 'Editar Movimentação' : 'Nova Movimentação',
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Produto
                        DropdownButtonFormField<ProductModel>(
                          initialValue: _selectedProduct,
                          decoration: const InputDecoration(
                            labelText: 'Produto *',
                            border: OutlineInputBorder(),
                          ),
                          items: _controller.products.value.map((prod) {
                            return DropdownMenuItem<ProductModel>(
                              value: prod,
                              child: Text(prod.nome),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            await _atualizarSaldo(val);
                            setDialogState(() {
                              _selectedProduct = val;
                            });
                          },
                          validator: (val) =>
                              val == null ? 'Selecione um produto' : null,
                        ),

                        // Saldo atual do produto selecionado
                        if (_selectedProduct != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _saldoAtual > 0
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _saldoAtual > 0
                                    ? Colors.green.shade200
                                    : Colors.orange.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _saldoAtual > 0
                                      ? Icons.inventory_2
                                      : Icons.warning_amber_rounded,
                                  size: 16,
                                  color: _saldoAtual > 0
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Saldo atual: ${_selectedProduct!.saldoFormatado}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _saldoAtual > 0
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Tipo de Movimentação
                        DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ENTRADA',
                              child: Text('✅ ENTRADA — Acréscimo de estoque'),
                            ),
                            DropdownMenuItem(
                              value: 'SAIDA',
                              child: Text('📦 SAÍDA — Decréscimo de estoque'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _selectedType = val;
                                if (val == 'ENTRADA') {
                                  _dataSaida = null;
                                  _dataEntrada ??= DateTime.now();
                                } else if (val == 'SAIDA') {
                                  _dataEntrada = null;
                                  _dataSaida = null;
                                }
                              });
                            }
                          },
                        ),

                        // Aviso de saldo zerado para SAIDA
                        if (saldoZerado) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.block,
                                  color: Colors.red.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Saldo zerado! Registre uma ENTRADA antes de lançar saída.',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Quantidade + Unidade
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _quantityController,
                                enabled: !saldoZerado,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Informe a quantidade';
                                  }
                                  final qty = double.tryParse(val);
                                  if (qty == null || qty <= 0) {
                                    return 'Deve ser > 0';
                                  }
                                  if (_selectedType == 'SAIDA' &&
                                      qty > _saldoAtual) {
                                    return 'Excede o saldo ($_saldoAtual)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unidade *',
                                  border: OutlineInputBorder(),
                                ),
                                items: UnidadeMedida.values.map((u) {
                                  return DropdownMenuItem(
                                    value: u.label,
                                    child: Text(u.label),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => _selectedUnit = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Data de Entrada
                        IgnorePointer(
                          ignoring: _selectedType == 'SAIDA',
                          child: InkWell(
                            onTap: () async {
                              if (_selectedType == 'SAIDA') return;
                              final picked = await _pickDate(
                                context,
                                initial: _dataEntrada ?? DateTime.now(),
                              );
                              if (picked != null) {
                                setDialogState(() => _dataEntrada = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: _selectedType == 'SAIDA'
                                    ? 'Data de Entrada'
                                    : 'Data de Entrada *',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                                filled: _selectedType == 'SAIDA',
                                fillColor: _selectedType == 'SAIDA'
                                    ? Colors.grey.shade100
                                    : null,
                              ),
                              child: Text(
                                _selectedType == 'SAIDA'
                                    ? 'Não aplicável'
                                    : _dataEntrada != null
                                    ? _dateFormat.format(_dataEntrada!)
                                    : 'Selecione a data',
                                style: _selectedType == 'SAIDA'
                                    ? TextStyle(color: Colors.grey.shade500)
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Data de Saída
                        IgnorePointer(
                          ignoring: _selectedType == 'ENTRADA',
                          child: InkWell(
                            onTap: () async {
                              if (_selectedType == 'ENTRADA') return;
                              final picked = await _pickDate(
                                context,
                                initial:
                                    _dataSaida ??
                                    _dataEntrada ??
                                    DateTime.now(),
                                firstDate: _dataEntrada ?? DateTime(2020),
                              );
                              if (picked != null) {
                                setDialogState(() => _dataSaida = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: _selectedType == 'SAIDA'
                                    ? 'Data de Saída *'
                                    : 'Data de Saída',
                                border: const OutlineInputBorder(),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_dataSaida != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setDialogState(
                                          () => _dataSaida = null,
                                        ),
                                      ),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                                filled: _selectedType == 'ENTRADA',
                                fillColor: _selectedType == 'ENTRADA'
                                    ? Colors.grey.shade100
                                    : null,
                              ),
                              child: Text(
                                _selectedType == 'ENTRADA'
                                    ? 'Não informada'
                                    : _dataSaida != null
                                    ? _dateFormat.format(_dataSaida!)
                                    : 'Selecione a data',
                                style: _selectedType == 'ENTRADA'
                                    ? TextStyle(color: Colors.grey.shade500)
                                    : (_dataSaida == null
                                          ? TextStyle(
                                              color: Colors.grey.shade500,
                                            )
                                          : null),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Observação
                        TextFormField(
                          controller: _obsController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Observação (Opcional)',
                            border: OutlineInputBorder(),
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
                  onPressed: saldoZerado
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedProduct == null) return;
                          final saveContext = context;

                          if (_selectedType == 'ENTRADA' &&
                              _dataEntrada == null) {
                            ScaffoldMessenger.of(saveContext).showSnackBar(
                              const SnackBar(
                                content: Text('Informe a data de entrada.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (_selectedType == 'SAIDA' && _dataSaida == null) {
                            ScaffoldMessenger.of(saveContext).showSnackBar(
                              const SnackBar(
                                content: Text('Informe a data de saída.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final dataEntradaParaSalvar =
                              _selectedType == 'ENTRADA'
                              ? _dataEntrada!.toIso8601String()
                              : '';

                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(dialogContext);

                          try {
                            final qty = double.parse(_quantityController.text);

                            if (isEditing) {
                              await _controller.updateMovement(
                                MovementModel(
                                  id: movement.id,
                                  produtoId: _selectedProduct!.id!,
                                  tipo: _selectedType,
                                  quantidade: qty,
                                  unidadeMedida: _selectedUnit,
                                  dataEntrada: dataEntradaParaSalvar,
                                  dataSaida: _selectedType == 'ENTRADA'
                                      ? null
                                      : _dataSaida!.toIso8601String(),
                                  observacao: _obsController.text.trim().isEmpty
                                      ? null
                                      : _obsController.text.trim(),
                                ),
                              );
                            } else {
                              await _controller.registerMovement(
                                produtoId: _selectedProduct!.id!,
                                tipo: _selectedType,
                                quantidade: qty,
                                unidadeMedida: _selectedUnit,
                                dataEntrada: dataEntradaParaSalvar,
                                dataSaida: _selectedType == 'ENTRADA'
                                    ? null
                                    : _dataSaida!.toIso8601String(),
                                observacao: _obsController.text.trim().isEmpty
                                    ? null
                                    : _obsController.text.trim(),
                              );
                            }
                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Movimentação atualizada!'
                                      : 'Movimentação registrada!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text(isEditing ? 'Salvar' : 'Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(MovementModel movement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Movimentação'),
          content: Text(
            'Deseja excluir a movimentação de '
            '${movement.isEntrada ? 'ENTRADA' : 'SAÍDA'} de '
            '${movement.quantidade} ${movement.unidadeMedida} '
            'do produto "${movement.produtoNome ?? 'Desconhecido'}"?\n\n'
            'O saldo do produto será recalculado automaticamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _controller.deleteMovement(movement.id!);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Movimentação excluída.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
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
        title: const Text('Movimentações de Estoque'),
        elevation: 2,
      ),
      body: SignalBuilder(
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

          final list = _controller.movements.value;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz_outlined,
                    size: 64,
                    color: theme.hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma movimentação registrada.',
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
            itemCount: list.length,
            itemBuilder: (context, index) {
              final mov = list[index];
              final isEntrada = mov.isEntrada;
              final dataE =
                  DateTime.tryParse(mov.dataEntrada) ?? DateTime.now();
              final dataS = mov.dataSaida != null
                  ? DateTime.tryParse(mov.dataSaida!)
                  : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 10.0),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isEntrada
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isEntrada
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                  title: Text(
                    mov.produtoNome ?? 'Produto Desconhecido',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ent: ${_dateTimeFormat.format(dataE).split(' ')[0]}',
                        ),
                      ),
                      if (dataS != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Saída: ${_dateTimeFormat.format(dataS)}',
                          ),
                        ),
                      if (mov.observacao != null)
                        Text('Obs: ${mov.observacao}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${isEntrada ? "+" : "-"}${mov.quantidade} ${mov.unidadeMedida}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isEntrada ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar',
                        onPressed: () => _showAddDialog(mov),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Excluir',
                        onPressed: () => _confirmDelete(mov),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_controller.products.value.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cadastre ao menos um produto primeiro.'),
                backgroundColor: Colors.amber,
              ),
            );
            return;
          }
          _showAddDialog();
        },
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Nova Movimentação'),
      ),
    );
  }
}

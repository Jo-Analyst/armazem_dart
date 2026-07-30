import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../controllers/movement_controller.dart';
import '../../models/movement_model.dart';
import '../../models/product_model.dart';

class MovementFormPage extends StatefulWidget {
  final MovementModel? movement;

  const MovementFormPage({super.key, this.movement});

  @override
  State<MovementFormPage> createState() => _MovementFormPageState();
}

class _MovementFormPageState extends State<MovementFormPage> {
  final _controller = locator<MovementController>();
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _obsController = TextEditingController();

  ProductModel? _selectedProduct;
  String _selectedType = 'ENTRADA';
  String _selectedUnit = 'UN';
  DateTime? _dataEntrada;
  DateTime? _dataSaida;
  double _saldoAtual = 0.0;
  bool _isLoading = false;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final isEditing = widget.movement != null;

    // Listener para re-renderizar ao digitar na quantidade (controla a visibilidade do ícone de limpar)
    _quantityController.addListener(() {
      if (mounted) setState(() {});
    });

    if (isEditing) {
      _quantityController.text = widget.movement!.quantidade
          .toString()
          .replaceAll('.', ',');
      _obsController.text = widget.movement!.observacao ?? '';
      _selectedType = widget.movement!.tipo;
      _selectedUnit = widget.movement!.unidadeMedida;
      _dataEntrada = widget.movement!.dataEntrada.isNotEmpty
          ? DateTime.tryParse(widget.movement!.dataEntrada)
          : null;
      _dataSaida = DateTime.tryParse(widget.movement!.dataSaida ?? '');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.init();

      if (isEditing) {
        final prod = _controller.products.value
            .where((p) => p.id == widget.movement!.produtoId)
            .firstOrNull;

        if (prod != null) {
          await _atualizarSaldo(prod);
        }

        setState(() {
          _selectedProduct = prod;
        });
      } else {
        setState(() {
          _selectedProduct = _controller.products.value.isNotEmpty
              ? _controller.products.value.first
              : null;
          _dataEntrada = DateTime.now();
        });
        if (_selectedProduct != null) {
          await _atualizarSaldo(_selectedProduct);
        }
      }
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
    final saldo = await _controller.getSaldoProduto(produto.id!);
    setState(() {
      _saldoAtual = saldo;
    });
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

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.movement == null) {
        await _controller.registerMovement(
          produtoId: _selectedProduct!.id!,
          tipo: _selectedType,
          quantidade: double.parse(
            _quantityController.text.trim().replaceAll(',', '.'),
          ),
          unidadeMedida: _selectedUnit,
          dataEntrada: _selectedType == 'ENTRADA'
              ? _dataEntrada!.toIso8601String()
              : '',
          dataSaida: _selectedType == 'SAIDA'
              ? (_dataSaida?.toIso8601String() ?? '')
              : '',
          observacao: _obsController.text.trim().isEmpty
              ? null
              : _obsController.text.trim(),
        );
      } else {
        await _controller.updateMovement(
          MovementModel(
            id: widget.movement!.id,
            produtoId: _selectedProduct!.id!,
            tipo: _selectedType,
            quantidade: double.parse(
              _quantityController.text.trim().replaceAll(',', '.'),
            ),
            unidadeMedida: _selectedUnit,
            dataEntrada: _selectedType == 'ENTRADA'
                ? _dataEntrada!.toIso8601String()
                : '',
            dataSaida: _selectedType == 'SAIDA'
                ? (_dataSaida?.toIso8601String() ?? '')
                : '',
            observacao: _obsController.text.trim().isEmpty
                ? null
                : _obsController.text.trim(),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.movement == null
                ? 'Movimentação registrada!'
                : 'Movimentação atualizada!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.movement != null;
    final isSaida = _selectedType == 'SAIDA';
    final saldoZerado = isSaida && _saldoAtual <= 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(isEditing ? 'Editar Movimentação' : 'Nova Movimentação'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Produto
              SignalBuilder(
                builder: (context) {
                  final productList = _controller.products.value;

                  return Autocomplete<ProductModel>(
                    key: ValueKey(_selectedProduct?.id ?? 'novo_produto'),
                    initialValue: TextEditingValue(
                      text: _selectedProduct?.nome ?? '',
                    ),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return productList;
                      }
                      return productList.where((ProductModel option) {
                        return option.nome.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    displayStringForOption: (ProductModel option) =>
                        option.nome,
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          if (textEditingController.text.isEmpty &&
                              _selectedProduct != null) {
                            textEditingController.text = _selectedProduct!.nome;
                          }

                          final hasValue =
                              textEditingController.text.isNotEmpty ||
                              _selectedProduct != null;

                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Produto *',
                              border: const OutlineInputBorder(),
                              suffixIcon: !hasValue
                                  ? const Icon(Icons.search)
                                  : IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        textEditingController.clear();
                                        focusNode.unfocus();
                                        setState(() {
                                          _selectedProduct = null;
                                          _saldoAtual = 0.0;
                                        });
                                      },
                                    ),
                            ),
                            validator: (val) {
                              if (val == null ||
                                  val.trim().isEmpty ||
                                  _selectedProduct == null) {
                                return 'Selecione um produto';
                              }
                              return null;
                            },
                          );
                        },
                    onSelected: (ProductModel selection) async {
                      await _atualizarSaldo(selection);
                      setState(() {
                        _selectedProduct = selection;
                      });
                    },
                  );
                },
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
                    setState(() {
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
                      Icon(Icons.block, color: Colors.red.shade700, size: 18),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // Permite apenas números e um único separador decimal (. ou ,)
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Quantidade *',
                        border: const OutlineInputBorder(),
                        suffixIcon: _quantityController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _quantityController.clear(),
                              )
                            : null,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Informe a quantidade';
                        }
                        // Substitui vírgula por ponto para o double.tryParse não falhar
                        final normalizedVal = val.replaceAll(',', '.');
                        final qty = double.tryParse(normalizedVal);
                        if (qty == null || qty <= 0) {
                          return 'Deve ser um número maior que 0';
                        }
                        if (_selectedType == 'SAIDA' && qty > _saldoAtual) {
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
                          setState(() => _selectedUnit = val);
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
                      setState(() => _dataEntrada = picked);
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
                      initial: _dataSaida ?? _dataEntrada ?? DateTime.now(),
                      firstDate: _dataEntrada ?? DateTime(2020),
                    );
                    if (picked != null) {
                      setState(() => _dataSaida = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _selectedType == 'SAIDA'
                          ? 'Data de Saída *'
                          : 'Data de Saída',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      filled: _selectedType == 'ENTRADA',
                      fillColor: _selectedType == 'ENTRADA'
                          ? Colors.grey.shade100
                          : null,
                    ),
                    child: Text(
                      _selectedType == 'ENTRADA'
                          ? 'Não aplicável'
                          : _dataSaida != null
                          ? _dateFormat.format(_dataSaida!)
                          : 'Selecione a data',
                      style: _selectedType == 'ENTRADA'
                          ? TextStyle(color: Colors.grey.shade500)
                          : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Observação
              TextFormField(
                controller: _obsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveMovement,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Salvar' : 'Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

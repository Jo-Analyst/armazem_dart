import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/error_utils.dart';
import '../../controllers/movement_controller.dart';
import '../../models/movement_model.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({super.key});

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  final _controller = locator<MovementController>();
  final ScrollController _scrollController = ScrollController();
  MovementModel? _selectedMovement;

  final _dateTimeFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 150 &&
        _controller.hasMoreMovements.value &&
        !_controller.isLoading.value &&
        !_controller.isLoadingMoreMovements) {
      _controller.loadMovements(reset: false);
    }
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
            '${movement.quantity} ${movement.unitOfMeasurement} '
            'do produto "${movement.productName ?? 'Desconhecido'}"?\n\n'
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
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _controller.deleteMovement(movement.id!);
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Movimentação excluída.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(cleanErrorMessage(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.white),
              ),
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
          _selectedMovement != null
              ? 'Movimentação Selecionada'
              : 'Movimentações de Estoque',
        ),
        elevation: 2,
        actions: _selectedMovement != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: 'Editar',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.movementForm,
                      arguments: _selectedMovement,
                    );
                    setState(() => _selectedMovement = null);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  tooltip: 'Excluir',
                  onPressed: () {
                    _confirmDelete(_selectedMovement!);
                    setState(() => _selectedMovement = null);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cancelar seleção',
                  onPressed: () => setState(() => _selectedMovement = null),
                ),
              ]
            : null,
      ),
      // 1. ADICIONADO: SafeArea para proteger contra a barra de navegação do sistema Android
      body: SafeArea(
        child: Column(
          children: [
            SignalBuilder(
              builder: (context) {
                return _controller.isLoading.value
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink();
              },
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
                        'Erro: ${cleanErrorMessage(_controller.error.value)}',
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
                            Icons.move_down_outlined,
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
                    controller: _scrollController,
                    // 2. ALTERADO: Adicionado padding bottom: 80.0 para descolar o último item do FAB
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 80.0,
                    ),
                    itemCount:
                        list.length +
                        (_controller.hasMoreMovements.value ? 1 : 0),
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
                                Text('Carregando mais movimentações...'),
                              ],
                            ),
                          ),
                        );
                      }

                      final mov = list[index];
                      final isEntrada = mov.isEntrada;
                      final dt = mov.dataEntry.split('T')[0];
                      final dateFormated = dt.isNotEmpty
                          ? _dateTimeFormat.format(
                              DateTime(
                                int.parse(dt.split('-')[0]),
                                int.parse(dt.split('-')[1]),
                                int.parse(dt.split('-')[2]),
                              ),
                            )
                          : '';

                      final dataS = mov.dataExit != null
                          ? DateTime.tryParse(mov.dataExit!)
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        elevation: 1,
                        shape: _selectedMovement?.id == mov.id
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey),
                              )
                            : null,
                        color: _selectedMovement?.id == mov.id
                            ? Colors.grey.shade50
                            : null,
                        child: ListTile(
                          onLongPress: () =>
                              setState(() => _selectedMovement = mov),
                          leading: CircleAvatar(
                            backgroundColor: isEntrada
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              isEntrada
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isEntrada
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          title: Text(
                            '${mov.productName} ${mov.productVolume != null ? '(${mov.productVolume})' : ''} ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedMovement?.id == mov.id
                                  ? Colors.black
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (dateFormated.isNotEmpty)
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Ent: $dateFormated',
                                    style: TextStyle(
                                      color: _selectedMovement?.id == mov.id
                                          ? Colors.black
                                          : null,
                                    ),
                                  ),
                                ),
                              if (dataS != null)
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Saída: ${_dateTimeFormat.format(dataS)}',
                                  ),
                                ),
                              if (mov.observation != null)
                                Text('Obs: ${mov.observation}'),
                            ],
                          ),
                          trailing: _selectedMovement?.id == mov.id
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${isEntrada ? "+" : "-"}${mov.quantity} ${mov.unitOfMeasurement}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isEntrada
                                              ? Colors.green
                                              : Colors.red,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Colors.white,
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
          Navigator.pushNamed(context, AppRoutes.movementForm);
        },
        icon: const Icon(Icons.move_down),
        label: const Text('Nova Movimentação'),
      ),
    );
  }
}

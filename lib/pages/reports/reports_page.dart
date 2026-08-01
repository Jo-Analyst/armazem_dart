import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../controllers/report_controller.dart';
import '../../models/movement_model.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _controller = locator<ReportController>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      locale: const Locale('pt', 'BR'),
      context: context,
      initialDateRange: DateTimeRange(
        start: _controller.startDate.value,
        end: _controller.endDate.value,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _controller.updatePeriod(picked.start, picked.end);
    }
  }

  Future<String> _criarArquivoPdf(List<MovementModel> list) async {
    final pdf = pw.Document();
    final start = _dateFormat.format(_controller.startDate.value);
    final end = _dateFormat.format(_controller.endDate.value);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório de Movimentações - Almoxarifado',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Período: $start a $end',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Entradas: ${_controller.totalEntradas}',
                  style: pw.TextStyle(
                    color: PdfColors.green800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Total Saídas: ${_controller.totalSaidas}',
                  style: pw.TextStyle(
                    color: PdfColors.red800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(1.5),
              5: pw.FlexColumnWidth(2.0),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                children: [
                  _pdfCell('Produto', header: true),
                  _pdfCell('Tipo', header: true),
                  _pdfCell('Qtd / Und', header: true),
                  _pdfCell('Dt. Entrada', header: true),
                  _pdfCell('Dt. Saída', header: true),
                  _pdfCell('Observação', header: true),
                ],
              ),
              ...list.map((mov) {
                final isEntrada = mov.isEntrada;
                final dataE = _formatDateStr(mov.dataEntrada);
                final dataS = mov.dataSaida != null
                    ? _formatDateStr(mov.dataSaida!)
                    : '-';
                return pw.TableRow(
                  children: [
                    _pdfCell('${mov.productName} (${mov.productVolume})'),
                    _pdfCell(
                      mov.tipo,
                      color: isEntrada ? PdfColors.green800 : PdfColors.red800,
                    ),
                    _pdfCell(
                      '${mov.quantidade} ${mov.unidadeMedida}',
                      color: isEntrada ? PdfColors.green800 : PdfColors.red800,
                    ),
                    _pdfCell(dataE),
                    _pdfCell(dataS),
                    _pdfCell(mov.observacao ?? '-'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/relatorio_almoxarifado_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> _gerarPdf(List<MovementModel> list) async {
    final filePath = await _criarArquivoPdf(list);
    await Printing.layoutPdf(
      onLayout: (format) async => File(filePath).readAsBytes(),
      name:
          'relatorio_almoxarifado_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _compartilharRelatorio(List<MovementModel> list) async {
    try {
      final filePath = await _criarArquivoPdf(list);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Relatório de Movimentações - Almoxarifado',
          text: 'Segue o relatório em PDF do almoxarifado.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível compartilhar o relatório: $e'),
        ),
      );
    }
  }

  pw.Widget _pdfCell(String text, {bool header = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 10 : 9,
          fontWeight: header ? pw.FontWeight.bold : null,
          color: header ? PdfColors.white : (color ?? PdfColors.black),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _formatDateStr(String iso) {
    if (iso.isEmpty) {
      return '-';
    }
    try {
      return _dateFormat.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Relatório de Movimentações'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Selecionar Período',
            onPressed: _selectDateRange,
          ),
          SignalBuilder(
            builder: (context) {
              final list = _controller.movements.value;
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Compartilhar PDF',
                    onPressed: list.isEmpty
                        ? null
                        : () => _compartilharRelatorio(list),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print),
                    tooltip: 'Imprimir',
                    onPressed: list.isEmpty ? null : () => _gerarPdf(list),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context) {
          final start = _controller.startDate.value;
          final end = _controller.endDate.value;
          final list = _controller.movements.value;

          return Column(
            children: [
              // Banner de período e resumo
              Container(
                padding: const EdgeInsets.all(16.0),
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Período: ${_dateFormat.format(start)} a ${_dateFormat.format(end)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Alterar'),
                    ),
                  ],
                ),
              ),

              // Cards de resumo
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _summaryCard(
                      label: 'Entradas Totais',
                      value: _controller.totalEntradas.toString(),
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(width: 16),
                    _summaryCard(
                      label: 'Saídas Totais',
                      value: _controller.totalSaidas.toString(),
                      color: Colors.red,
                      icon: Icons.arrow_upward,
                    ),
                    const SizedBox(width: 16),
                    // Filtro por produto
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _controller.selectedProductId.value,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por produto',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ..._controller.products.value.map((p) {
                            return DropdownMenuItem<int?>(
                              value: p.id,
                              child: Text(p.nome),
                            );
                          }),
                        ],
                        onChanged: _controller.updateProductFilter,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de movimentações
              Expanded(
                child: _controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma movimentação no período.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final mov = list[index];
                          final isEntrada = mov.isEntrada;
                          final dtE = mov.dataEntrada.split('T')[0];
                          final dateE = dtE.isNotEmpty
                              ? _dateFormat
                                    .format(
                                      DateTime(
                                        int.parse(dtE.split('-')[0]),
                                        int.parse(dtE.split('-')[1]),
                                        int.parse(dtE.split('-')[2]),
                                      ),
                                    )
                                    .split(' ')[0]
                              : '';

                          final dataS = mov.dataSaida != null
                              ? DateTime.tryParse(mov.dataSaida!)
                              : null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isEntrada
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                child: Icon(
                                  isEntrada
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isEntrada ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                '${mov.productName} (${mov.productVolume})',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dateE.isNotEmpty) Text('Entrada: $dateE'),
                                  if (dataS != null)
                                    Text(
                                      'Saída: ${_dateFormat.format(dataS).split(' ')[0]}',
                                    ),
                                  if (mov.observacao != null)
                                    Text('Obs: ${mov.observacao}'),
                                ],
                              ),
                              trailing: Text(
                                '${isEntrada ? "+" : "-"}${mov.quantidade} ${mov.unidadeMedida}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEntrada ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: SignalBuilder(
        builder: (context) {
          final list = _controller.movements.value;
          return FloatingActionButton.extended(
            foregroundColor: Colors.white,
            onPressed: list.isEmpty ? null : () => _gerarPdf(list),
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

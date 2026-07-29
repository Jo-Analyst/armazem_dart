import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../core/routes/app_routes.dart';
import '../../controllers/backup_controller.dart';
import '../../controllers/settings_controller.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _backupController = locator<BackupController>();
  final _settingsController = locator<SettingsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _settingsController.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup e Restauração'), elevation: 2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                // Card principal de ações
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.backup,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gerenciamento de Backup',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Exporte ou restaure os dados do almoxarifado. '
                          'O backup automático é acionado ao fechar o aplicativo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Indicador de progresso (LinearProgressIndicator)
                        SignalBuilder(
                          builder: (context) {
                            final prog = _backupController.progress.value;
                            final loading = _backupController.isLoading.value;

                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: loading
                                  ? Column(
                                      key: const ValueKey('loading'),
                                      children: [
                                        LinearProgressIndicator(
                                          value: prog,
                                          backgroundColor: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          prog != null
                                              ? '${(prog * 100).toInt()}% — Processando...'
                                              : 'Processando...',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('idle'),
                                    ),
                            );
                          },
                        ),

                        // Status de mensagem
                        SignalBuilder(
                          builder: (context) {
                            final msg = _backupController.statusMessage.value;
                            final err = _backupController.isError.value;
                            final emailMsg =
                                _backupController.emailStatus.value;

                            if (msg == null && emailMsg == null) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              children: [
                                if (msg != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: err
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: err
                                            ? Colors.red.shade200
                                            : Colors.green.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      msg,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: err
                                            ? Colors.red.shade900
                                            : Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                if (emailMsg != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .secondaryContainer
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      emailMsg,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        // Botões de ação
                        SignalBuilder(
                          builder: (context) {
                            final loading = _backupController.isLoading.value;
                            return Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: loading
                                        ? null
                                        : () =>
                                              _backupController.exportBackup(),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Exportar Backup'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      foregroundColor:
                                          theme.colorScheme.onSecondary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: loading
                                        ? null
                                        : () => _confirmarRestauracao(context),
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Restaurar Backup'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Card de configuração do diretório de backup
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Diretório de Backup',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SignalBuilder(
                          builder: (context) {
                            final dir =
                                _settingsController.backupDirectory.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (dir != null && dir.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            dir,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    'Nenhum diretório configurado. '
                                    'O backup automático será salvo apenas temporariamente.',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final selected = await _backupController
                                        .selecionarDiretorioBackup();
                                    if (!mounted) return;
                                    if (selected != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Diretório configurado: $selected',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Escolher diretório'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarRestauracao(BuildContext context) {
    AppRoutes.showAppDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restaurar Backup?'),
          content: const Text(
            '⚠️ ATENÇÃO: A restauração substituirá todos os dados atuais!\n\n'
            'Certifique-se de escolher o arquivo .db correto.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _backupController.restoreBackup();
              },
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
  }
}

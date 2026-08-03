import 'dart:async';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../core/database/change_tracker.dart';
import '../repositories/backup_repository.dart';
import 'settings_controller.dart';

class BackupController {
  final BackupRepository _backupRepository;
  final SettingsController _settingsController;
  final DatabaseChangeTracker _changeTracker = DatabaseChangeTracker();

  BackupController(this._backupRepository, this._settingsController);

  final isLoading = signal(false);
  final progress = signal<double?>(
    null,
  ); // 0.0 a 1.0 para LinearProgressIndicator
  final statusMessage = signal<String?>(null);
  final isError = signal(false);
  final emailStatus = signal<String?>(null);

  Future<void> dispararBackupAutomatico() async {
    if (isLoading.value) return;
    unawaited(exportBackup(automatico: true));
  }

  Future<void> executarBackupSeHouverMudanca() async {
    if (!_changeTracker.hasPendingBackup) return;
    await exportBackup(automatico: true);
    _changeTracker.clearPendingBackup();
  }

  /// Executa o fluxo completo de backup:
  /// 1. Cria arquivo backup .db
  /// 2. Salva no diretório configurado
  /// 3. Compartilha nativamente (Android) ou copia (Windows)
  /// 4. Se online e SMTP configurado, envia por e-mail
  Future<void> exportBackup({bool automatico = false}) async {
    isLoading.value = true;
    progress.value = 0.1;
    statusMessage.value = automatico
        ? 'Backup automático em andamento...'
        : null;
    isError.value = false;
    emailStatus.value = null;

    try {
      // Passo 1: Cria arquivo de backup temporário
      progress.value = 0.3;
      final backupPath = await _backupRepository.criarArquivoBackup();

      // Passo 2: Salva no diretório configurado ou no diretório de fallback.
      progress.value = 0.5;
      final backupDir = _settingsController.backupDirectory.value;
      final destinoBackup = await _backupRepository.salvarBackupNoDestino(
        backupPath,
        backupDir != null && backupDir.isNotEmpty
            ? backupDir
            : await _backupRepository.getDefaultBackupDirectory(),
      );

      // Passo 3: Ajusta status do backup local antes do envio por e-mail.
      progress.value = 0.7;
      if (!automatico) {
        statusMessage.value = 'Backup salvo em: $destinoBackup';
      }

      // Passo 4: Envio por e-mail se online e SMTP configurado
      progress.value = 0.85;
      final temConexao = await _backupRepository.temConexao();
      if (temConexao && _settingsController.smtpConfigurado) {
        try {
          // Compacta antes de enviar por e-mail
          final zipPath = await _backupRepository.criarZipBackup();
          await _backupRepository.enviarPorEmail(
            arquivoPath: zipPath,
            smtpHost: _settingsController.smtpHost.value,
            smtpPort: _settingsController.smtpPort.value,
            smtpUser: _settingsController.smtpUser.value,
            smtpPassword: _settingsController.smtpPassword.value,
            emailDestino: _settingsController.emailDestino.value,
            ssl: _settingsController.smtpSsl.value,
          );
          // Limpa zip temporário
          try {
            File(zipPath).deleteSync();
          } catch (_) {}
          emailStatus.value =
              '✅ Backup enviado para ${_settingsController.emailDestino.value}';
        } catch (e) {
          emailStatus.value = '⚠️ Falha ao enviar e-mail: ${e.toString()}';
        }
      } else if (!temConexao) {
        emailStatus.value = 'Sem internet — e-mail não enviado.';
      } else {
        emailStatus.value = 'SMTP não configurado — e-mail não enviado.';
      }

      // Limpa o arquivo temporário
      try {
        File(backupPath).deleteSync();
      } catch (_) {}

      progress.value = 1.0;
      statusMessage.value = automatico
          ? 'Backup automático concluído com sucesso!'
          : 'Backup exportado com sucesso!';
      _changeTracker.clearPendingBackup();
    } catch (e) {
      isError.value = true;
      statusMessage.value = 'Erro ao exportar backup: $e';
      progress.value = null;
    } finally {
      isLoading.value = false;
      await Future.delayed(const Duration(milliseconds: 400));
      progress.value = null;
    }
  }

  Future<void> restoreBackup() async {
    isLoading.value = true;
    progress.value = 0.1;
    statusMessage.value = 'Selecione o arquivo de backup (.db)...';
    isError.value = false;
    emailStatus.value = null;

    try {
      // Passo 1: Abrir seletor de arquivo para escolher o backup
      progress.value = 0.3;
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Database files',
        extensions: <String>['db'],
      );
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );

      if (file == null) {
        statusMessage.value = 'Nenhum arquivo selecionado.';
        isLoading.value = false;
        progress.value = null;
        return;
      }

      // Passo 2: Validar o arquivo selecionado
      progress.value = 0.5;
      final sourceFile = File(file.path);
      if (!await sourceFile.exists()) {
        throw Exception('Arquivo selecionado não encontrado: ${file.path}');
      }

      // Passo 3: Restaurar o backup
      progress.value = 0.7;
      statusMessage.value = 'Restaurando banco de dados...';
      await _backupRepository.restaurarBackup(file.path);

      progress.value = 1.0;
      statusMessage.value = 'Backup restaurado com sucesso!';
    } catch (e) {
      isError.value = true;
      statusMessage.value = 'Erro ao restaurar backup: $e';
      progress.value = null;
    } finally {
      isLoading.value = false;
      await Future.delayed(const Duration(milliseconds: 400));
      progress.value = null;
    }
  }

  /// Abre um seletor de diretório para o usuário escolher o local do backup.
  Future<String?> selecionarDiretorioBackup() async {
    try {
      final String? selectedDirectory = await getDirectoryPath();

      if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
        return null;
      }

      await _settingsController.salvarDiretorioBackup(selectedDirectory);
      return selectedDirectory;
    } catch (e) {
      isError.value = true;
      statusMessage.value = 'Não foi possível abrir o seletor de pasta: $e';
      return null;
    }
  }
}

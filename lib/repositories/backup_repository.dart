import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/database/database_helper.dart';

class BackupRepository {
  final DatabaseHelper _dbHelper;

  BackupRepository(this._dbHelper);

  /// Cria uma cópia .db do banco no diretório temporário e retorna o caminho.
  Future<String> criarArquivoBackup() async {
    final dbPath = await _dbHelper.getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Arquivo de banco de dados não encontrado em: $dbPath');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'backup_armazem_$timestamp.db';
    final tempFile = File(p.join(tempDir.path, fileName));
    await dbFile.copy(tempFile.path);
    return tempFile.path;
  }

  /// Retorna o diretório padrão para salvar backups quando não houver configuração.
  Future<String> getDefaultBackupDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final backupDir = Directory(p.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// Cria um arquivo .zip contendo o backup .db e retorna o caminho.
  Future<String> criarZipBackup() async {
    final backupPath = await criarArquivoBackup();
    final backupFile = File(backupPath);
    final zipPath = backupPath.replaceAll('.db', '.zip');

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addFile(backupFile);
    encoder.close();

    // Limpa o .db temporário após zipar
    try {
      await backupFile.delete();
    } catch (_) {}

    return zipPath;
  }

  /// Copia o arquivo de backup para o [destinoDir] informado.
  Future<String> salvarBackupNoDestino(
    String arquivoOrigem,
    String destinoDir,
  ) async {
    final dir = Directory(destinoDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final nomeArquivo = p.basename(arquivoOrigem);
    final destino = p.join(destinoDir, nomeArquivo);
    await File(arquivoOrigem).copy(destino);
    return destino;
  }

  /// Restaura o banco de dados a partir de um arquivo .db informado.
  Future<void> restaurarBackup(String filePath) async {
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      throw Exception('Arquivo de restauração não encontrado: $filePath');
    }

    final dbPath = await _dbHelper.getDatabasePath();
    await _dbHelper.close();

    try {
      await sourceFile.copy(dbPath);
    } finally {
      // Sempre re-abre o banco, mesmo em caso de erro
      await _dbHelper.database;
    }
  }

  /// Verifica se há conexão com a internet.
  Future<bool> temConexao() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Envia o arquivo de backup por e-mail via SMTP.
  Future<void> enviarPorEmail({
    required String arquivoPath,
    required String smtpHost,
    required int smtpPort,
    required String smtpUser,
    required String smtpPassword,
    required String emailDestino,
    bool ssl = false,
  }) async {
    final smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: smtpUser,
      password: smtpPassword,
      ssl: ssl,
      ignoreBadCertificate: false,
      allowInsecure: !ssl,
    );

    final nomeArquivo = p.basename(arquivoPath);
    final message = Message()
      ..from = Address(smtpUser, 'Controle de Almoxarifado')
      ..recipients.add(emailDestino)
      ..subject = 'Backup Almoxarifado — ${DateTime.now().toLocal()}'
      ..text =
          'Backup automático do sistema de Controle de Almoxarifado.\n'
          'Arquivo: $nomeArquivo\n'
          'Data: ${DateTime.now().toLocal()}'
      ..attachments = [
        FileAttachment(File(arquivoPath))..location = Location.attachment,
      ];

    await send(message, smtpServer);
  }
}

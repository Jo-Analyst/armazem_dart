import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Chaves de configuração persistidas em SharedPreferences
class _Keys {
  static const backupDir = 'backup_directory';
  static const smtpHost = 'smtp_host';
  static const smtpPort = 'smtp_port';
  static const smtpUser = 'smtp_user';
  static const smtpPassword = 'smtp_password';
  static const smtpSsl = 'smtp_ssl';
  static const emailDestino = 'email_destino';
  static const backupSetup = 'backup_setup_done';
}

class SettingsController {
  // Diretório de backup
  final backupDirectory = signal<String?>('');
  final backupSetupDone = signal(false);

  // SMTP
  final smtpHost = signal<String>('');
  final smtpPort = signal<int>(587);
  final smtpUser = signal<String>('');
  final smtpPassword = signal<String>('');
  final smtpSsl = signal<bool>(false);
  final emailDestino = signal<String>('');

  final isLoading = signal(false);

  Future<void> load() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      backupDirectory.value = prefs.getString(_Keys.backupDir);
      backupSetupDone.value = prefs.getBool(_Keys.backupSetup) ?? false;
      smtpHost.value = prefs.getString(_Keys.smtpHost) ?? '';
      smtpPort.value = prefs.getInt(_Keys.smtpPort) ?? 587;
      smtpUser.value = prefs.getString(_Keys.smtpUser) ?? '';
      smtpPassword.value = prefs.getString(_Keys.smtpPassword) ?? '';
      smtpSsl.value = prefs.getBool(_Keys.smtpSsl) ?? false;
      emailDestino.value = prefs.getString(_Keys.emailDestino) ?? '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> salvarDiretorioBackup(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_Keys.backupDir, path);
    await prefs.setBool(_Keys.backupSetup, true);
    backupDirectory.value = path;
    backupSetupDone.value = true;
  }

  Future<void> salvarConfigSmtp({
    required String host,
    required int port,
    required String user,
    required String password,
    required bool ssl,
    required String destino,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_Keys.smtpHost, host);
    await prefs.setInt(_Keys.smtpPort, port);
    await prefs.setString(_Keys.smtpUser, user);
    await prefs.setString(_Keys.smtpPassword, password);
    await prefs.setBool(_Keys.smtpSsl, ssl);
    await prefs.setString(_Keys.emailDestino, destino);
    smtpHost.value = host;
    smtpPort.value = port;
    smtpUser.value = user;
    smtpPassword.value = password;
    smtpSsl.value = ssl;
    emailDestino.value = destino;
  }

  bool get smtpConfigurado =>
      smtpHost.value.isNotEmpty &&
      smtpUser.value.isNotEmpty &&
      smtpPassword.value.isNotEmpty &&
      emailDestino.value.isNotEmpty;
}

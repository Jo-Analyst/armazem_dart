import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/locator/locator.dart';
import '../../controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = locator<SettingsController>();
  final _formKey = GlobalKey<FormState>();

  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _destinoController = TextEditingController();
  bool _ssl = false;
  bool _obscurePassword = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.load();
      _hostController.text = _controller.smtpHost.value;
      _portController.text = _controller.smtpPort.value.toString();
      _userController.text = _controller.smtpUser.value;
      _passwordController.text = _controller.smtpPassword.value;
      _destinoController.text = _controller.emailDestino.value;
      setState(() => _ssl = _controller.smtpSsl.value);
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _destinoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _controller.salvarConfigSmtp(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        user: _userController.text.trim(),
        password: _passwordController.text,
        ssl: _ssl,
        destino: _destinoController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações SMTP salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('Configurações'),
        elevation: 2,
      ),
      body: SignalBuilder(
        builder: (context) {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho da seção
                      Row(
                        children: [
                          Icon(Icons.email, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Configurações de E-mail (SMTP)',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure o servidor SMTP para envio automático de backups por e-mail.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status de configuração
                      if (_controller.smtpConfigurado)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('SMTP configurado e pronto para uso.'),
                            ],
                          ),
                        ),

                      // Servidor SMTP + Porta
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _hostController,
                              decoration: const InputDecoration(
                                labelText: 'Servidor SMTP *',
                                hintText: 'Ex: smtp.gmail.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.dns),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Informe o servidor SMTP';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Porta *',
                                hintText: '587',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                final port = int.tryParse(val ?? '');
                                if (port == null || port <= 0) {
                                  return 'Porta inválida';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Usuário
                      TextFormField(
                        controller: _userController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Usuário / E-mail de envio *',
                          hintText: 'seuemail@gmail.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Informe o usuário';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Senha
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha / App Password *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Informe a senha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // E-mail destinatário
                      TextFormField(
                        controller: _destinoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail Destinatário *',
                          hintText: 'destino@exemplo.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.send),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Informe o e-mail destinatário';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // SSL
                      SwitchListTile(
                        title: const Text('Usar SSL/TLS'),
                        subtitle: const Text(
                          'Ative para portas 465 (SSL). '
                          'Para porta 587 (TLS), mantenha desativado.',
                        ),
                        value: _ssl,
                        onChanged: (val) => setState(() => _ssl = val),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Dica para Gmail
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 Dica para Gmail:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Host: smtp.gmail.com | Porta: 587 | SSL: Desativado\n'
                              'Use uma "Senha de App" gerada em: '
                              'Conta Google → Segurança → Senhas de App',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botão Salvar
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _salvar,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _saving ? 'Salvando...' : 'Salvar Configurações',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Sobre o Aplicativo'),
        backgroundColor: Colors.teal,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.info, size: 80, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                'Almoxarifado',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '''Este aplicativo foi desenvolvido para otimizar o controle e a organização de estoques de alimentos e produtos de limpeza.
                 Ele oferece funcionalidades para registrar a entrada e saída de insumos, gerenciar níveis mínimos de estoque, e acompanhar o histórico de consumo''',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[300]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Desenvolvido por:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Joelmir Rogério Carvalho', // Nome do desenvolvedor, ajustado com base no caminho do projeto
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.teal,
                  fontStyle: FontStyle.italic,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Versão: 1.0.0', // Você pode atualizar a versão conforme necessário
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

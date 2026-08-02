import 'dart:io';
import 'package:armazem/pages/about/about_page.dart';
import 'package:armazem/pages/armazem_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:window_manager/window_manager.dart';
import '../controllers/backup_controller.dart';
import '../core/locator/locator.dart';
import '../controllers/settings_controller.dart';
import 'categories/categories_page.dart';
import 'products/products_page.dart';
import 'movements/movements_page.dart';
import 'reports/reports_page.dart';
import 'backup/backup_page.dart';
import 'settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  int _selectedIndex = 0;

  final _settingsController = locator<SettingsController>();
  final _backupController = locator<BackupController>();

  final List<Widget> _pages = [
    const ArmazemPage(),
    const ProductsPage(),
    const CategoriesPage(),
    const MovementsPage(),
    const ReportsPage(),
    const BackupPage(),
    const AboutPage(),
    const SettingsPage(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Início',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Produtos',
    ),
    NavigationDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category),
      label: 'Categorias',
    ),
    NavigationDestination(
      // icon: Icon(Icons.swap_horiz_outlined),
      icon: Icon(Icons.move_down_outlined),
      selectedIcon: Icon(Icons.move_down),
      label: 'Movimentações',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Relatórios',
    ),
    NavigationDestination(
      icon: Icon(Icons.backup_outlined),
      selectedIcon: Icon(Icons.backup),
      label: 'Backup',
    ),
    NavigationDestination(
      icon: Icon(Icons.info_outline),
      selectedIcon: Icon(Icons.info),
      label: 'Sobre',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Configurações',
    ),
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _settingsController.load();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    if (!mounted) return;
    _confirmarSaida(context, fecharAposBackup: true);
  }

  Future<void> _confirmarSaida(
    BuildContext context, {
    bool fecharAposBackup = true,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Finalizando aplicativo'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SignalBuilder(
                  builder: (context) {
                    final hasPendingBackup =
                        _backupController.isLoading.value ||
                        _backupController.progress.value != null ||
                        _backupController.statusMessage.value != null ||
                        _backupController.isError.value;

                    if (!hasPendingBackup) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Carregando o fechamento...',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final loading = _backupController.isLoading.value;
                    final progress = _backupController.progress.value;
                    final message = _backupController.statusMessage.value;
                    final error = _backupController.isError.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Criando backup automático antes de fechar o app.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loading
                              ? (progress != null
                                    ? '${(progress * 100).toInt()}% — Processando...'
                                    : 'Processando...')
                              : (message ?? 'Finalizando...'),
                          style: TextStyle(
                            color: error
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await _backupController.executarBackupSeHouverMudanca();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (fecharAposBackup) {
        _fecharAplicativo();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Não foi possível concluir o backup ao sair: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _fecharAplicativo();
    }
  }

  void _fecharAplicativo() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              title: const Text('Almoxarifado'),
              elevation: 2,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  tooltip: 'Sair',
                  onPressed: () => _confirmarSaida(context),
                ),
              ],
            )
          : null,
      drawer: !isDesktop
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: theme.colorScheme.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warehouse,
                          size: 48,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Almoxarifado',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(_destinations.length, (index) {
                    final dest = _destinations[index];
                    return ListTile(
                      leading: _selectedIndex == index
                          ? dest.selectedIcon
                          : dest.icon,
                      title: Text(dest.label),
                      selected: _selectedIndex == index,
                      selectedTileColor: theme.colorScheme.primaryContainer,
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Sair'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmarSaida(context);
                    },
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop) ...[
            NavigationRail(
              extended: MediaQuery.of(context).size.width >= 1100,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.warehouse,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    if (MediaQuery.of(context).size.width >= 1100)
                      Text(
                        'Almoxarifado',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

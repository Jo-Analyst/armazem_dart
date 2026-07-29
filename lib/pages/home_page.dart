import 'package:flutter/material.dart';
import '../core/locator/locator.dart';
import '../controllers/backup_controller.dart';
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

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final AppLifecycleListener _lifecycleListener;

  final _backupController = locator<BackupController>();
  final _settingsController = locator<SettingsController>();

  final List<Widget> _pages = [
    const ProductsPage(),
    const CategoriesPage(),
    const MovementsPage(),
    const ReportsPage(),
    const BackupPage(),
    const SettingsPage(),
  ];

  final List<NavigationDestination> _destinations = const [
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
      icon: Icon(Icons.swap_horiz_outlined),
      selectedIcon: Icon(Icons.swap_horiz),
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
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Configurações',
    ),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _settingsController.load();
    });

    // Backup automático ao pausar/fechar o aplicativo
    _lifecycleListener = AppLifecycleListener(
      onPause: _executarBackupAutomatico,
      onDetach: _executarBackupAutomatico,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _executarBackupAutomatico() async {
    try {
      await _backupController.exportBackup(automatico: true);
    } catch (_) {
      // Backup automático falha silenciosamente — não interrompe o fechamento
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(title: const Text('Almoxarifado'), elevation: 2)
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

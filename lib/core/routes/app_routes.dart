import 'package:flutter/material.dart';
import '../../pages/backup/backup_page.dart';
import '../../pages/categories/categories_page.dart';
import '../../pages/home_page.dart';
import '../../pages/movements/movements_page.dart';
import '../../pages/products/products_page.dart';
import '../../pages/reports/reports_page.dart';
import '../../pages/settings/settings_page.dart';

class AppRoutes {
  static const home = '/';
  static const products = '/products';
  static const categories = '/categories';
  static const movements = '/movements';
  static const reports = '/reports';
  static const backup = '/backup';
  static const settings = '/settings';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomePage(),
    products: (_) => const ProductsPage(),
    categories: (_) => const CategoriesPage(),
    movements: (_) => const MovementsPage(),
    reports: (_) => const ReportsPage(),
    backup: (_) => const BackupPage(),
    settings: (_) => const SettingsPage(),
  };

  static Route<T> onGenerateRoute<T>(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return _buildRoute<T>(settings, builder);
    }

    return _buildRoute<T>(settings, (_) => const HomePage());
  }

  static Route<T> _buildRoute<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.03, 0.0);
        const end = Offset.zero;
        final curve = Curves.easeOutCubic;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        final fadeTween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }

  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}

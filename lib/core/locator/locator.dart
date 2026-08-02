import 'package:armazem/controllers/backup_controller.dart';
import 'package:armazem/controllers/category_controller.dart';
import 'package:armazem/controllers/movement_controller.dart';
import 'package:armazem/controllers/product_controller.dart';
import 'package:armazem/controllers/report_controller.dart';
import 'package:armazem/controllers/settings_controller.dart';
import 'package:armazem/core/database/change_tracker.dart';
import 'package:armazem/core/database/database_helper.dart';
import 'package:armazem/repositories/backup_repository.dart';
import 'package:armazem/repositories/category_repository.dart';
import 'package:armazem/repositories/movement_repository.dart';
import 'package:armazem/repositories/product_repository.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Database Helper (Singleton — uma única instância durante todo o ciclo de vida)
  locator.registerSingleton<DatabaseHelper>(DatabaseHelper());
  locator.registerLazySingleton<DatabaseChangeTracker>(
    () => DatabaseChangeTracker(),
  );

  // Repositories
  locator.registerLazySingleton<CategoryRepository>(
    () => CategoryRepository(locator<DatabaseHelper>()),
  );
  locator.registerLazySingleton<ProductRepository>(
    () => ProductRepository(locator<DatabaseHelper>()),
  );
  locator.registerLazySingleton<MovementRepository>(
    () => MovementRepository(locator<DatabaseHelper>()),
  );
  locator.registerLazySingleton<BackupRepository>(
    () => BackupRepository(locator<DatabaseHelper>()),
  );

  // Settings Controller (registrado antes do BackupController que depende dele)
  locator.registerLazySingleton<SettingsController>(() => SettingsController());

  // Controllers
  locator.registerLazySingleton<CategoryController>(
    () => CategoryController(locator<CategoryRepository>()),
  );
  locator.registerLazySingleton<ProductController>(
    () => ProductController(
      locator<ProductRepository>(),
      locator<CategoryRepository>(),
    ),
  );
  locator.registerLazySingleton<MovementController>(
    () => MovementController(
      locator<MovementRepository>(),
      locator<ProductRepository>(),
    ),
  );
  locator.registerLazySingleton<ReportController>(
    () => ReportController(
      locator<MovementRepository>(),
      locator<ProductRepository>(),
    ),
  );
  locator.registerLazySingleton<BackupController>(
    () => BackupController(
      locator<BackupRepository>(),
      locator<SettingsController>(),
    ),
  );
}

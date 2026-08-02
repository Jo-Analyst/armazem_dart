import 'package:signals_flutter/signals_flutter.dart';
import '../core/database/change_tracker.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryController {
  final CategoryRepository _repository;
  final DatabaseChangeTracker _changeTracker = DatabaseChangeTracker();

  CategoryController(this._repository);

  final categories = listSignal<CategoryModel>([]);
  final isLoading = signal(false);
  final error = signal<String?>(null);

  Future<void> loadCategories() async {
    isLoading.value = true;
    error.value = null;
    try {
      final list = await _repository.getAll();
      categories.value = list;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory(String name) async {
    if (name.trim().isEmpty) return;
    isLoading.value = true;
    error.value = null;
    try {
      await _repository.insert(CategoryModel(name: name.trim()));
      _changeTracker.markChanged();
      await loadCategories();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editCategory(CategoryModel category) async {
    isLoading.value = true;
    error.value = null;
    try {
      await _repository.update(category);
      _changeTracker.markChanged();
      await loadCategories();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCategory(int id) async {
    isLoading.value = true;
    error.value = null;
    try {
      await _repository.delete(id);
      _changeTracker.markChanged();
      await loadCategories();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}

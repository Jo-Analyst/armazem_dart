import 'package:signals_flutter/signals_flutter.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryController {
  final CategoryRepository _repository;

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
      await loadCategories();
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}

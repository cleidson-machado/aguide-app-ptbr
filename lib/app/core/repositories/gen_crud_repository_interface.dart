import 'package:portugal_guide/app/core/base/base_model.dart';

//### ATTENTION: This code is for a generic Crud repository interface for the MVVM pattern. ###

abstract class GenCrudRepositoryInterface<T extends BaseModel> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<bool> destroy(String id);
}
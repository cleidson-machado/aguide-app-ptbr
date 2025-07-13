// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
// MUDANÇA 1: Importar o pacote 'meta' para a anotação @protected
import 'package:meta/meta.dart';
import 'package:portugal_guide/app/core/base/base_model.dart';
import 'package:portugal_guide/app/core/repositories/gen_crud_repository_interface.dart';

//### ATTENTION: This code is for a generic Crud repository class for the MVVM pattern. ###

class GenCrudRepository<T extends BaseModel> implements GenCrudRepositoryInterface<T> {
  final Dio _dio;
  final String _endpoint;
  final T Function(Map<String, dynamic>) _fromMap;

  GenCrudRepository({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromMap,
    Dio? dio,
  })  : _endpoint = endpoint,
        _fromMap = fromMap,
        _dio = dio ?? Dio();

  // MUDANÇA 2: Criar getters públicos, mas protegidos, para as subclasses
  @protected
  Dio get dioGenCrudRepo => _dio;

  @protected
  String get endpointGenCrudRepo => _endpoint;

  @protected
  T Function(Map<String, dynamic>) get fromMap => _fromMap;


  // Os métodos de CRUD genéricos continuam aqui, sem alterações...
  @override
  Future<List<T>> getAll() async {
    try {
      final response = await _dio.get(_endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => _fromMap(json)).toList();
      }
      throw Exception('Failed to load items');
    } catch (e) {
      throw Exception('Error fetching items: $e');
    }
  }

  @override
  Future<T?> getById(String id) async {
    try {
      final response = await _dio.get('$_endpoint/$id');
      if (response.statusCode == 200) {
        return _fromMap(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching item: $e');
    }
  }

  @override
  Future<T> create(T item) async {
    try {
      final response = await _dio.post(
        _endpoint,
        data: item.toMap(),
      );
      if (response.statusCode == 201) {
        return _fromMap(response.data);
      }
      throw Exception('Failed to create item');
    } catch (e) {
      throw Exception('Error creating item: $e');
    }
  }

  @override
  Future<T> update(T item) async {
    try {
      final response = await _dio.put(
        '$_endpoint/${item.id}',
        data: item.toMap(),
      );
      if (response.statusCode == 200) {
        return _fromMap(response.data);
      }
      throw Exception('Failed to update item');
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  @override
  Future<bool> destroy(String id) async {
    try {
      final response = await _dio.delete('$_endpoint/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting item: $e');
    }
  }
}
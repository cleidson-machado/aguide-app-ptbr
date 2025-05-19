// lib/core/repositories/api_repository.dart
import 'package:dio/dio.dart';
import 'package:portugal_guide/app/core/base/base_model.dart';
import 'package:portugal_guide/app/core/repositories/base_repository.dart';

class ApiRepository<T extends BaseModel> implements BaseRepository<T> {
  final Dio _dio;
  final String _endpoint;
  final T Function(Map<String, dynamic>) _fromMap;

  ApiRepository({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromMap,
    Dio? dio,
  }) : _endpoint = endpoint,
       _fromMap = fromMap,
       _dio = dio ?? Dio();

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
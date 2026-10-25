import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'featured_content_models.dart';
import 'user_relation_featured_content_repository_interface.dart';
import 'user_relation_network_dio_factory.dart';

/// Leitor de catálogo (`/contents`) e top-contents do usuário (`/engagements`)
/// para "Temas em Destaque".
///
/// NOTE: `MainContentTopicRepository` cobre `/contents`, mas usa paginação
/// 1-based no app e um model com casts estritos. Este repositório envia a
/// página 0-based direto e usa DTOs tolerantes, sem alterar main_contents.
class UserRelationFeaturedContentRepository
    implements UserRelationFeaturedContentRepositoryInterface {
  static const int _maxPageSize = 100;
  static const String _contentsEndpoint = '/contents';

  final Dio _dio;

  UserRelationFeaturedContentRepository({Dio? dio})
    : _dio = dio ?? buildUserRelationNetworkDio();

  String _buildContentByIdEndpoint(String contentId) =>
      '$_contentsEndpoint/$contentId';

  String _buildUserTopContentsEndpoint(String userId) =>
      '/engagements/user/$userId/top-contents';

  @override
  Future<List<FeaturedContentRecord>> getLatestContents({int size = 30}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _contentsEndpoint,
      queryParameters: {
        'page': 0,
        'size': size.clamp(1, _maxPageSize),
        'sort': 'publishedAt',
        'order': 'desc',
      },
    );

    final List<FeaturedContentRecord> contents = _parseList(
      response.data?['content'],
      FeaturedContentRecord.fromJson,
    );

    if (kDebugMode) {
      debugPrint(
        '🎯 [UserRelationFeaturedContentRepository] ${contents.length} conteúdo(s) do catálogo',
      );
    }
    return contents;
  }

  @override
  Future<List<UserTopContent>> getUserTopContents({
    required String userId,
    int limit = 12,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _buildUserTopContentsEndpoint(userId),
      queryParameters: {'limit': limit.clamp(1, _maxPageSize)},
    );

    final List<UserTopContent> topContents = _parseList(
      response.data?['topContents'],
      UserTopContent.fromJson,
    ).where((top) => top.contentId.isNotEmpty).toList();

    if (kDebugMode) {
      debugPrint(
        '🎯 [UserRelationFeaturedContentRepository] ${topContents.length} top-content(s) do usuário',
      );
    }
    return topContents;
  }

  @override
  Future<FeaturedContentRecord> getContentById(String contentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _buildContentByIdEndpoint(contentId),
    );
    final Map<String, dynamic>? data = response.data;
    if (data == null) {
      throw StateError('Conteúdo $contentId sem corpo de resposta');
    }
    return FeaturedContentRecord.fromJson(data);
  }

  List<T> _parseList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}

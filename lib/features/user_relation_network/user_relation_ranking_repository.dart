import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'user_ranking_summary_model.dart';
import 'user_relation_network_dio_factory.dart';
import 'user_relation_ranking_repository_interface.dart';

/// Leitor do leaderboard (`/user-rankings/top`) para a tela de relações.
///
/// NOTE: `UserTrackingDataRepository.getTopUsersByScore` cobre o mesmo
/// endpoint, mas devolve `[]` em qualquer erro e depende de um model que
/// falha com timestamps nulos. Este repositório propaga o erro e usa um DTO
/// tolerante, sem alterar a feature user_tracking_data.
class UserRelationRankingRepository
    implements UserRelationRankingRepositoryInterface {
  static const int _maxLimit = 100;

  final Dio _dio;

  UserRelationRankingRepository({Dio? dio})
      : _dio = dio ?? buildUserRelationNetworkDio();

  String _buildTopRankingsEndpoint() => '/user-rankings/top';

  @override
  Future<List<UserRankingSummaryModel>> getTopRankings({int limit = 10}) async {
    final int safeLimit = limit.clamp(1, _maxLimit);

    final response = await _dio.get<List<dynamic>>(
      _buildTopRankingsEndpoint(),
      queryParameters: {'limit': safeLimit},
    );

    final List<dynamic> data = response.data ?? const [];
    final rankings = data
        .whereType<Map<String, dynamic>>()
        .where((json) => json['userId'] is String)
        .map(UserRankingSummaryModel.fromJson)
        .toList();

    if (kDebugMode) {
      debugPrint(
          '🏆 [UserRelationRankingRepository] ${rankings.length} ranking(s) recebido(s) (limit=$safeLimit)');
    }

    return rankings;
  }
}

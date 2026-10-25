import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_http_interceptor.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/correlation_id_interceptor.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'user_ranking_summary_model.dart';
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

  UserRelationRankingRepository({Dio? dio}) : _dio = dio ?? _setupDio();

  static Dio _setupDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvKeyHelperConfig.apiBaseUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.addAll([
      AuthHttpInterceptor(
        injector<AuthTokenManager>(),
        fallbackToken: EnvKeyHelperConfig.tokenKeyForMocApi2,
      ),
      CorrelationIdInterceptor(),
      LatencyInterceptor(),
    ]);

    return dio;
  }

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

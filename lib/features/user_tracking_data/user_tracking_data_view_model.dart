import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_service.dart';

/// Estados possíveis do carregamento de dados
enum UserTrackingState {
  initial,
  loading,
  loaded,
  error,
}

/// ViewModel para gerenciar estado de User Tracking Data
/// 
/// Documentação: .local_knowledge/FLUTTER_USER_TRACKING_MVP_GUIDE.md
/// 
/// 🎯 Responsabilidades:
/// - State management (ChangeNotifier)
/// - Carregar estatísticas do usuário
/// - Carregar leaderboard (top usuários)
/// - Notificar UI de mudanças
/// 
/// Quando usar:
/// - Tela de perfil (exibir estatísticas)
/// - Tela de leaderboard (exibir ranking)
/// - Dashboard (exibir widgets de gamificação)
/// 
/// Exemplo de uso:
/// ```dart
/// final viewModel = injector<UserTrackingDataViewModel>();
/// viewModel.loadUserStats(currentUserId);
/// 
/// // Em um StatefulWidget
/// ListenableBuilder(
///   listenable: viewModel,
///   builder: (context, child) {
///     if (viewModel.isLoading) return CupertinoActivityIndicator();
///     return Text('Score: ${viewModel.userStats?.totalScore}');
///   },
/// )
/// ```
class UserTrackingDataViewModel extends ChangeNotifier {
  final UserTrackingDataService _service;

  UserTrackingState _state = UserTrackingState.initial;
  String? _errorMessage;

  // Estatísticas do usuário
  UserTrackingDataModel? _userStats;

  // Leaderboard (top usuários)
  List<UserTrackingDataModel> _topUsers = [];

  // Posição no ranking global
  int? _userRankPosition;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔍 GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  UserTrackingState get state => _state;
  String? get errorMessage => _errorMessage;
  UserTrackingDataModel? get userStats => _userStats;
  List<UserTrackingDataModel> get topUsers => _topUsers;
  int? get userRankPosition => _userRankPosition;

  bool get isLoading => _state == UserTrackingState.loading;
  bool get hasError => _state == UserTrackingState.error;
  bool get hasData => _userStats != null;

  UserTrackingDataViewModel(this._service);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 MÉTODOS PÚBLICOS - CARREGAR DADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carrega estatísticas do usuário
  /// 
  /// Quando usar: Ao abrir tela de perfil ou dashboard
  /// 
  /// Exemplo:
  /// ```dart
  /// viewModel.loadUserStats(currentUserId);
  /// ```
  Future<void> loadUserStats(String userId) async {
    _state = UserTrackingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('📊 [UserTrackingDataViewModel] Carregando estatísticas...');
      }

      final stats = await _service.getUserStats(userId);

      if (stats != null) {
        _userStats = stats;
        _state = UserTrackingState.loaded;

        if (kDebugMode) {
          print('✅ [UserTrackingDataViewModel] Estatísticas carregadas:');
          print('   - Score: ${stats.totalScore}');
          print('   - Level: ${stats.engagementLevel}');
          print('   - Streak: ${stats.consecutiveDaysStreak} dias');
        }
      } else {
        _state = UserTrackingState.error;
        _errorMessage = 'Usuário não possui ranking ainda';

        if (kDebugMode) {
          print('⚠️  [UserTrackingDataViewModel] Ranking não encontrado');
        }
      }
    } catch (e) {
      _state = UserTrackingState.error;
      _errorMessage = 'Erro ao carregar estatísticas: $e';

      if (kDebugMode) {
        print('❌ [UserTrackingDataViewModel] Erro: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  /// Carrega top N usuários (leaderboard)
  /// 
  /// Quando usar: Ao abrir tela de ranking/leaderboard
  /// 
  /// Exemplo:
  /// ```dart
  /// viewModel.loadTopUsers(limit: 10);
  /// ```
  Future<void> loadTopUsers({int limit = 10}) async {
    try {
      if (kDebugMode) {
        print('🏆 [UserTrackingDataViewModel] Carregando top $limit usuários');
      }

      final top = await _service.getTopUsers(limit: limit);

      _topUsers = top;
      notifyListeners();

      if (kDebugMode) {
        print('✅ [UserTrackingDataViewModel] Top ${top.length} carregado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataViewModel] Erro ao carregar top: $e');
      }
    }
  }

  /// Carrega posição do usuário no ranking global
  /// 
  /// Quando usar: Exibir "Você está em 5º lugar" na UI
  /// 
  /// Exemplo:
  /// ```dart
  /// await viewModel.loadUserRankPosition(userId);
  /// print('Posição: ${viewModel.userRankPosition}º');
  /// ```
  Future<void> loadUserRankPosition(String userId) async {
    try {
      if (kDebugMode) {
        print('🔢 [UserTrackingDataViewModel] Calculando posição no ranking');
      }

      final position = await _service.getUserRankPosition(userId);

      _userRankPosition = position;
      notifyListeners();

      if (kDebugMode) {
        if (position != null) {
          print('✅ [UserTrackingDataViewModel] Posição: $positionº');
        } else {
          print('⚠️  [UserTrackingDataViewModel] Posição não encontrada');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataViewModel] Erro ao calcular posição: $e');
      }
    }
  }

  /// Carrega TUDO de uma vez (stats + top + position)
  /// 
  /// Quando usar: Dashboard completo ou tela de perfil com ranking
  /// 
  /// Exemplo:
  /// ```dart
  /// await viewModel.loadComplete(userId);
  /// ```
  Future<void> loadComplete(String userId, {int topLimit = 10}) async {
    _state = UserTrackingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Carregar em paralelo para otimizar tempo
      await Future.wait([
        loadUserStats(userId),
        loadTopUsers(limit: topLimit),
        loadUserRankPosition(userId),
      ]);

      _state = UserTrackingState.loaded;
    } catch (e) {
      _state = UserTrackingState.error;
      _errorMessage = 'Erro ao carregar dados completos: $e';

      if (kDebugMode) {
        print('❌ [UserTrackingDataViewModel] Erro completo: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  /// Atualiza apenas estatísticas do usuário (refresh silencioso)
  /// 
  /// Quando usar: Após adicionar pontos, para atualizar UI
  /// 
  /// ⚠️ NÃO altera state para loading (não mostra spinner)
  Future<void> refreshUserStats(String userId) async {
    try {
      final stats = await _service.getUserStats(userId);

      if (stats != null) {
        _userStats = stats;
        notifyListeners();

        if (kDebugMode) {
          print('🔄 [UserTrackingDataViewModel] Estatísticas atualizadas');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataViewModel] Erro ao atualizar stats: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎮 HELPER METHODS - TRANSFORMAÇÃO DE DADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Retorna emoji do nível de engajamento
  String? get levelEmoji {
    if (_userStats == null) return null;

    final level =
        UserEngagementLevel.fromString(_userStats!.engagementLevel);
    return level.emoji;
  }

  /// Retorna nome traduzível do nível
  String? get levelDisplayName {
    if (_userStats == null) return null;

    final level =
        UserEngagementLevel.fromString(_userStats!.engagementLevel);
    return level.displayName;
  }

  /// Retorna texto formatado do streak
  /// Exemplo: "5 dias consecutivos 🔥"
  String? get streakText {
    if (_userStats == null) return null;

    final streak = _userStats!.consecutiveDaysStreak;
    final emoji = streak >= 7 ? '🔥' : '📅';

    return '$streak dia${streak > 1 ? 's' : ''} consecutivo${streak > 1 ? 's' : ''} $emoji';
  }

  /// Retorna texto formatado da posição no ranking
  /// Exemplo: "5º lugar 🏅"
  String? get rankPositionText {
    if (_userRankPosition == null) return null;

    String emoji;
    if (_userRankPosition == 1) {
      emoji = '🥇';
    } else if (_userRankPosition == 2) {
      emoji = '🥈';
    } else if (_userRankPosition == 3) {
      emoji = '🥉';
    } else if (_userRankPosition! <= 10) {
      emoji = '🏅';
    } else {
      emoji = '📊';
    }

    return '$_userRankPositionº lugar $emoji';
  }

  /// Calcula progresso até próximo nível
  /// Retorna valor entre 0.0 e 1.0 para barra de progresso
  double? get progressToNextLevel {
    if (_userStats == null) return null;

    final score = _userStats!.totalScore;

    // Thresholds de score para cada nível
    if (score < 100) {
      // LOW → MEDIUM (100 pontos)
      return score / 100.0;
    } else if (score < 500) {
      // MEDIUM → HIGH (500 pontos)
      return (score - 100) / 400.0;
    } else if (score < 1000) {
      // HIGH → VERY_HIGH (1000 pontos)
      return (score - 500) / 500.0;
    } else {
      // VERY_HIGH (máximo)
      return 1.0;
    }
  }

  /// Retorna pontos necessários até próximo nível
  int? get pointsToNextLevel {
    if (_userStats == null) return null;

    final score = _userStats!.totalScore;

    if (score < 100) {
      return 100 - score;
    } else if (score < 500) {
      return 500 - score;
    } else if (score < 1000) {
      return 1000 - score;
    } else {
      return 0; // Já está no máximo
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧹 CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reseta estado (útil para testes ou logout)
  void reset() {
    _state = UserTrackingState.initial;
    _errorMessage = null;
    _userStats = null;
    _topUsers = [];
    _userRankPosition = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Limpar recursos aqui se necessário (timers, streams, etc.)
    super.dispose();
  }
}

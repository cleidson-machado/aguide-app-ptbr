import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_repository_interface.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_validator.dart';

/// Service responsável pela lógica de negócio de rastreamento de usuários
/// 
/// Documentação: .local_knowledge/FLUTTER_USER_TRACKING_MVP_GUIDE.md
/// 
/// 🎯 Responsabilidades:
/// - Gerenciar fluxo de login (criar ou atualizar ranking)
/// - Calcular streaks de dias consecutivos
/// - Adicionar pontos com base em eventos
/// - Detectar bônus (streak de 7 dias, 30 dias, etc.)
/// 
/// ⚠️ Arquitetura Híbrida:
/// - Flutter rastreia eventos de login e envia para backend
/// - Backend calcula automaticamente engagementLevel, scoreUpdatedAt
/// - Flutter calcula streak localmente (timezone-aware)
class UserTrackingDataService {
  final UserTrackingDataRepositoryInterface _repository;

  UserTrackingDataService(this._repository);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 MÉTODO PRINCIPAL: Rastrear Login
  // ═══════════════════════════════════════════════════════════════════════════

  /// ✅ PRINCIPAL: Rastreia evento de login do usuário
  /// 
  /// Fluxo:
  /// 1. Buscar ranking existente (GET /user/{userId})
  /// 2. Se não existe (404) → Criar ranking inicial (POST)
  /// 3. Se existe → Verificar se é novo dia → Atualizar (PUT) + Adicionar pontos
  /// 
  /// Quando usar: Logo após login bem-sucedido (AuthCredentialsLoginViewModel)
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final service = injector<UserTrackingDataService>();
  /// await service.trackLoginEvent(currentUserId);
  /// ```
  /// 
  /// ⚠️ NÃO bloqueia login do usuário - erros são logados mas não propagados
  Future<UserTrackingDataModel?> trackLoginEvent(String userId) async {
    try {
      if (kDebugMode) {
        print('🔐 [UserTrackingDataService] Rastreando login: $userId');
      }

      // 1. Buscar ranking existente
      final existing = await _repository.getUserTrackingByUserId(userId);

      if (existing == null) {
        // Primeiro login - criar ranking inicial
        if (kDebugMode) {
          print('✨ [UserTrackingDataService] Primeiro login - criando ranking');
        }

        return await _createInitialRanking(userId);
      } else {
        // Login recorrente - atualizar timestamps e contadores
        if (kDebugMode) {
          print('🔄 [UserTrackingDataService] Login recorrente - atualizando');
        }

        return await _updateExistingRanking(existing);
      }
    } catch (e) {
      // ⚠️ NÃO propagar erro - não bloquear login do usuário
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao rastrear login: $e');
        print('   → Continue normalmente. Ranking será sincronizado depois.');
      }
      return null;
    }
  }

  /// Cria ranking inicial para novo usuário
  Future<UserTrackingDataModel?> _createInitialRanking(String userId) async {
    // Validações client-side
    UserTrackingValidator.validateUserId(userId);
    
    final now = DateTime.now().toUtc();
    UserTrackingValidator.validateTimestamp(now, 'lastLoginAt');

    final initialTracking = UserTrackingDataModel(
      userId: userId,
      lastLoginAt: now,
      lastActivityAt: now,
      totalActiveDays: 1,
      consecutiveDaysStreak: 1,
      totalScore: 1, // +1 ponto pelo primeiro login
      engagementLevel: 'LOW',
    );

    final created = await _repository.createUserTracking(initialTracking);

    if (created != null && kDebugMode) {
      print('✅ [UserTrackingDataService] Ranking inicial criado!');
      print('   - ID: ${created.id}');
      print('   - Score inicial: ${created.totalScore}');
    }

    return created;
  }

  /// Atualiza ranking existente em login recorrente
  Future<UserTrackingDataModel?> _updateExistingRanking(
      UserTrackingDataModel existing) async {
    // Validações client-side
    UserTrackingValidator.validateUserId(existing.userId);
    
    final now = DateTime.now().toUtc();
    UserTrackingValidator.validateTimestamp(now, 'lastLoginAt');
    
    final lastLogin = existing.lastLoginAt;
    final isSameDay = _isSameDay(now, lastLogin);

    // Verificar se é um novo dia
    if (!isSameDay) {
      if (kDebugMode) {
        print('📅 [UserTrackingDataService] Novo dia detectado!');
      }

      // Calcular novo streak
      final newStreak = _calculateStreak(now, lastLogin, existing.consecutiveDaysStreak);
      
      // Validar streak antes de enviar
      UserTrackingValidator.validateStreak(
        oldStreak: existing.consecutiveDaysStreak,
        newStreak: newStreak,
        isSameDay: false,
      );

      // Incrementar dias ativos
      final newActiveDays = existing.totalActiveDays + 1;

      // Atualizar timestamps e contadores
      final updated = existing.copyWith(
        lastLoginAt: now,
        lastActivityAt: now,
        totalActiveDays: newActiveDays,
        consecutiveDaysStreak: newStreak,
      );

      // Enviar para backend (PUT)
      final result = await _repository.updateUserTracking(existing.id!, updated);

      if (result != null) {
        // ✅ OTIMIZAÇÃO: Calcular pontos totais e enviar em UMA chamada
        // Evita race condition do backend (conforme análise do time backend)
        final totalPointsToAdd = _calculateTotalPointsForDay(newStreak);
        
        if (totalPointsToAdd > 0) {
          // Validar antes de adicionar
          UserTrackingValidator.validateScoreAfterAddition(
            currentScore: result.totalScore,
            pointsToAdd: totalPointsToAdd,
          );
          
          if (kDebugMode) {
            print('➕ [UserTrackingDataService] Adicionando $totalPointsToAdd pontos totais');
          }
          
          final withPoints = await _repository.addPoints(
            existing.userId,
            totalPointsToAdd,
          );
          
          return withPoints ?? result;
        }

        return result;
      }

      return result;
    } else {
      if (kDebugMode) {
        print('⏰ [UserTrackingDataService] Mesmo dia - atualizando timestamps');
      }

      // ✅ SEMPRE atualizar lastLoginAt e lastActivityAt (mesmo que seja o mesmo dia)
      // Motivo: Precisão temporal para análises, sessões múltiplas, segurança
      // Referência: Firebase Analytics, Mixpanel, Amplitude
      final updated = existing.copyWith(
        lastLoginAt: now,      // ✅ Atualiza para horário atual do login
        lastActivityAt: now,   // ✅ Atualiza última atividade
      );
      return await _repository.updateUserTracking(existing.id!, updated);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 MÉTODOS HELPER - LÓGICA DE NEGÓCIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calcula streak de dias consecutivos
  /// 
  /// Regras:
  /// - Diferença de 1 dia → Incrementa streak
  /// - Mesmo dia (0 dias) → Mantém streak
  /// - Diferença > 1 dia → Reseta streak para 1
  /// 
  /// ⚠️ Usa UTC para evitar problemas de timezone
  int _calculateStreak(
      DateTime today, DateTime lastLogin, int currentStreak) {
    final difference = today.difference(lastLogin).inDays;

    if (kDebugMode) {
      print('🔢 [UserTrackingDataService] Calculando streak:');
      print('   - Diferença de dias: $difference');
      print('   - Streak atual: $currentStreak');
    }

    if (difference == 1) {
      // Dia consecutivo → incrementa
      final newStreak = currentStreak + 1;
      if (kDebugMode) {
        print('   ✅ Dia consecutivo! Novo streak: $newStreak');
      }
      return newStreak;
    } else if (difference == 0) {
      // Mesmo dia → mantém
      if (kDebugMode) {
        print('   ⏸️  Mesmo dia - mantém streak: $currentStreak');
      }
      return currentStreak;
    } else {
      // Quebrou streak → reseta para 1
      if (kDebugMode) {
        print('   ❌ Streak quebrado! Resetando para 1');
      }
      return 1;
    }
  }

  /// Verifica se duas datas são do mesmo dia (ignora hora)
  /// ⚠️ Usa UTC para consistência
  bool _isSameDay(DateTime date1, DateTime date2) {
    final utc1 = date1.toUtc();
    final utc2 = date2.toUtc();

    return utc1.year == utc2.year &&
        utc1.month == utc2.month &&
        utc1.day == utc2.day;
  }

  /// Calcula pontos totais a adicionar para o dia (login + bônus streak)
  /// 
  /// ✅ OTIMIZAÇÃO: Retorna soma total para enviar em UMA única chamada
  /// Evita race condition no backend ao fazer múltiplos add-points
  /// 
  /// Pontos:
  /// - Login diário: +1 ponto
  /// - Bônus 7 dias consecutivos: +5 pontos
  /// - Bônus 30 dias consecutivos: +20 pontos
  /// - Bônus 60 dias consecutivos: +50 pontos
  /// 
  /// Exemplo: Se streak == 7, retorna 6 (1 login + 5 bônus)
  int _calculateTotalPointsForDay(int streak) {
    int totalPoints = 1; // Login diário sempre adiciona 1
    
    // Adicionar bônus de streaks especiais
    if (streak == 7) {
      if (kDebugMode) {
        print('🎉 [UserTrackingDataService] BÔNUS: 7 dias consecutivos! +5 pontos');
      }
      totalPoints += 5;
    } else if (streak == 30) {
      if (kDebugMode) {
        print('🏆 [UserTrackingDataService] BÔNUS: 30 dias consecutivos! +20 pontos');
      }
      totalPoints += 20;
    } else if (streak == 60) {
      if (kDebugMode) {
        print('💎 [UserTrackingDataService] BÔNUS: 60 dias consecutivos! +50 pontos');
      }
      totalPoints += 50;
    }
    
    return totalPoints;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎮 MÉTODOS PÚBLICOS ADICIONAIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adiciona pontos manualmente (eventos customizados)
  /// 
  /// Quando usar:
  /// - Completar tutorial: +10 pontos
  /// - Assistir vídeo até o fim: +5 pontos
  /// - Compartilhar conteúdo: +3 pontos
  /// 
  /// Exemplo:
  /// ```dart
  /// await service.addCustomPoints(userId, 5, 'Video Completed');
  /// ```
  Future<UserTrackingDataModel?> addCustomPoints(
      String userId, int points, String reason) async {
    // Validações client-side
    UserTrackingValidator.validateUserId(userId);
    UserTrackingValidator.validatePointsToAdd(points);
    
    if (kDebugMode) {
      print('✨ [UserTrackingDataService] Adicionando pontos customizados:');
      print('   - Razão: $reason');
      print('   - Pontos: +$points');
    }

    return await _repository.addPoints(userId, points);
  }

  /// Busca estatísticas do usuário
  /// 
  /// Quando usar: Exibir estatísticas em tela de perfil
  Future<UserTrackingDataModel?> getUserStats(String userId) async {
    return await _repository.getUserTrackingByUserId(userId);
  }

  /// Busca top N usuários (leaderboard)
  /// 
  /// Quando usar: Exibir ranking global na UI
  Future<List<UserTrackingDataModel>> getTopUsers({int limit = 10}) async {
    return await _repository.getTopUsersByScore(limit: limit);
  }

  /// Calcula posição do usuário no ranking global
  /// 
  /// Retorna posição (1-based) ou null se não encontrado
  /// 
  /// Exemplo: Se usuário está em 5º lugar, retorna 5
  Future<int?> getUserRankPosition(String userId) async {
    try {
      // Buscar todos os rankings ordenados por score
      final allRankings = await _repository.getAllUserTrackings();

      // Ordenar por score (maior primeiro)
      allRankings.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      // Encontrar posição do usuário
      for (int i = 0; i < allRankings.length; i++) {
        if (allRankings[i].userId == userId) {
          return i + 1; // Posição 1-based
        }
      }

      return null; // Usuário não encontrado
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao calcular posição: $e');
      }
      return null;
    }
  }

  /// Verifica se usuário atingiu novo nível de engajamento
  /// 
  /// Útil para exibir notificação/animação quando subir de nível
  /// 
  /// Retorna true se level mudou
  Future<bool> checkLevelUp(String userId, String previousLevel) async {
    final current = await _repository.getUserTrackingByUserId(userId);

    if (current != null) {
      final levelChanged = current.engagementLevel != previousLevel;

      if (levelChanged && kDebugMode) {
        print('🆙 [UserTrackingDataService] LEVEL UP!');
        print('   - De: $previousLevel');
        print('   - Para: ${current.engagementLevel}');
      }

      return levelChanged;
    }

    return false;
  }
}

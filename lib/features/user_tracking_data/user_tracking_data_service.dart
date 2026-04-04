import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_model.dart';
import 'package:portugal_guide/features/user_tracking_data/points_history_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_repository_interface.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_validator.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_repository.dart';
import 'package:portugal_guide/features/user_tracking_data/enums/points_reason_enum.dart';
import 'package:portugal_guide/features/user_tracking_data/enums/favorite_content_type_enum.dart';

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

  // ═══════════════════════════════════════════════════════════════════════════
  // 📜 HISTÓRICO DE PONTOS (AUDITORIA)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Busca histórico de adição de pontos do usuário (auditoria)
  /// 
  /// Endpoint: GET /user/{userId}/points-history?limit={limit}
  /// 
  /// **Segurança:**
  /// - userId DEVE ser do usuário logado (backend valida JWT)
  /// - Se tentar acessar dados de outro usuário, backend retorna 403
  /// 
  /// **Uso:**
  /// Tela "Meu Histórico de Pontos" para mostrar timeline de conquistas
  /// 
  /// **Exemplo:**
  /// ```dart
  /// final history = await service.getPointsHistory(currentUserId, limit: 20);
  /// for (final entry in history) {
  ///   print('${entry.date}: +${entry.points} - ${entry.getReasonDescription()}');
  /// }
  /// ```
  /// 
  /// **Parâmetros:**
  /// - [userId]: ID do usuário (UUID) - DEVE ser do logado
  /// - [limit]: Quantidade de registros (default: 10, max: 100)
  /// 
  /// **Retorno:**
  /// - Lista de [PointsHistoryModel] ordenados por data (mais recente primeiro)
  /// - Lista vazia se sem histórico ou erro
  Future<List<PointsHistoryModel>> getPointsHistory(
    String userId, {
    int? limit,
  }) async {
    try {
      // Validações client-side
      UserTrackingValidator.validateUserId(userId);
      
      if (limit != null && (limit < 1 || limit > 100)) {
        if (kDebugMode) {
          print('⚠️  [UserTrackingDataService] Limit fora do intervalo [1, 100]: $limit');
          print('   → Ajustando para padrão 10');
        }
        limit = 10;
      }

      if (kDebugMode) {
        print('📜 [UserTrackingDataService] Buscando histórico de pontos');
        print('   - userId: $userId');
        print('   - limit: ${limit ?? 10}');
      }

      // Downcast seguro para implementação concreta
      final repository = _repository as UserTrackingDataRepository;
      final history = await repository.getPointsHistory(userId, limit: limit);

      if (kDebugMode) {
        print('✅ [UserTrackingDataService] ${history.length} registros encontrados');
      }

      return history;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao buscar histórico: $e');
      }
      return [];
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 PHASE B: MÉTODOS DE TELEMETRIA ENRIQUECIDA
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🆕 PHASE B: Rastreia visualização de conteúdo
  /// 
  /// Fluxo:
  /// 1. Incrementa totalContentViews
  /// 2. Adiciona contentId ao set de únicos (uniqueContentViews)
  /// 3. Atualiza lastContentViewAt
  /// 4. Atualiza favoriteCategory se categoria fornecida
  /// 5. Backend detecta milestones (10/50/100 views) automaticamente
  /// 
  /// **Quando usar:**
  /// - Usuário clica em conteúdo na MainContentTopicScreen
  /// - Ao abrir detalhes de um conteúdo
  /// 
  /// **Exemplo:**
  /// ```dart
  /// await service.trackContentView(
  ///   userId: currentUserId,
  ///   contentId: 'uuid-123',
  ///   category: 'Tecnologia',
  ///   contentType: FavoriteContentType.video,
  /// );
  /// ```
  /// 
  /// **Parâmetros:**
  /// - [userId]: ID do usuário logado
  /// - [contentId]: ID do conteúdo visualizado (para contagem de únicos)
  /// - [category]: Categoria do conteúdo (opcional, para favorito)
  /// - [contentType]: Tipo do conteúdo (opcional, para favorito)
  /// 
  /// **Pontos automáticos (backend):**
  /// - +1 ponto por view (backend sempre adiciona)
  /// - +2 pontos ao atingir 10 views (milestone automático)
  /// - +5 pontos ao atingir 50 views (milestone automático)
  /// - +10 pontos ao atingir 100 views (milestone automático)
  /// 
  /// ⚠️ NÃO bloqueia navegação - erros são logados mas não propagados
  Future<UserTrackingDataModel?> trackContentView({
    required String userId,
    required String contentId,
    String? category,
    FavoriteContentType? contentType,
  }) async {
    try {
      // Validações client-side
      UserTrackingValidator.validateUserId(userId);
      if (category != null) {
        UserTrackingValidator.validateFavoriteCategory(category);
      }

      if (kDebugMode) {
        print('📺 [UserTrackingDataService] Rastreando content view');
        print('   - contentId: $contentId');
        print('   - category: ${category ?? "N/A"}');
        print('   - type: ${contentType?.name ?? "N/A"}');
      }

      // Buscar ranking atual
      final existing = await _repository.getUserTrackingByUserId(userId);
      if (existing == null) {
        if (kDebugMode) {
          print('⚠️  [UserTrackingDataService] Ranking não encontrado, pulando tracking');
        }
        return null;
      }

      // Incrementar totalContentViews
      final newTotalViews = (existing.totalContentViews ?? 0) + 1;
      
      // Incrementar uniqueContentViews se for novo conteúdo
      // ⚠️ Implementação simplificada: backend deve validar uniqueness
      // Em produção, usar Set<String> para rastrear IDs localmente
      final newUniqueViews = (existing.uniqueContentViews ?? 0) + 1;

      // Validações antes de atualizar
      UserTrackingValidator.validateContentViews(newTotalViews);
      UserTrackingValidator.validateUniqueContentViews(
        uniqueContentViews: newUniqueViews,
        totalContentViews: newTotalViews,
      );

      final now = DateTime.now().toUtc();
      UserTrackingValidator.validateTimestamp(now, 'lastContentViewAt');

      // Atualizar modelo com novos campos
      final updated = existing.copyWith(
        totalContentViews: newTotalViews,
        uniqueContentViews: newUniqueViews,
        lastContentViewAt: now,
        lastActivityAt: now,
        // Atualizar favoritos se fornecidos
        favoriteCategory: category ?? existing.favoriteCategory,
        favoriteContentType: contentType ?? existing.favoriteContentType,
      );

      // Enviar para backend (PUT)
      final result = await _repository.updateUserTracking(existing.id!, updated);

      if (result != null && kDebugMode) {
        print('✅ [UserTrackingDataService] Content view rastreado!');
        print('   - Total views: ${result.totalContentViews}');
        print('   - Unique views: ${result.uniqueContentViews}');
        print('   - Backend adicionará +1 ponto automaticamente');
        
        // Avisar sobre milestones próximos
        final totalViews = result.totalContentViews ?? 0;
        if (totalViews == 9) {
          print('   🎯 Próximo milestone: 10 views (+2 pontos bônus!)');
        } else if (totalViews == 49) {
          print('   🎯 Próximo milestone: 50 views (+5 pontos bônus!)');
        } else if (totalViews == 99) {
          print('   🎯 Próximo milestone: 100 views (+10 pontos bônus!)');
        }
      }

      return result;
    } catch (e) {
      // ⚠️ NÃO propagar erro - não bloquear navegação do usuário
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao rastrear content view: $e');
      }
      return null;
    }
  }

  /// 🆕 PHASE B: Atualiza percentual de conclusão do perfil
  /// 
  /// Fluxo:
  /// 1. Valida percentual (0-100)
  /// 2. Atualiza profileCompletionPercentage
  /// 3. Backend detecta milestone de 50% e 100% automaticamente
  /// 
  /// **Quando usar:**
  /// - Durante wizard de perfil (a cada step concluído)
  /// - Ao editar informações do perfil
  /// 
  /// **Exemplo:**
  /// ```dart
  /// await service.trackProfileCompletion(
  ///   userId: currentUserId,
  ///   percentage: 50,
  /// );
  /// ```
  /// 
  /// **Pontos automáticos (backend):**
  /// - +3 pontos ao atingir 50% (milestone automático)
  /// - +10 pontos ao atingir 100% (milestone automático)
  /// 
  /// ⚠️ NÃO bloqueia fluxo do wizard - erros são logados mas não propagados
  Future<UserTrackingDataModel?> trackProfileCompletion({
    required String userId,
    required int percentage,
  }) async {
    try {
      // Validações client-side
      UserTrackingValidator.validateUserId(userId);
      UserTrackingValidator.validateProfileCompletionPercentage(percentage);

      if (kDebugMode) {
        print('📝 [UserTrackingDataService] Atualizando profile completion');
        print('   - Percentual: $percentage%');
      }

      // Buscar ranking atual
      final existing = await _repository.getUserTrackingByUserId(userId);
      if (existing == null) {
        if (kDebugMode) {
          print('⚠️  [UserTrackingDataService] Ranking não encontrado, pulando tracking');
        }
        return null;
      }

      // Atualizar modelo
      final now = DateTime.now().toUtc();
      final updated = existing.copyWith(
        profileCompletionPercentage: percentage,
        lastActivityAt: now,
      );

      // Enviar para backend (PUT)
      final result = await _repository.updateUserTracking(existing.id!, updated);

      if (result != null && kDebugMode) {
        print('✅ [UserTrackingDataService] Profile completion atualizado!');
        print('   - Percentual: ${result.profileCompletionPercentage}%');
        
        // Avisar sobre milestones
        if (percentage == 50) {
          print('   🎉 Milestone atingido: 50% (+3 pontos bônus!)');
        } else if (percentage == 100) {
          print('   🏆 Milestone atingido: 100% (+10 pontos bônus!)');
        }
      }

      return result;
    } catch (e) {
      // ⚠️ NÃO propagar erro - não bloquear wizard do usuário
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao atualizar profile completion: $e');
      }
      return null;
    }
  }

  /// 🆕 PHASE B: Atualiza média de minutos de uso diário
  /// 
  /// Fluxo:
  /// 1. Valida minutos (0-1440)
  /// 2. Calcula média ponderada com valor anterior
  /// 3. Atualiza avgDailyUsageMinutes
  /// 
  /// **Quando usar:**
  /// - Ao fechar app (em AppLifecycleState.paused/detached)
  /// - A cada 5 minutos de uso contínuo (debounce)
  /// 
  /// **Exemplo:**
  /// ```dart
  /// await service.updateSessionDuration(
  ///   userId: currentUserId,
  ///   sessionMinutes: 15,
  /// );
  /// ```
  /// 
  /// **Cálculo de média ponderada:**
  /// ```
  /// newAvg = (oldAvg * 0.8) + (sessionMinutes * 0.2)
  /// ```
  /// Peso maior no histórico (80%), menor na sessão atual (20%)
  /// 
  /// ⚠️ NÃO bloqueia fechamento do app - erros são logados mas não propagados
  Future<UserTrackingDataModel?> updateSessionDuration({
    required String userId,
    required int sessionMinutes,
  }) async {
    try {
      // Validações client-side
      UserTrackingValidator.validateUserId(userId);
      UserTrackingValidator.validateDailyUsageMinutes(sessionMinutes);

      if (kDebugMode) {
        print('⏱️  [UserTrackingDataService] Atualizando session duration');
        print('   - Sessão (min): $sessionMinutes');
      }

      // Buscar ranking atual
      final existing = await _repository.getUserTrackingByUserId(userId);
      if (existing == null) {
        if (kDebugMode) {
          print('⚠️  [UserTrackingDataService] Ranking não encontrado, pulando tracking');
        }
        return null;
      }

      // Calcular média ponderada
      final oldAvg = existing.avgDailyUsageMinutes ?? 0;
      final newAvg = ((oldAvg * 0.8) + (sessionMinutes * 0.2)).round();

      // Validar resultado
      UserTrackingValidator.validateDailyUsageMinutes(newAvg);

      if (kDebugMode) {
        print('   - Média antiga: $oldAvg min');
        print('   - Média nova: $newAvg min');
      }

      // Atualizar modelo
      final now = DateTime.now().toUtc();
      final updated = existing.copyWith(
        avgDailyUsageMinutes: newAvg,
        lastActivityAt: now,
      );

      // Enviar para backend (PUT)
      final result = await _repository.updateUserTracking(existing.id!, updated);

      if (result != null && kDebugMode) {
        print('✅ [UserTrackingDataService] Session duration atualizado!');
        print('   - Média diária: ${result.avgDailyUsageMinutes} min');
      }

      return result;
    } catch (e) {
      // ⚠️ NÃO propagar erro - não bloquear fechamento do app
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao atualizar session duration: $e');
      }
      return null;
    }
  }

  /// 🆕 PHASE B: Adiciona pontos com razão específica (auditability)
  /// 
  /// Fluxo:
  /// 1. Valida pontos (1-1000)
  /// 2. Converte PointsReason para snake_case (wizardEntry → "wizard_entry")
  /// 3. Envia para backend com reason parameter
  /// 4. Backend registra em points_history com reason para auditoria
  /// 
  /// **Quando usar:**
  /// - Wizard steps: PointsReason.wizardStep1 (+2 pontos)
  /// - Primeiro conteúdo criado: PointsReason.wizardEntry (+2 pontos)
  /// - Primeira mensagem enviada: PointsReason.firstMessageSent (+1 ponto)
  /// - Primeira conversa iniciada: PointsReason.firstConversation (+2 pontos)
  /// 
  /// **Exemplo:**
  /// ```dart
  /// await service.addPointsWithReason(
  ///   userId: currentUserId,
  ///   points: 2,
  ///   reason: PointsReason.wizardEntry,
  /// );
  /// ```
  /// 
  /// **Diferenças com addCustomPoints:**
  /// - addCustomPoints: String livre, sem enum (legado)
  /// - addPointsWithReason: Enum validado, auditável, snake_case automático
  /// 
  /// **Backend:**
  /// - Aceita query param `reason` opcional
  /// - Armazena em points_history.reason (type: varchar(50))
  /// - Validação: valores conhecidos ou null
  /// 
  /// ⚠️ NÃO bloqueia ação do usuário - erros são logados mas não propagados
  Future<UserTrackingDataModel?> addPointsWithReason({
    required String userId,
    required int points,
    required PointsReason reason,
  }) async {
    try {
      // Validações client-side
      UserTrackingValidator.validateUserId(userId);
      UserTrackingValidator.validatePointsToAdd(points);

      // Converter enum para snake_case
      final reasonString = reason.toJson();

      if (kDebugMode) {
        print('✨ [UserTrackingDataService] Adicionando pontos com reason');
        print('   - Pontos: +$points');
        print('   - Reason (enum): ${reason.name}');
        print('   - Reason (snake_case): $reasonString');
      }

      // Downcast seguro para implementação concreta
      final repository = _repository as UserTrackingDataRepository;
      
      // Chamar método com reason parameter
      final result = await repository.addPoints(userId, points, reason: reasonString);

      if (result != null && kDebugMode) {
        print('✅ [UserTrackingDataService] Pontos adicionados com sucesso!');
        print('   - Score total: ${result.totalScore}');
        print('   - Reason registrado em points_history para auditoria');
      }

      return result;
    } catch (e) {
      // ⚠️ NÃO propagar erro - não bloquear ação do usuário
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao adicionar pontos: $e');
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 PHASE B: PROFILE COMPLETION TRACKING (Helper Method)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🆕 PHASE B: Calcula profile completion percentage e rastreia automaticamente
  /// 
  /// **Cálculo de Porcentagem:**
  /// - Campos obrigatórios (3): name, surname, email
  /// - Campos opcionais (3): phone, youtubeUserId, youtubeChannelId
  /// - Total: 6 campos (100% = todos preenchidos)
  /// 
  /// **Pesos:**
  /// - Obrigatórios: 50% (se todos 3 preenchidos = 50%)
  /// - Opcionais: 50% dividido igualmente (16.67% cada)
  ///   - phone: +16.67%
  ///   - youtubeUserId: +16.67%
  ///   - youtubeChannelId: +16.67%
  /// 
  /// **Milestones (detectados automaticamente pelo backend):**
  /// - 50%: +3 pontos (PointsReason.profileCompletion50)
  /// - 100%: +10 pontos (PointsReason.profileCompletion100)
  /// 
  /// **Quando usar:**
  /// - Após `updateUser()` em qualquer tela de edição de perfil
  /// - Após `updateUserDetails()` em profile settings
  /// - Após adicionar telefone ou YouTube IDs
  /// 
  /// **Exemplo de uso:**
  /// ```dart
  /// final service = injector<UserTrackingDataService>();
  /// final userDetails = injector<UserDetailsViewModel>().userDetails;
  /// 
  /// await service.calculateAndTrackProfileCompletion(
  ///   userId: currentUserId,
  ///   userDetails: userDetails,
  /// );
  /// ```
  /// 
  /// ⚠️ NÃO bloqueia ação do usuário - erros são logados mas não propagados
  Future<void> calculateAndTrackProfileCompletion({
    required String userId,
    required dynamic userDetails, // UserDetailsModel
  }) async {
    try {
      if (kDebugMode) {
        print('');
        print('╔════════════════════════════════════════════════════════════════════╗');
        print('║  📊 CALCULANDO PROFILE COMPLETION PERCENTAGE                       ║');
        print('╚════════════════════════════════════════════════════════════════════╝');
      }

      // Campos obrigatórios (peso: 50%)
      final hasName = userDetails.name != null && userDetails.name.toString().trim().isNotEmpty;
      final hasSurname = userDetails.surname != null && userDetails.surname.toString().trim().isNotEmpty;
      final hasEmail = userDetails.email != null && userDetails.email.toString().trim().isNotEmpty;

      // Campos opcionais (peso: 50% / 3 = 16.67% cada)
      final hasPhone = userDetails.phones != null && (userDetails.phones as List).isNotEmpty;
      final hasYoutubeUserId = userDetails.youtubeUserId != null && 
                                userDetails.youtubeUserId.toString().trim().isNotEmpty;
      final hasYoutubeChannelId = userDetails.youtubeChannelId != null && 
                                   userDetails.youtubeChannelId.toString().trim().isNotEmpty;

      // Cálculo de porcentagem
      double percentage = 0.0;

      // Obrigatórios: 50% total (se todos 3 = 50%)
      final requiredFieldsCount = (hasName ? 1 : 0) + (hasSurname ? 1 : 0) + (hasEmail ? 1 : 0);
      percentage += (requiredFieldsCount / 3.0) * 50.0;

      // Opcionais: 50% total (16.67% cada)
      if (hasPhone) percentage += 16.67;
      if (hasYoutubeUserId) percentage += 16.67;
      if (hasYoutubeChannelId) percentage += 16.67;

      // Arredondar para inteiro
      final completionPercentage = percentage.round();

      if (kDebugMode) {
        print('   🎯 Campos Obrigatórios (50%):');
        print('      - name: ${hasName ? "✅" : "❌"}');
        print('      - surname: ${hasSurname ? "✅" : "❌"}');
        print('      - email: ${hasEmail ? "✅" : "❌"}');
        print('      - Subtotal: ${((requiredFieldsCount / 3.0) * 50.0).toStringAsFixed(1)}%');
        print('');
        print('   🎯 Campos Opcionais (50%):');
        print('      - phone: ${hasPhone ? "✅ +16.67%" : "❌"}');
        print('      - youtubeUserId: ${hasYoutubeUserId ? "✅ +16.67%" : "❌"}');
        print('      - youtubeChannelId: ${hasYoutubeChannelId ? "✅ +16.67%" : "❌"}');
        print('');
        print('   📊 COMPLETION TOTAL: $completionPercentage%');
        print('───────────────────────────────────────────────────────────────────');
      }

      // Chamar trackProfileCompletion
      await trackProfileCompletion(
        userId: userId,
        percentage: completionPercentage,
      );

      if (kDebugMode) {
        print('✅ [UserTrackingDataService] Profile completion rastreado!');
        print('   - Backend detectará milestones automaticamente');
        print('   - 50%: +3 pontos | 100%: +10 pontos');
        print('╚════════════════════════════════════════════════════════════════════╝');
        print('');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserTrackingDataService] Erro ao calcular profile completion: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
}

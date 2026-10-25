import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user_message_flow/models/message_user_data.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';
import 'connection_profile_model.dart';
import 'featured_content_models.dart';
import 'featured_theme_data.dart';
import 'featured_themes_composer.dart';
import 'relation_suggestion_data.dart';
import 'user_ranking_summary_model.dart';
import 'user_relation_featured_content_repository_interface.dart';
import 'user_relation_ranking_repository_interface.dart';

/// ViewModel para gerenciar dados da tela UserRelationNetworkScreen
class UserRelationNetworkViewModel extends ChangeNotifier {
  /// Quantidade máxima de sugestões exibidas (+1 no fetch para compensar o
  /// próprio usuário, que é removido da lista).
  static const int _maxSuggestions = 20;

  /// 4 linhas de 3 círculos na grid "Temas em Destaque".
  static const int _maxFeaturedThemes = 12;
  // NOTE: lote maior que os 30 do prompt: 30 itens recentes cobriam só 4 das 7
  // categorias. Rever quando existir endpoint dedicado de temas no backend.
  static const int _featuredCatalogSize = 100;

  final UserRepositoryInterface _userRepository;
  final OwnershipRepositoryInterface _ownershipRepository;
  final UserRelationRankingRepositoryInterface _rankingRepository;
  final UserRelationFeaturedContentRepositoryInterface _featuredContentRepository;
  static const FeaturedThemesComposer _featuredThemesComposer = FeaturedThemesComposer();
  final String? Function() _currentUserIdProvider;

  UserRelationNetworkViewModel({
    UserRepositoryInterface? userRepository,
    OwnershipRepositoryInterface? ownershipRepository,
    UserRelationRankingRepositoryInterface? rankingRepository,
    UserRelationFeaturedContentRepositoryInterface? featuredContentRepository,
    String? Function()? currentUserIdProvider,
  })  : _userRepository = userRepository ?? injector<UserRepositoryInterface>(),
        _ownershipRepository = ownershipRepository ?? injector<OwnershipRepositoryInterface>(),
        _rankingRepository =
            rankingRepository ?? injector<UserRelationRankingRepositoryInterface>(),
        _featuredContentRepository = featuredContentRepository ??
            injector<UserRelationFeaturedContentRepositoryInterface>(),
        _currentUserIdProvider =
            currentUserIdProvider ?? (() => injector<AuthTokenManager>().getUserId());

  bool _isDisposed = false;

  // Query de busca
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ===== Estado de User Details (para diferenciação CRIADOR/CONSUMIDOR) =====
  UserDetailsModel? _userDetails;
  bool _isLoadingUserDetails = false;

  // ===== Estado de Conexões Reais (via API) =====
  List<MessageUserData> _connections = [];
  bool _isLoadingConnections = false;
  String? _connectionsError;

  // ===== Estado de Ownership (Conteúdos Verificados) =====
  List<OwnershipContentModel> _ownershipContents = [];
  bool _isLoadingOwnership = false;
  String? _ownershipError;

  // ===== Estado de Sugestões (ranking via /user-rankings/top) =====
  List<RelationSuggestionData> _suggestions = [];
  bool _isLoadingSuggestions = false;
  String? _suggestionsError;

  // ===== Estado de Temas em Destaque (catálogo + top-contents do usuário) =====
  List<FeaturedThemeData> _featuredThemes = [];
  bool _isLoadingFeaturedThemes = false;
  String? _featuredThemesError;

  // ===== Getters para User Details =====
  UserDetailsModel? get userDetails => _userDetails;
  bool get isLoadingUserDetails => _isLoadingUserDetails;

  // ===== Getters para Conexões =====
  /// Retorna apenas os primeiros 20 usuários
  List<MessageUserData> get connections => _connections.take(20).toList();
  bool get isLoadingConnections => _isLoadingConnections;
  String? get connectionsError => _connectionsError;
  bool get hasMoreConnections => _connections.length > 20;

  // ===== Getters para Ownership =====
  List<OwnershipContentModel> get ownershipContents => _ownershipContents;
  bool get isLoadingOwnership => _isLoadingOwnership;
  String? get ownershipError => _ownershipError;

  // ===== Getters para Sugestões =====
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get suggestionsError => _suggestionsError;

  /// Sugestões já filtradas pela busca, na ordem do leaderboard
  List<RelationSuggestionData> get filteredSuggestions {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _suggestions;
    return _suggestions
        .where((suggestion) => suggestion.fullName.toLowerCase().contains(query))
        .toList();
  }

  // ===== Getters para Temas em Destaque =====
  bool get isLoadingFeaturedThemes => _isLoadingFeaturedThemes;
  String? get featuredThemesError => _featuredThemesError;

  /// Temas já filtrados pela busca (por rótulo)
  List<FeaturedThemeData> get filteredFeaturedThemes {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _featuredThemes;
    return _featuredThemes
        .where((theme) => theme.label.toLowerCase().contains(query))
        .toList();
  }

  /// Determina se o usuário é CRIADOR (Produtor de Conteúdo)
  /// 
  /// Lógica: Se ambos youtubeUserId E youtubeChannelId são não-nulos → CRIADOR
  /// Qualquer outra combinação → CONSUMIDOR
  bool get isContentCreator {
    if (_userDetails == null) {
      if (kDebugMode) {
        debugPrint('🔍 [UserRelationNetworkVM] _userDetails é NULL → retornando FALSE (CONSUMIDOR)');
      }
      return false;
    }

    final hasYoutubeUserId = _userDetails!.youtubeUserId != null &&
        _userDetails!.youtubeUserId!.isNotEmpty;
    final hasYoutubeChannelId = _userDetails!.youtubeChannelId != null &&
        _userDetails!.youtubeChannelId!.isNotEmpty;

    final isCriador = hasYoutubeUserId && hasYoutubeChannelId;

    if (kDebugMode) {
      debugPrint('🔍 [UserRelationNetworkVM] Verificação:');
      debugPrint('   youtubeUserId: ${_userDetails!.youtubeUserId ?? "NULL"} → hasYoutubeUserId: $hasYoutubeUserId');
      debugPrint('   youtubeChannelId: ${_userDetails!.youtubeChannelId ?? "NULL"} → hasYoutubeChannelId: $hasYoutubeChannelId');
      debugPrint('   Resultado: ${isCriador ? "CRIADOR" : "CONSUMIDOR"}');
    }

    return isCriador;
  }

  /// Retorna o título dinâmico da primeira seção
  /// - CRIADOR: "Meus Vídeos - CRIADOS"
  /// - CONSUMIDOR: "Conteúdo Visualizado"
  /// ### PAREI AQUI...
  String get dynamicTitlesByOwner {
    final title = isContentCreator
        ? 'Meus Vídeos - CRIADOS'
        : 'Conteúdo Visualizado';

    if (kDebugMode) {
      debugPrint('🏷️  [UserRelationNetworkVM] dynamicTitlesByOwner: "$title"');
    }

    return title;
  }

  // ========== DADOS MOCKADOS ==========

  /// Meus Vídeos (horizontal scroll) - 12 itens
  List<ConnectionProfileModel> get featuredProfiles => [
        const ConnectionProfileModel(
          id: '1',
          name: 'Canal Tech',
          avatarUrl: 'https://i.pravatar.cc/150?img=1',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '2',
          name: 'Vlog Viagens',
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '3',
          name: 'Receitas Fit',
          avatarUrl: 'https://i.pravatar.cc/150?img=5',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '100',
          name: 'Gaming Pro',
          avatarUrl: 'https://i.pravatar.cc/150?img=70',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '101',
          name: 'DIY Criativo',
          avatarUrl: 'https://i.pravatar.cc/150?img=8',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '102',
          name: 'Fitness Zone',
          avatarUrl: 'https://i.pravatar.cc/150?img=18',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '103',
          name: 'Música Live',
          avatarUrl: 'https://i.pravatar.cc/150?img=28',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '104',
          name: 'Arte Digital',
          avatarUrl: 'https://i.pravatar.cc/150?img=38',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '105',
          name: 'Idiomas',
          avatarUrl: 'https://i.pravatar.cc/150?img=48',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '106',
          name: 'Ciência Cool',
          avatarUrl: 'https://i.pravatar.cc/150?img=58',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '107',
          name: 'História',
          avatarUrl: 'https://i.pravatar.cc/150?img=63',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '108',
          name: 'Pets Fun',
          avatarUrl: 'https://i.pravatar.cc/150?img=69',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
      ];

  /// Minhas Conexões (conectados)
  List<ConnectionProfileModel> get myConnections => [
        const ConnectionProfileModel(
          id: '4',
          name: 'Suzanie Jobs',
          avatarUrl: 'https://i.pravatar.cc/150?img=47',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '5',
          name: 'João Silva',
          avatarUrl: 'https://i.pravatar.cc/150?img=13',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '6',
          name: 'Suzane Alves',
          avatarUrl: 'https://i.pravatar.cc/150?img=9',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '10',
          name: 'Maria Santos',
          avatarUrl: 'https://i.pravatar.cc/150?img=20',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '11',
          name: 'Pedro Costa',
          avatarUrl: 'https://i.pravatar.cc/150?img=15',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '12',
          name: 'Ana Lima',
          avatarUrl: 'https://i.pravatar.cc/150?img=25',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '13',
          name: 'Carlos Mendes',
          avatarUrl: 'https://i.pravatar.cc/150?img=30',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '14',
          name: 'Julia Rocha',
          avatarUrl: 'https://i.pravatar.cc/150?img=40',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '15',
          name: 'Lucas Ferreira',
          avatarUrl: 'https://i.pravatar.cc/150?img=52',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '16',
          name: 'Beatriz Souza',
          avatarUrl: 'https://i.pravatar.cc/150?img=35',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '17',
          name: 'Rafael Dias',
          avatarUrl: 'https://i.pravatar.cc/150?img=60',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '18',
          name: 'Camila Martins',
          avatarUrl: 'https://i.pravatar.cc/150?img=45',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
      ];

  /// Atualiza a query de busca
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Carrega conteúdos verificados (ownership) do usuário
  /// 
  /// Usa endpoint: GET /api/v1/ownership/user/{userId}/content
  /// Exibe "Meus Vídeos - CRIADOS" para CRIADORES
  Future<void> loadOwnershipContents(String userId) async {
    _isLoadingOwnership = true;
    _ownershipError = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════╗');
        debugPrint('║  🎬 CARREGANDO OWNERSHIP - UserRelationNetworkViewModel        ║');
        debugPrint('╚════════════════════════════════════════════════════════════════╝');
        debugPrint('   🆔 UserId: $userId');
      }

      final result = await _ownershipRepository.getUserVerifiedContents(
        userId: userId,
      );

      if (result.isOwner && result.contents != null) {
        _ownershipContents = result.contents!;
        if (kDebugMode) {
          debugPrint('   ✅ ${_ownershipContents.length} conteúdo(s) verificado(s) carregado(s)');
          for (final content in _ownershipContents) {
            debugPrint('      - ${content.channelName} (${content.title})');
          }
        }
      } else {
        _ownershipContents = [];
        if (kDebugMode) {
          debugPrint('   ⚠️  Nenhum conteúdo verificado (não é dono ou erro)');
        }
      }

      if (kDebugMode) {
        debugPrint('─────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } catch (e) {
      _ownershipContents = [];
      _ownershipError = 'Erro ao carregar conteúdos verificados';
      if (kDebugMode) {
        debugPrint('   ❌ Erro ao carregar ownership: $e');
      }
    } finally {
      _isLoadingOwnership = false;
      notifyListeners();
    }
  }

  /// Carrega a seção "Sugestões" a partir do leaderboard real
  ///
  /// 1. GET /api/v1/user-rankings/top?limit=N (ordenado por totalScore DESC)
  /// 2. GET /api/v1/users/{userId}/details para nome de exibição (em paralelo)
  ///
  /// A posição é derivada do índice no leaderboard (a API não envia
  /// `rankPosition`). O próprio usuário é removido e itens sem detalhes
  /// disponíveis são descartados, pois o ranking não traz nome.
  Future<void> loadSuggestions() async {
    if (_isLoadingSuggestions) return;

    _isLoadingSuggestions = true;
    _suggestionsError = null;
    notifyListeners();

    try {
      final List<UserRankingSummaryModel> rankings =
          await _rankingRepository.getTopRankings(limit: _maxSuggestions + 1);
      final String? currentUserId = _currentUserIdProvider();

      final List<RelationSuggestionData?> enriched = await Future.wait(
        [
          for (int index = 0; index < rankings.length; index++)
            if (rankings[index].userId != currentUserId)
              _buildSuggestion(rankings[index], rankPosition: index + 1),
        ],
      );

      _suggestions = enriched
          .whereType<RelationSuggestionData>()
          .take(_maxSuggestions)
          .toList();

      if (kDebugMode) {
        debugPrint(
            '✅ [UserRelationNetworkVM] ${_suggestions.length} sugestão(ões) carregada(s) do ranking');
      }
    } catch (e) {
      _suggestions = [];
      _suggestionsError = 'Erro ao carregar sugestões';
      if (kDebugMode) {
        debugPrint('❌ [UserRelationNetworkVM] Erro ao carregar sugestões: $e');
      }
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  /// Carrega a seção "Temas em Destaque".
  ///
  /// Não há endpoint de temas/trending global no backend; a grid é composta:
  /// 1. GET /contents (0-based, mais recentes) — obrigatório; falha = erro na UI
  /// 2. GET /engagements/user/{id}/top-contents — opcional; falha = só catálogo
  /// 3. GET /contents/{id} para top-contents fora do lote do catálogo
  ///    (top-contents não traz categoria)
  Future<void> loadFeaturedThemes() async {
    if (_isLoadingFeaturedThemes) return;

    _isLoadingFeaturedThemes = true;
    _featuredThemesError = null;
    notifyListeners();

    try {
      final Future<List<UserTopContent>> personalizedFuture = _loadPersonalizedTopContents();
      final List<FeaturedContentRecord> catalog =
          await _featuredContentRepository.getLatestContents(size: _featuredCatalogSize);
      final List<UserTopContent> personalized = await personalizedFuture;

      final Map<String, FeaturedContentRecord> recordsById = {
        for (final FeaturedContentRecord record in catalog)
          if (record.id.isNotEmpty) record.id: record,
      };
      await _resolveMissingRecords(personalized, recordsById);

      _featuredThemes = _featuredThemesComposer.compose(
        personalized: personalized,
        recordsById: recordsById,
        catalog: catalog,
        maxThemes: _maxFeaturedThemes,
      );

      if (kDebugMode) {
        final int personalizedCount = _featuredThemes
            .where((theme) => theme.source == FeaturedThemeSource.personalized)
            .length;
        debugPrint(
            '✅ [UserRelationNetworkVM] ${_featuredThemes.length} tema(s) em destaque ($personalizedCount personalizado(s))');
      }
    } catch (e) {
      _featuredThemes = [];
      _featuredThemesError = 'Erro ao carregar temas em destaque';
      if (kDebugMode) {
        debugPrint('❌ [UserRelationNetworkVM] Erro ao carregar temas em destaque: $e');
      }
    } finally {
      _isLoadingFeaturedThemes = false;
      notifyListeners();
    }
  }

  Future<List<UserTopContent>> _loadPersonalizedTopContents() async {
    final String? userId = _currentUserIdProvider();
    if (userId == null || userId.isEmpty) return const [];

    try {
      return await _featuredContentRepository.getUserTopContents(
        userId: userId,
        limit: _maxFeaturedThemes,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UserRelationNetworkVM] Top-contents indisponível, usando só o catálogo: $e');
      }
      return const [];
    }
  }

  Future<void> _resolveMissingRecords(
    List<UserTopContent> personalized,
    Map<String, FeaturedContentRecord> recordsById,
  ) async {
    final Set<String> missingIds = personalized
        .map((top) => top.contentId)
        .where((id) => !recordsById.containsKey(id))
        .toSet();
    if (missingIds.isEmpty) return;

    final List<FeaturedContentRecord?> resolved = await Future.wait(
      missingIds.map(_tryGetContentById),
    );
    for (final FeaturedContentRecord? record in resolved) {
      if (record != null && record.id.isNotEmpty) recordsById[record.id] = record;
    }
  }

  Future<FeaturedContentRecord?> _tryGetContentById(String contentId) async {
    try {
      return await _featuredContentRepository.getContentById(contentId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️  [UserRelationNetworkVM] Conteúdo $contentId indisponível: $e');
      }
      return null;
    }
  }

  Future<RelationSuggestionData?> _buildSuggestion(
    UserRankingSummaryModel ranking, {
    required int rankPosition,
  }) async {
    try {
      final UserDetailsModel details =
          await _userRepository.getUserDetails(ranking.userId);
      if (!details.active) return null;
      return RelationSuggestionData.fromRankingAndDetails(
        ranking: ranking,
        details: details,
        rankPosition: rankPosition,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️  [UserRelationNetworkVM] Detalhes indisponíveis para userId=${ranking.userId}: $e');
      }
      return null;
    }
  }

  /// Carrega lista de usuários reais para "Minhas Conexões"
  /// 
  /// Similar ao MessageUserListViewModel: GET /users + GET /users/{id}/details
  /// Filtra o próprio usuário da lista
  Future<void> loadConnections() async {
    _isLoadingConnections = true;
    _connectionsError = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════╗');
        debugPrint('║  🔄 CARREGANDO CONEXÕES - UserRelationNetworkViewModel        ║');
        debugPrint('╚════════════════════════════════════════════════════════════════╝');
      }

      // Step 1: Carregar lista básica de usuários
      final basicUsers = await _userRepository.getAll();
      if (kDebugMode) {
        debugPrint('   📊 ${basicUsers.length} usuários básicos carregados');
      }

      // Step 2: Enriquecer com detalhes (role designation)
      final List<MessageUserData> enrichedUsers = [];
      
      for (final user in basicUsers) {
        try {
          final details = await _userRepository.getUserDetails(user.id);
          final messageUserData = MessageUserData.fromUserAndDetails(user, details);
          enrichedUsers.add(messageUserData);
        } catch (e) {
          // Se falhar ao carregar detalhes, cria MessageUserData sem YouTube info
          if (kDebugMode) {
            debugPrint('   ⚠️  Detalhes não disponíveis para ${user.name}');
          }
          enrichedUsers.add(MessageUserData(
            id: user.id,
            name: user.name,
            surname: user.surname,
            email: user.email,
            fullName: '${user.name} ${user.surname}',
            youtubeUserId: null,
            youtubeChannelId: null,
          ));
        }
      }

      // Step 3: Filtrar o próprio usuário
      final currentUserId = injector<AuthTokenManager>().getUserId();
      _connections = enrichedUsers.where((user) => user.id != currentUserId).toList();

      if (kDebugMode) {
        debugPrint('   ✅ ${_connections.length} conexões carregadas (filtrou currentUserId)');
        debugPrint('   📋 Primeiros 20 serão exibidos na UI');
        debugPrint('─────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } catch (e) {
      _connections = [];
      _connectionsError = 'Erro ao carregar conexões';
      if (kDebugMode) {
        debugPrint('   ❌ Erro ao carregar conexões: $e');
      }
    } finally {
      _isLoadingConnections = false;
      notifyListeners();
    }
  }

  /// Carrega os detalhes do usuário via API
  /// 
  /// Consome: GET /api/v1/users/{userId}/details
  Future<void> loadUserDetails(String userId) async {
    _isLoadingUserDetails = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('📡 [UserRelationNetworkVM] Carregando user details para userId: $userId');
      }

      _userDetails = await _userRepository.getUserDetails(userId);

      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════╗');
        debugPrint('║  ✅ USER DETAILS CARREGADOS - UserRelationNetworkViewModel    ║');
        debugPrint('╚════════════════════════════════════════════════════════════════╝');
        debugPrint('   👤 Nome: ${_userDetails?.name}');
        debugPrint('   📧 Email: ${_userDetails?.email}');
        debugPrint('   📺 YouTube User ID: "${_userDetails?.youtubeUserId ?? "NULL"}"');
        debugPrint('   📺 YouTube Channel ID: "${_userDetails?.youtubeChannelId ?? "NULL"}"');
        debugPrint('   🎯 Tipo detectado: ${isContentCreator ? "CRIADOR" : "CONSUMIDOR"}');
        debugPrint('   🏷️  Título: "$dynamicTitlesByOwner"');
        debugPrint('─────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UserRelationNetworkVM] Erro ao carregar user details: $e');
      }
      // Não propaga erro para não bloquear a tela, apenas log
    } finally {
      _isLoadingUserDetails = false;
      notifyListeners();
    }
  }

  /// Ações mockadas (apenas prints para debug)
  void viewProfile(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('🔍 [UserRelationNetwork] Ver perfil: ${profile.name}');
    }
  }

  void sendMessage(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('💬 [UserRelationNetwork] Enviar mensagem para: ${profile.name}');
    }
  }

  void connect(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('🤝 [UserRelationNetwork] Conectar com: ${profile.name}');
    }
  }

  void disconnect(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('❌ [UserRelationNetwork] Desconectar de: ${profile.name}');
    }
  }

  // Os loads são assíncronos e a tela pode ser descartada antes de terminarem.
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

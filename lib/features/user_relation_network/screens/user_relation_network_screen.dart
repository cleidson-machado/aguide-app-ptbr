import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/user_message_flow/models/message_user_data.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';
import 'package:portugal_guide/features/user_message_flow/user_chat_message_view_screen.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';
import '../models/connection_profile_model.dart';
import '../viewmodels/user_relation_network_view_model.dart';

/// Tela de Rede de Conexões (Connections Network)
/// Layout vertical com scroll contínuo:
/// - Campo de busca
/// - Seção "Meus Vídeos" (grid vertical)
/// - Seção "Minhas Conexões" (grid vertical)
/// - Seção "Sugestões" (grid vertical)
/// - Seção "Temas em Destaque" (grid vertical)
/// 
/// Dados mockados para desenvolvimento da UI
class UserRelationNetworkScreen extends StatefulWidget {
  const UserRelationNetworkScreen({super.key});

  @override
  State<UserRelationNetworkScreen> createState() => _UserRelationNetworkScreenState();
}

class _UserRelationNetworkScreenState extends State<UserRelationNetworkScreen> {
  late final UserRelationNetworkViewModel _viewModel;
  late final TextEditingController _searchController;
  late final UserMessageFlowRepositoryInterface _messageRepository;
  final AuthTokenManager _tokenManager = injector<AuthTokenManager>();
  bool _isCreatingConversation = false;

  @override
  void initState() {
    super.initState();
    _viewModel = UserRelationNetworkViewModel();
    _searchController = TextEditingController();
    _messageRepository = injector<UserMessageFlowRepositoryInterface>();
    // 🆕 Carrega os detalhes do usuário para determinar CRIADOR/CONSUMIDOR
    _loadUserDetails();
    // 🆕 Carrega conexões reais via API
    _viewModel.loadConnections();
    // 🆕 Carrega conteúdos verificados (ownership)
    _loadOwnershipContents();
  }

  /// 🆕 Carrega os detalhes do usuário via API para determinar se é CRIADOR ou CONSUMIDOR
  Future<void> _loadUserDetails() async {
    final userId = _tokenManager.getUserId();
    if (userId != null && userId.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════╗');
        debugPrint('║  👤 CARREGANDO USER DETAILS - UserRelationNetworkScreen       ║');
        debugPrint('╚════════════════════════════════════════════════════════════════╝');
        debugPrint('   🆔 UserId: $userId');
        debugPrint('   📍 Origem: UserRelationNetworkScreen.initState()');
        debugPrint('─────────────────────────────────────────────────────────────────');
      }

      await _viewModel.loadUserDetails(userId);

      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════╗');
        debugPrint('║  🔄 ESTADO ATUAL DO VIEWMODEL - UserRelationNetwork          ║');
        debugPrint('╚════════════════════════════════════════════════════════════════╝');
        debugPrint('   📊 userDetails: ${_viewModel.userDetails != null ? "CARREGADO" : "NULL"}');
        debugPrint('   🎯 isContentCreator: ${_viewModel.isContentCreator}');
        debugPrint('   🏷️  meusVideosTitle: "${_viewModel.meusVideosTitle}"');
        debugPrint('─────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️  [UserRelationNetworkScreen] UserId não disponível - não é possível carregar user details');
      }
    }
  }

  /// 🆕 Carrega conteúdos verificados (ownership) do usuário
  Future<void> _loadOwnershipContents() async {
    final userId = _tokenManager.getUserId();
    if (userId != null && userId.isNotEmpty) {
      await _viewModel.loadOwnershipContents(userId);
    } else {
      if (kDebugMode) {
        debugPrint('⚠️  [UserRelationNetworkScreen] UserId não disponível - não é possível carregar ownership');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Navega de volta para a home (tela principal com tabs)
  /// Como esta tela é navegada via Modular.to.navigate(), ela está em uma pilha de rotas.
  void _navigateToHome(BuildContext context) {
    if (kDebugMode) {
      print('🔙 [UserRelationNetworkScreen] Navegando de volta para home...');
    }
    
    // Verifica se pode fazer pop (se há rota anterior na pilha)
    if (Navigator.of(context).canPop()) {
      if (kDebugMode) {
        print('📤 [UserRelationNetworkScreen] Fazendo Navigator.pop()...');
      }
      Navigator.of(context).pop();
    } else {
      // Fallback: navegar explicitamente para a rota main
      if (kDebugMode) {
        print('📤 [UserRelationNetworkScreen] Fallback: Modular.to.navigate(main)');
      }
      Modular.to.navigate(AppRoutes.main);
    }
  }

  /// Navega para a tela de mensagens (UsersMessageBucketScreen)
  /// Usa pushNamed para adicionar à pilha de navegação
  void _navigateToMessageBucket() {
    if (kDebugMode) {
      debugPrint('💬 [UserRelationNetworkScreen] Navegando para tela de mensagens...');
    }
    Modular.to.pushNamed(AppRoutes.messageBucket);
  }

  /// Navega para o chat direto com o usuário selecionado
  /// Cria/busca conversa e navega para UserChatMessageViewScreen
  Future<void> _handleUserTap(MessageUserData user) async {
    if (_isCreatingConversation) return;

    if (kDebugMode) {
      debugPrint('');
      debugPrint('👤 [UserRelationNetworkScreen] Usuário selecionado: ${user.fullName} (id=${user.id})');
    }

    setState(() {
      _isCreatingConversation = true;
    });

    try {
      // Mostra loading modal
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );

      if (kDebugMode) {
        debugPrint('🔄 [UserRelationNetworkScreen] Criando/buscando conversa direta...');
      }

      UserMessageContactModel? conversation;

      try {
        // Tenta criar conversa - backend retorna existente se já existe
        conversation = await _messageRepository.createDirectConversation(
          otherUserId: user.id,
        );
      } catch (e) {
        // Fallback: busca conversa existente na lista
        if (kDebugMode) {
          debugPrint('⚠️  [UserRelationNetworkScreen] Erro ao criar: $e');
          debugPrint('🔍 [UserRelationNetworkScreen] Buscando conversa existente...');
        }

        final existingConversations = await _messageRepository.getConversations();
        final directConversations = existingConversations
            .where((c) => c.type == 'DIRECT')
            .toList();

        // Tenta encontrar conversa acessível
        for (final conv in directConversations) {
          try {
            await _messageRepository.getConversationDetails(conv.id);
            conversation = conv;
            if (kDebugMode) {
              debugPrint('✅ [UserRelationNetworkScreen] Conversa encontrada: ${conv.id}');
            }
            break;
          } catch (detailsError) {
            // Continua para próxima
            continue;
          }
        }

        if (conversation == null) {
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint('✅ [UserRelationNetworkScreen] Conversa: ${conversation.id} - ${conversation.contactName}');
      }

      // Fecha loading modal
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navega para tela de chat
      if (mounted) {
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => UserChatMessageViewScreen(
              contact: conversation!,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [UserRelationNetworkScreen] Erro ao criar conversa:');
        debugPrint('   Tipo: ${e.runtimeType}');
        debugPrint('   Mensagem: $e');
        debugPrint('   StackTrace: $stackTrace');
      }

      // Fecha loading modal se ainda estiver exibindo
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostra dialog de erro
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erro'),
            content: Text(
              'Não foi possível iniciar a conversa.\n\nDetalhes: ${e.toString()}',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingConversation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => _navigateToHome(context),
        ),
        middle: const Text(
          'Guia - PORTUGAL - Relações',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        trailing: GestureDetector(
          onTap: () {
            // TODO: Implementar modal de filtros/configurações
            if (kDebugMode) {
              debugPrint('🔧 [UserRelationNetworkScreen] Botão de filtros clicado');
            }
          },
          child: const Icon(CupertinoIcons.slider_horizontal_3, size: 24),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        border: null,
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            return Column(
              children: [
                // Campo de busca FIXO (não faz scroll)
                _buildSearchBar(),
                
                // Conteúdo scrollable
                // 🆕 Dinâmico baseado no tipo de usuário:
                // - CRIADOR: "Meus Vídeos - CRIADOS"
                // - CONSUMIDOR: "Conteúdo Visualizado"
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Seção "Meus Vídeos" ou "Conteúdo Visualizado" (dinâmico)
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(_viewModel.meusVideosTitle),
                      ),
                      _buildMeusVideosSection(),

                      // Linha divisória com ponto
                      SliverToBoxAdapter(
                        child: _buildDividerWithDot(),
                      ),

                      // Seção "Minhas Conexões" (clicável - navega para mensagens)
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          'Conexões e Papos',
                          onTap: _navigateToMessageBucket,
                        ),
                      ),
                      _buildConnectionsSection(),

                      // Linha divisória com ponto
                      SliverToBoxAdapter(
                        child: _buildDividerWithDot(),
                      ),

                      // Seção "Sugestões"
                      SliverToBoxAdapter(
                        child: _buildSectionTitle('Sugestões'),
                      ),
                      _buildSuggestionsSection(),

                      // Linha divisória com ponto
                      SliverToBoxAdapter(
                        child: _buildDividerWithDot(),
                      ),

                      // Seção "Temas em Destaque"
                      SliverToBoxAdapter(
                        child: _buildSectionTitle('Temas em Destaque'),
                      ),
                      _buildTemasDestaqueSection(),

                      // Espaçamento final
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Campo de busca
  Widget _buildSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: CupertinoSearchTextField(
          controller: _searchController,
          placeholder: 'Buscar',
          onChanged: (value) => _viewModel.setSearchQuery(value),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Título de seção com chevron
  /// [onTap] callback opcional para tornar o título clicável
  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ],
      ),
    );

    // Se não há callback, retorna apenas o conteúdo estático
    if (onTap == null) {
      return content;
    }

    // Se há callback, envolve em GestureDetector com feedback visual
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  /// Linha divisória com ponto central
  Widget _buildDividerWithDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Linha horizontal mais visível
          Container(
            height: 2,
            color: CupertinoColors.systemGrey3.resolveFrom(context),
          ),
          // Ponto central
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey2.resolveFrom(context),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// Seção "Meus Vídeos" - Scroll horizontal com dados reais de Ownership
  Widget _buildMeusVideosSection() {
    // Estado de loading
    if (_viewModel.isLoadingOwnership) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    }

    // Estado de erro
    if (_viewModel.ownershipError != null) {
      return SliverToBoxAdapter(
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Text(
              _viewModel.ownershipError!,
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            ),
          ),
        ),
      );
    }

    final contents = _viewModel.ownershipContents;

    // Estado vazio
    if (contents.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Text(
              'Nenhum conteúdo verificado',
              style: TextStyle(
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = contents[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: _buildOwnershipContentCard(content),
            );
          },
        ),
      ),
    );
  }

  /// Seção "Minhas Conexões" - Scroll horizontal com dados reais da API
  /// Exibe até 20 usuários + botão "Ver Mais" no final
  Widget _buildConnectionsSection() {
    // Estado de loading
    if (_viewModel.isLoadingConnections) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    }

    // Estado de erro
    if (_viewModel.connectionsError != null) {
      return SliverToBoxAdapter(
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Text(
              _viewModel.connectionsError!,
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            ),
          ),
        ),
      );
    }

    final connections = _viewModel.connections; // Já limitado a 20
    final hasMore = _viewModel.hasMoreConnections;

    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // +1 para incluir o botão "Ver Mais" se houver mais de 20
          itemCount: hasMore ? connections.length + 1 : connections.length,
          itemBuilder: (context, index) {
            // Último item: botão "Ver Mais"
            if (index == connections.length) {
              return _buildViewMoreButton();
            }

            // Item normal: perfil de usuário
            final user = connections[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: _buildConnectionProfileCardFromUser(user),
            );
          },
        ),
      ),
    );
  }

  /// Seção "Sugestões" - Scroll horizontal
  Widget _buildSuggestionsSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.suggestions);

    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: _buildSuggestionProfileCard(profile),
            );
          },
        ),
      ),
    );
  }

  /// Seção "Temas em Destaque" - Scroll vertical independente
  Widget _buildTemasDestaqueSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.temasDestaque);

    return SliverToBoxAdapter(
      child: Container(
        height: 400, // Altura fixa para scroll independente
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: (profiles.length / 3).ceil(),
          itemBuilder: (context, rowIndex) {
            final startIndex = rowIndex * 3;
            final rowProfiles = <ConnectionProfileModel>[];
            
            for (int i = 0; i < 3; i++) {
              final profileIndex = startIndex + i;
              if (profileIndex < profiles.length) {
                rowProfiles.add(profiles[profileIndex]);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: rowProfiles.map((profile) {
                  return Expanded(
                    child: _buildTemasDestaqueProfileCard(profile),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Card de conteúdo verificado (Ownership) - Dados reais da API
  Widget _buildOwnershipContentCard(OwnershipContentModel content) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circular com inicial do canal
        ClipOval(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
            ),
            child: Center(
              child: Text(
                content.channelName.isNotEmpty
                    ? content.channelName[0].toUpperCase()
                    : '🎥',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Nome do canal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            content.channelName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Card de perfil circular (para "Minhas Conexões") - Dados reais da API
  Widget _buildConnectionProfileCardFromUser(MessageUserData user) {
    return GestureDetector(
      onTap: () => _handleUserTap(user),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar com iniciais como fallback
          ClipOval(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Nome completo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Botão "Ver Mais" (seta para direita) no final da lista de conexões
  Widget _buildViewMoreButton() {
    return GestureDetector(
      onTap: _navigateToMessageBucket,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo com ícone de seta
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                  width: 1.5,
                ),
              ),
              child: Icon(
                CupertinoIcons.arrow_right,
                size: 30,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 6),
            // Texto "Ver Mais"
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'Ver Mais',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de perfil circular (para "Sugestões")
  Widget _buildSuggestionProfileCard(ConnectionProfileModel profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // Avatar
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: profile.avatarUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => Container(
                width: 70,
                height: 70,
                color: CupertinoColors.systemGrey5,
                child: const Icon(CupertinoIcons.person_fill, size: 35),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Nome
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              profile.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
  }

  /// Card de perfil circular (para "Temas em Destaque")
  Widget _buildTemasDestaqueProfileCard(ConnectionProfileModel profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // Avatar
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: profile.avatarUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => Container(
                width: 70,
                height: 70,
                color: CupertinoColors.systemGrey5,
                child: const Icon(CupertinoIcons.person_fill, size: 35),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Nome
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              profile.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
  }
}
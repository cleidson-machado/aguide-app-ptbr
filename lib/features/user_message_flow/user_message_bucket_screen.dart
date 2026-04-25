import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user_message_flow/models/message_user_data.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/message_user_list_view_model.dart';
import 'package:portugal_guide/features/user_message_flow/widgets/message_user_list_item_widget.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';
import 'package:portugal_guide/features/user_message_flow/user_chat_message_view_screen.dart';

/// Users list screen - displays all system users for messaging
/// 
/// **Arquitetura DDD:** Usa MessageUserListViewModel e MessageUserListItemWidget
/// específicos desta feature, mantendo independência da feature core 'user'.
/// Combina UserModel + UserDetailsModel localmente para exibir role designation.
///
/// ⚠️ IMPORTANTE: Esta tela está sendo usada como TAB
/// Como é uma TAB, NÃO deve ter NavigationBar com botão voltar
/// (Tabs não têm pilha de navegação - causar tela preta ao usar Navigator.pop)
class UsersMessageBucketScreen extends StatefulWidget {
  const UsersMessageBucketScreen({super.key});

  @override
  State<UsersMessageBucketScreen> createState() =>
      _UsersMessageBucketScreenState();
}

class _UsersMessageBucketScreenState extends State<UsersMessageBucketScreen> {
  late ScrollController _scrollController;
  late MessageUserListViewModel _viewModel;
  late UserMessageFlowRepositoryInterface _messageRepository;
  bool _isCreatingConversation = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _viewModel = injector<MessageUserListViewModel>();
    _messageRepository = injector<UserMessageFlowRepositoryInterface>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadUsers();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      if (kDebugMode) {
        debugPrint(
          '📟 [UsersMessageBucketScreen] state loading=${_viewModel.isLoading} users=${_viewModel.users.length} error=${_viewModel.error}',
        );
      }
      setState(() {});
    }
  }

  /// Handles pull-to-refresh - fetches latest users from API
  Future<void> _handleRefresh() async {
    if (kDebugMode) {
      debugPrint('🔄 [UsersMessageBucketScreen] Pull-to-refresh acionado');
    }
    await _viewModel.refreshUsers();
  }

  /// Handles filter/sort icon tap (top-right)
  void _handleFilterTap() {
    if (kDebugMode) {
      debugPrint(
        '⚙️  [UsersMessageBucketScreen] Ordenação acionada',
      );
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Ordenar usuários'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _viewModel.sortUsers(MessageUserSortCriteria.alphabeticalAZ);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.sort_down, size: 20),
                    const SizedBox(width: 8),
                    const Text('Ordenar A-Z'),
                    if (_viewModel.currentSort == MessageUserSortCriteria.alphabeticalAZ)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          CupertinoIcons.check_mark,
                          size: 18,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _viewModel.sortUsers(MessageUserSortCriteria.alphabeticalZA);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.sort_up, size: 20),
                    const SizedBox(width: 8),
                    const Text('Ordenar Z-A'),
                    if (_viewModel.currentSort == MessageUserSortCriteria.alphabeticalZA)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          CupertinoIcons.check_mark,
                          size: 18,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
    );
  }

  /// Handles user tap - finds existing conversation or creates new one
  Future<void> _handleUserTap(MessageUserData user) async {
    if (_isCreatingConversation) return;

    if (kDebugMode) {
      debugPrint(
        '👤 [UsersMessageBucketScreen] Usuário selecionado: ${user.fullName} (id=${user.id})',
      );
    }

    setState(() {
      _isCreatingConversation = true;
    });

    try {
      // Show loading modal
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CupertinoActivityIndicator(radius: 20),
            ),
      );

      if (kDebugMode) {
        debugPrint('🔍 [UsersMessageBucketScreen] Buscando conversas existentes...');
      }

      // Step 1: Check if conversation already exists (for SQL-inserted conversations)
      final existingConversations = await _messageRepository.getConversations();
      
      UserMessageContactModel? conversation;
      
      // Try to find existing DIRECT conversation with this user
      // Since backend doesn't store otherUserId in list response, we need to check conversation details
      // For now, just try to create - if exists, backend returns existing one
      
      if (kDebugMode) {
        debugPrint('🔄 [UsersMessageBucketScreen] Tentando criar/recuperar conversa direta...');
      }
      
      try {
        // Try to create - backend should return existing if already exists
        conversation = await _messageRepository.createDirectConversation(
          otherUserId: user.id,
        );
      } catch (e) {
        // If 404 (user not found in backend validator), fall back to searching existing conversations
        if (kDebugMode) {
          debugPrint('⚠️ [UsersMessageBucketScreen] Erro ao criar conversa: $e');
          debugPrint('🔍 [UsersMessageBucketScreen] Tentando buscar conversa existente na lista...');
        }
        
        // Fallback: try to find in existing conversations list
        // (This handles SQL-inserted conversations that backend can't create)
        if (existingConversations.isNotEmpty) {
          final directConversations = existingConversations.where((c) => c.type == 'DIRECT').toList();
          
          if (kDebugMode) {
            debugPrint('📋 [UsersMessageBucketScreen] Conversas DIRECT encontradas: ${directConversations.length}');
            for (final conv in directConversations) {
              debugPrint('   - ID: ${conv.id}, Nome: ${conv.contactName}');
            }
          }
          
          // For direct conversations, we need full details to know the other participant
          for (final conv in directConversations) {
            try {
              if (kDebugMode) {
                debugPrint('🔍 [UsersMessageBucketScreen] Tentando acessar conversa ${conv.id}...');
              }
              
              // Get full conversation details to verify participants
              await _messageRepository.getConversationDetails(conv.id);
              // Use this conversation (for now, first DIRECT found)
              conversation = conv;
              
              if (kDebugMode) {
                debugPrint('✅ [UsersMessageBucketScreen] Conversa acessível encontrada: ${conv.id}');
              }
              break;
            } catch (detailsError) {
              if (kDebugMode) {
                debugPrint('⚠️ [UsersMessageBucketScreen] Conversa ${conv.id} não acessível: $detailsError');
                debugPrint('   Continuando busca...');
              }
              // Continue to next conversation
            }
          }
          
          if (conversation == null && kDebugMode) {
            debugPrint('❌ [UsersMessageBucketScreen] Nenhuma conversa DIRECT acessível encontrada!');
          }
        }
        
        // If still no conversation found, re-throw original error
        if (conversation == null) {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('🚨 [UsersMessageBucketScreen] DIAGNÓSTICO DO PROBLEMA:');
            debugPrint('   1. POST /conversations/direct retornou 404 (usuário não encontrado no backend)');
            debugPrint('   2. GET /conversations retornou ${existingConversations.length} conversas');
            debugPrint('   3. Nenhuma conversa DIRECT é acessível pelo usuário logado');
            debugPrint('');
            debugPrint('💡 POSSÍVEIS CAUSAS:');
            debugPrint('   - Conversa inserida via SQL sem incluir usuário logado nos participantes');
            debugPrint('   - Tabela conversation_participant inconsistente');
            debugPrint('   - Usuário ${user.id} não existe no backend (inserido apenas no banco)');
            debugPrint('');
            debugPrint('🔧 SOLUÇÃO:');
            debugPrint('   Verificar tabela conversation_participant no PostgreSQL');
            debugPrint('   Garantir que ambos os usuários estejam registrados via API REST');
            debugPrint('');
          }
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint(
          '✅ [UsersMessageBucketScreen] Conversa retornada:'
          '\n  - id: ${conversation.id}'
          '\n  - contactName: ${conversation.contactName}'
          '\n  - type: ${conversation.type}',
        );
      }

      // Close loading modal
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to chat screen
      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => UserChatMessageViewScreen(
              contact: conversation!, // Safe after null check in catch block
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [UsersMessageBucketScreen] Erro ao criar conversa:');
        debugPrint('   Tipo: ${e.runtimeType}');
        debugPrint('   Mensagem: $e');
        debugPrint('   StackTrace: $stackTrace');
      }

      // Close loading modal if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Erro'),
                content: Text(
                  e.toString().contains('Não é possível')
                      ? e.toString()
                      : 'Não foi possível iniciar a conversa. Tente novamente.\n\nDetalhes: $e',
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
      backgroundColor: CupertinoColors.white,
      navigationBar: _buildNavigationBar(context),
      child: SafeArea(child: _buildBody()),
    );
  }

  /// Builds custom iOS-style navigation bar with left-aligned title
  /// Follows clean, minimalist design with back button + title side-by-side
  CupertinoNavigationBar _buildNavigationBar(BuildContext context) {
    // Check if can actually navigate back (important for TAB screens)
    final canPop = Navigator.of(context).canPop();

    return CupertinoNavigationBar(
      transitionBetweenRoutes: false,
      backgroundColor: CupertinoColors.white,
      border: const Border(
        bottom: BorderSide(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      // Left-aligned back button + title (iOS style)
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back button - only show if can navigate back
          if (canPop)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 44,
              onPressed: () => Navigator.of(context).pop(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.back,
                    size: 28,
                    color: CupertinoColors.black,
                  ),
                  SizedBox(width: 6),
                ],
              ),
            ),
          // Title - bold, left-aligned with back button
          const Text(
            'Mensagens',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700, // Bold for strong hierarchy
              color: CupertinoColors.black,
              fontFamily: '.SF Pro Display', // iOS system font
              letterSpacing: -0.5, // Tighter tracking (iOS style)
            ),
          ),
        ],
      ),
      // Filter/sort button on the right
      trailing: GestureDetector(
        onTap: _handleFilterTap,
        child: const Icon(
          CupertinoIcons.slider_horizontal_3,
          size: 24,
          color: CupertinoColors.black,
        ),
      ),
      // Prevents title from being centered (we control layout in leading)
      middle: null,
    );
  }

  Widget _buildBody() {
    if (_viewModel.error != null && _viewModel.users.isEmpty) {
      return _buildErrorState(_viewModel.error!);
    }

    if (_viewModel.isLoading && _viewModel.users.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (_viewModel.users.isEmpty) {
      return _buildEmptyState();
    }

    return _buildUsersList(_viewModel.users);
  }

  /// Builds the scrollable users list
  Widget _buildUsersList(List<MessageUserData> users) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pull-to-refresh control
        CupertinoSliverRefreshControl(onRefresh: _handleRefresh),

        // Users list
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final user = users[index];
              return MessageUserListItemWidget(
                user: user,
                onTap: () => _handleUserTap(user),
              );
            }, childCount: users.length),
          ),
        ),
      ],
    );
  }

  /// Builds empty state when no users exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 80,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum usuário encontrado',
            style: TextStyle(
              fontSize: 18,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Os usuários do sistema aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    if (kDebugMode) {
      debugPrint('❌ [UsersMessageBucketScreen] Error state message=$message');
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 60,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar usuários',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: () => _viewModel.loadUsers(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}


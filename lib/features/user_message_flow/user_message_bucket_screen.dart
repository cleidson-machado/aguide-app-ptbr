import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/features/user/user_model_extensions.dart';
import 'package:portugal_guide/features/user/user_list_view_model.dart';
import 'package:portugal_guide/features/user/widgets/user_list_item_widget.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';
import 'package:portugal_guide/features/user_message_flow/user_chat_message_view_screen.dart';

/// Users list screen - displays all system users for messaging
/// Refactored from conversation list to show available users
/// Uses MVVM architecture with UserListViewModel
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
  late UserListViewModel _viewModel;
  late UserMessageFlowRepositoryInterface _messageRepository;
  bool _isCreatingConversation = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _viewModel = injector<UserListViewModel>();
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
                  _viewModel.sortUsers(UserSortCriteria.alphabeticalAZ);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.sort_down, size: 20),
                    const SizedBox(width: 8),
                    const Text('Ordenar A-Z'),
                    if (_viewModel.currentSort == UserSortCriteria.alphabeticalAZ)
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
                  _viewModel.sortUsers(UserSortCriteria.alphabeticalZA);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.sort_up, size: 20),
                    const SizedBox(width: 8),
                    const Text('Ordenar Z-A'),
                    if (_viewModel.currentSort == UserSortCriteria.alphabeticalZA)
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

  /// Handles user tap - creates/opens conversation with selected user
  Future<void> _handleUserTap(UserModel user) async {
    if (_isCreatingConversation) return;

    if (kDebugMode) {
      debugPrint(
        '👤 [UsersMessageBucketScreen] Usuário selecionado: ${user.fullName}',
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

      // Create or retrieve direct conversation with this user
      final conversation = await _messageRepository.createDirectConversation(
        otherUserId: user.id,
      );

      if (kDebugMode) {
        debugPrint(
          '✅ [UsersMessageBucketScreen] Conversa criada/recuperada: ${conversation.id}',
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
              contact: conversation,
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UsersMessageBucketScreen] Erro ao criar conversa: $e');
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
                      : 'Não foi possível iniciar a conversa. Tente novamente.',
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
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        middle: const Text(
          'Mensagens',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: GestureDetector(
          onTap: _handleFilterTap,
          child: const Icon(CupertinoIcons.slider_horizontal_3, size: 24),
        ),
      ),
      child: SafeArea(child: _buildBody()),
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
  Widget _buildUsersList(List<UserModel> users) {
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
              return UserListItemWidget(
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


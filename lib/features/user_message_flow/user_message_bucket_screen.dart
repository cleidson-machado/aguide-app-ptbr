import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_bucket_view_model.dart';
import 'package:portugal_guide/features/user_message_flow/widgets/user_message_contact_list_item_widget.dart';
import 'package:portugal_guide/features/user_message_flow/user_chat_message_view_screen.dart';

/// Messages list screen (WhatsApp-style conversation list)
/// Displays user contacts with message previews, timestamps, and online status
/// Uses MVVM architecture with real API integration via UserMessageFlowRepository
///
/// ⚠️ IMPORTANTE: Esta tela está sendo usada TEMPORARIAMENTE como TAB
/// (substituindo RELAÇÕES em HomeContentTabScreen para testes iniciais)
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
  late UserMessageBucketViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _viewModel = injector<UserMessageBucketViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadConversations();
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
          '📟 [UsersMessageBucketScreen] state loading=${_viewModel.isLoading} conversations=${_viewModel.conversations.length} error=${_viewModel.error}',
        );
      }
      setState(() {});
    }
  }

  /// Handles pull-to-refresh - fetches latest conversations from API
  Future<void> _handleRefresh() async {
    if (kDebugMode) {
      debugPrint('🔄 [UsersMessageBucketScreen] Pull-to-refresh acionado');
    }
    await _viewModel.refreshConversations();
  }

  /// Handles filter/settings icon tap (top-right)
  void _handleFilterTap() {
    if (kDebugMode) {
      debugPrint(
        '⚙️  [UsersMessageBucketScreen] Filtro/configurações acionado',
      );
    }

    // TODO: Implement filter/settings modal
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Filtros'),
            content: const Text(
              'Funcionalidade de filtros será implementada em breve.',
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

  /// Handles contact tap (opens chat detail screen)
  void _handleContactTap(UserMessageContactModel contact) {
    if (kDebugMode) {
      debugPrint(
        '💬 [UsersMessageBucketScreen] Contato selecionado: ${contact.contactName}',
      );
    }

    // Navigate to chat detail screen
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => UserChatMessageViewScreen(contact: contact),
      ),
    );
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
    if (_viewModel.error != null && _viewModel.conversations.isEmpty) {
      return _buildErrorState(_viewModel.error!);
    }

    if (_viewModel.isLoading && _viewModel.conversations.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (_viewModel.conversations.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMessagesList(_viewModel.conversations);
  }

  /// Builds the scrollable messages list
  Widget _buildMessagesList(List<UserMessageContactModel> conversations) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pull-to-refresh control
        CupertinoSliverRefreshControl(onRefresh: _handleRefresh),

        // Messages list
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final contact = conversations[index];
              return UserMessageContactListItemWidget(
                contact: contact,
                onTap: () => _handleContactTap(contact),
              );
            }, childCount: conversations.length),
          ),
        ),
      ],
    );
  }

  /// Builds empty state when no conversations exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 80,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda',
            style: TextStyle(
              fontSize: 18,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'As conversas aparecerão aqui',
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
              'Erro ao carregar conversas',
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
              onPressed: () => _viewModel.loadConversations(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

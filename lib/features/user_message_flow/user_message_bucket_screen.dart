import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/widgets/user_message_contact_list_item_widget.dart';

/// Messages list screen (WhatsApp-style conversation list)
/// Displays user contacts with message previews, timestamps, and online status
/// Currently uses mocked data - will integrate with MVVM later
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

class _UsersMessageBucketScreenState
    extends State<UsersMessageBucketScreen> {
  late ScrollController _scrollController;
  List<UserMessageContactModel> _conversations = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadMockedContacts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads mocked contacts for development/testing
  void _loadMockedContacts() {
    setState(() {
      _conversations = UserMessageContactModel.getMockedContacts();
    });

    if (kDebugMode) {
      debugPrint(
          '📜 [UsersMessageBucketScreen] Carregados ${_conversations.length} contatos mocados');
    }
  }

  /// Handles pull-to-refresh (mocked delay)
  Future<void> _handleRefresh() async {
    if (kDebugMode) {
      debugPrint('🔄 [UsersMessageBucketScreen] Pull-to-refresh acionado');
    }

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Reload mocked data
    _loadMockedContacts();
  }

  /// Handles filter/settings icon tap (top-right)
  void _handleFilterTap() {
    if (kDebugMode) {
      debugPrint(
          '⚙️  [UsersMessageBucketScreen] Filtro/configurações acionado');
    }

    // TODO: Implement filter/settings modal
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Filtros'),
        content: const Text('Funcionalidade de filtros será implementada em breve.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handles contact tap (opens chat - future implementation)
  void _handleContactTap(UserMessageContactModel contact) {
    if (kDebugMode) {
      debugPrint(
          '💬 [UsersMessageBucketScreen] Contato selecionado: ${contact.contactName}');
    }

    // TODO: Navigate to chat screen
    // Modular.to.navigate('/user_message_flow/chat/${contact.id}');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        // ⚠️ BOTÃO DE VOLTAR TEMPORÁRIO - Apenas visual por enquanto
        // Esta tela está como TAB para testes iniciais do layout
        // Quando migrar para rota navegada, substituir por: Navigator.of(context).pop()
        // Por ora, mantém layout correto mas sem funcionalidade real
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            if (kDebugMode) {
              debugPrint('◀️  [UsersMessageBucketScreen] Botão voltar (sem funcionalidade ainda - tela é tab temporária)');
            }
            // TODO: Quando migrar para rota navegada, usar: Navigator.of(context).pop()
          },
        ),
        middle: const Text(
          'Mensagens',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: GestureDetector(
          onTap: _handleFilterTap,
          child: const Icon(
            CupertinoIcons.slider_horizontal_3,
            size: 24,
          ),
        ),
      ),
      child: SafeArea(
        child: _conversations.isEmpty ? _buildEmptyState() : _buildMessagesList(),
      ),
    );
  }

  /// Builds the scrollable messages list
  Widget _buildMessagesList() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pull-to-refresh control
        CupertinoSliverRefreshControl(
          onRefresh: _handleRefresh,
        ),

        // Messages list
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final contact = _conversations[index];
                return UserMessageContactListItemWidget(
                  contact: contact,
                  onTap: () => _handleContactTap(contact),
                );
              },
              childCount: _conversations.length,
            ),
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
}
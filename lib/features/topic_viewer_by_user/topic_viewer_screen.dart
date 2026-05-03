import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_option.dart';
import 'package:portugal_guide/features/topic_viewer_by_user/topic_viewer_view_model.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TopicViewerScreen extends StatefulWidget {
  const TopicViewerScreen({super.key});

  @override
  State<TopicViewerScreen> createState() => _TopicViewerScreenState();
}

class _TopicViewerScreenState extends State<TopicViewerScreen>
    with AutomaticKeepAliveClientMixin {
  final MainContentTopicViewModel mainContentTopicViewModel =
      injector<MainContentTopicViewModel>();
  final TopicViewerViewModel topicViewerViewModel =
      injector<TopicViewerViewModel>();
  late ScrollController _scrollController;
  Timer? _debounce;
  Timer? _dialogTimer; // Timer para auto-fechar dialogs

  /// Mantém o estado vivo quando a tab não está ativa
  /// Evita recriação do widget e recarregamento de dados ao trocar de tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    mainContentTopicViewModel.loadPagedContentsIfNeeded();
    
    final userId = injector<AuthTokenManager>().getUserId();
    if (userId != null) {
      topicViewerViewModel.loadUserDetails(userId);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _dialogTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    mainContentTopicViewModel.dispose();
    topicViewerViewModel.dispose();
    super.dispose();
  }

  /// Listener para detectar quando o usuário chegou próximo do final da lista
  /// Usa uma margem de 200px para disparar o carregamento antes de atingir o final absoluto
  void _onScroll() {
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Se chegou perto do final (dentro de 200px) e há mais páginas
    if (currentScroll >= maxScroll - 200) {
      if (mainContentTopicViewModel.hasMorePages && !mainContentTopicViewModel.isLoadingMore) {
        if (kDebugMode) {
          debugPrint(
            "📜 [_TopicViewerScreenState] Scroll trigger: carregando próxima página",
          );
        }
        mainContentTopicViewModel.loadNextPage();
      }
    }
  }

  /// Handler de busca com debounce de 500ms
  /// Cancela requisições anteriores se o usuário continuar digitando
  /// Reduz em ~95% o número de chamadas à API durante a digitação
  void _onSearchChanged(String value) {
    // Cancela timer anterior se existir
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Cria novo timer de 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      mainContentTopicViewModel.searchContents(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // OBRIGATÓRIO: chama super.build() para AutomaticKeepAliveClientMixin funcionar
    super.build(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            if (kDebugMode) {
              debugPrint('🔙 [TopicViewerScreen] Botão de voltar clicado');
            }
          },
        ),
        middle: AnimatedBuilder(
          animation: topicViewerViewModel,
          builder: (context, _) => Text(topicViewerViewModel.dinamicTitle),
        ),
        trailing: GestureDetector(
          onTap: () {
            _filterPopUpHandler(context);
          },
          child: const Icon(CupertinoIcons.slider_horizontal_3, size: 24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: CupertinoSearchTextField(
              onChanged: _onSearchChanged, // Usa handler com debounce
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: mainContentTopicViewModel,
              builder: (context, child) {
                return _buildBody();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (mainContentTopicViewModel.isLoading) {
      // Skeleton loader para carregamento inicial
      return _buildSkeletonList();
    }

    if (mainContentTopicViewModel.error != null) {
      return Center(
        child: Text(
          mainContentTopicViewModel.errorMessage ?? 'Erro desconhecido',
          style: const TextStyle(color: CupertinoColors.systemRed),
        ),
      );
    }

    if (mainContentTopicViewModel.contents.isEmpty) {
      return const Center(child: Text("Nenhum conteúdo encontrado."));
    }

    // CustomScrollView permite usar CupertinoSliverRefreshControl (pull-to-refresh nativo iOS)
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pull-to-refresh control nativo do iOS
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await mainContentTopicViewModel.refreshContents();
          },
        ),
        // Lista de conteúdos com paginação
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Se for o último item e estamos carregando, mostrar skeleton loader
                if (index == mainContentTopicViewModel.contents.length) {
                  return _buildSkeletonCard();
                }

                final content = mainContentTopicViewModel.contents[index];
                return _buildBlogCard(content);
              },
              childCount:
                  mainContentTopicViewModel.contents.length + (mainContentTopicViewModel.isLoadingMore ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlogCard(MainContentTopicModel content) {
    return Padding(
      key: ValueKey('content_${content.id}'), // Key única para otimizar rebuilds
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.50),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card principal (thumbnail + conteúdo)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail à esquerda
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: content.videoThumbnailUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 200,
                      maxWidthDiskCache: 200,
                      maxHeightDiskCache: 200,
                      placeholder: (context, url) => Container(
                        width: 100,
                        height: 100,
                        color: CupertinoColors.systemGrey5,
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100,
                        height: 100,
                        color: CupertinoColors.systemGrey5,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: CupertinoColors.systemGrey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Conteúdo textual
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          content.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Descrição
                        Text(
                          content.description.isNotEmpty
                              ? content.description
                              : 'Este vídeo não possui descrição.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            const Divider(height: 1, color: CupertinoColors.systemGrey5),
            
            // Métricas de engajamento
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3E5F5), Color(0xFFE1F5FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    icon: CupertinoIcons.eye_fill,
                    value: _formatNumber(content.viewCount),
                    label: 'Views',
                    color: const Color(0xFF9575CD),
                  ),
                  Container(width: 1, height: 40, color: CupertinoColors.systemGrey4),
                  _buildMetric(
                    icon: CupertinoIcons.hand_thumbsup_fill,
                    value: _formatNumber(content.likeCount),
                    label: 'Likes',
                    color: const Color(0xFFE57373),
                  ),
                  Container(width: 1, height: 40, color: CupertinoColors.systemGrey4),
                  _buildMetric(
                    icon: CupertinoIcons.chat_bubble_fill,
                    value: _formatNumber(content.commentCount),
                    label: 'Comentários',
                    color: const Color(0xFF4FC3F7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formata números grandes (ex: 1.5M, 250K, 1.2K)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// Constrói widget de métrica com ícone, valor e label
  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Skeleton loader para lista completa (carregamento inicial)
  Widget _buildSkeletonList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: 8, // Mostra 8 skeletons placeholder
        itemBuilder: (context, index) {
          return _buildSkeletonCardContent();
        },
      ),
    );
  }

  /// Skeleton loader para um único card (carregamento incremental)
  Widget _buildSkeletonCard() {
    return Skeletonizer(
      enabled: true,
      child: _buildSkeletonCardContent(),
    );
  }

  /// Conteúdo do skeleton card (reutilizável)
  Widget _buildSkeletonCardContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.square(size: 100, borderRadius: BorderRadius.circular(8)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 3, fontSize: 16),
                        SizedBox(height: 4),
                        Bone.text(words: 6, fontSize: 13),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CupertinoColors.systemGrey5),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3E5F5), Color(0xFFE1F5FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: Bone.text(words: 1, fontSize: 14)),
                  SizedBox(width: 8),
                  Expanded(child: Bone.text(words: 1, fontSize: 14)),
                  SizedBox(width: 8),
                  Expanded(child: Bone.text(words: 1, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _filterPopUpHandler(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text(
              'Selecione a ordenação dos conteúdos',
              style: TextStyle(fontSize: 14),
            ),
            message: const Text(
              'Escolha como deseja visualizar os conteúdos',
              style: TextStyle(fontSize: 12),
            ),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await mainContentTopicViewModel.applyManualFilter(
                    MainContentSortOption.titleAscending,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.sort_up, size: 20),
                    SizedBox(width: 8),
                    Text('Título A-Z'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await mainContentTopicViewModel.applyManualFilter(
                    MainContentSortOption.titleDescending,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.sort_down, size: 20),
                    SizedBox(width: 8),
                    Text('Título Z-A'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await mainContentTopicViewModel.applyManualFilter(
                    MainContentSortOption.newestPublished,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.clock_fill, size: 20),
                    SizedBox(width: 8),
                    Text('Mais Recentes'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await mainContentTopicViewModel.applyManualFilter(
                    MainContentSortOption.oldestPublished,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.time, size: 20),
                    SizedBox(width: 8),
                    Text('Mais Antigos'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await mainContentTopicViewModel.applyManualFilter(
                    MainContentSortOption.channelNameAscending,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.tv, size: 20),
                    SizedBox(width: 8),
                    Text('Canal A-Z'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await mainContentTopicViewModel.applyManualFilter(
                    MainContentSortOption.recentlyAdded,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add_circled_solid, size: 20),
                    SizedBox(width: 8),
                    Text('Adicionados Recentemente'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await mainContentTopicViewModel.resetToRandomMode();
                  if (context.mounted) {
                    _showResetMessage(context, '🎲 Modo Aleatório ativado!');
                  }
                },
                isDestructiveAction: false,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.shuffle,
                      size: 20,
                      color: CupertinoColors.activeBlue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '🎲 Surpreenda-me (Aleatório)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Sair'),
            ),
          ),
    );
  }

  /// Exibe mensagem de confirmação com auto-close
  void _showResetMessage(BuildContext context, String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: CupertinoColors.activeGreen,
              size: 48,
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
          ),
    );

    // Auto-fechar após 1.5 segundos
    _dialogTimer?.cancel();
    _dialogTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Dialog já foi fechado: $e');
          }
        }
      }
    });
  }
}

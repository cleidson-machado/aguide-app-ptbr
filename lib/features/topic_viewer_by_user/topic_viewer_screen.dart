import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
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
  final TopicViewerViewModel topicViewerViewModel = injector<TopicViewerViewModel>();
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
    
    final userId = injector<AuthTokenManager>().getUserId();
    if (userId != null) {
      // Carrega user details e ownership contents (vídeos do usuário)
      topicViewerViewModel.loadUserDetails(userId);
      topicViewerViewModel.loadOwnershipContents(userId);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _dialogTimer?.cancel();
    _scrollController.dispose();
    topicViewerViewModel.dispose();
    super.dispose();
  }

  /// Handler de busca com debounce de 500ms
  /// Filtra conteúdos localmente (ownership já carregado)
  void _onSearchChanged(String value) {
    // TODO: Implementar filtro local se necessário
    // Por enquanto, busca está desabilitada para ownership contents
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
          const Divider(height: 1, thickness: 0.5, color: CupertinoColors.systemGrey4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: CupertinoSearchTextField(
              onChanged: _onSearchChanged,
              placeholder: 'Pesquisar ${topicViewerViewModel.isContentCreator ? 'em criados' : ' em assistidos'}',
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: CupertinoColors.systemGrey4),
          Expanded(
            child: AnimatedBuilder(
              animation: topicViewerViewModel,
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
    // Loading inicial
    if (topicViewerViewModel.isLoadingOwnership) {
      return _buildSkeletonList();
    }

    // Erro ao carregar
    if (topicViewerViewModel.ownershipError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              topicViewerViewModel.ownershipError!,
              style: const TextStyle(color: CupertinoColors.systemRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () {
                final userId = injector<AuthTokenManager>().getUserId();
                if (userId != null) {
                  topicViewerViewModel.loadOwnershipContents(userId);
                }
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    // Lista vazia
    if (!topicViewerViewModel.hasOwnershipContents) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.video_camera,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              topicViewerViewModel.isContentCreator
                  ? 'Você ainda não tem vídeos verificados'
                  : 'Nenhum conteúdo assistido',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lista de conteúdos (ownership)
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pull-to-refresh
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            final userId = injector<AuthTokenManager>().getUserId();
            if (userId != null) {
              await topicViewerViewModel.loadOwnershipContents(userId);
            }
          },
        ),
        
        // 📊 Indicador de enriquecimento de métricas (não-bloqueante)
        if (topicViewerViewModel.isEnrichingMetrics)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF90CAF9),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(radius: 8),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📊 Carregando métricas de engajamento...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Lista de cards
        SliverPadding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 2, bottom: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ownershipContent = topicViewerViewModel.ownershipContents[index];
                // Converte OwnershipContentModel para MainContentTopicModel
                final content = _convertToMainContentModel(ownershipContent);
                return _buildBlogCard(content);
              },
              childCount: topicViewerViewModel.ownershipContents.length,
            ),
          ),
        ),
      ],
    );
  }

  /// Converte OwnershipContentModel para MainContentTopicModel
  /// Usado para manter compatibilidade com widgets existentes
  /// 
  /// **OTIMIZAÇÃO:** Busca dados enriquecidos (com métricas reais) se disponíveis
  MainContentTopicModel _convertToMainContentModel(
    ownershipContent,
  ) {
    // 🚀 Tentar obter dados completos (com métricas) do cache
    final enrichedContent = topicViewerViewModel.getEnrichedContent(
      ownershipContent.contentId,
    );

    if (enrichedContent != null) {
      if (kDebugMode) {
        debugPrint(
          '✅ [Adapter] Usando dados enriquecidos: ${enrichedContent.title} '
          '(Views: ${enrichedContent.viewCount}, Likes: ${enrichedContent.likeCount})',
        );
      }
      return enrichedContent;
    }

    // ⚠️ Fallback: Retornar dados básicos com métricas zeradas
    if (kDebugMode) {
      debugPrint(
        '⚠️  [Adapter] Dados enriquecidos não disponíveis para: ${ownershipContent.contentId}',
      );
    }

    return MainContentTopicModel(
      id: ownershipContent.contentId,
      title: ownershipContent.title,
      description: ownershipContent.description,
      videoUrl: ownershipContent.videoUrl,
      videoThumbnailUrl: ownershipContent.videoThumbnailUrl,
      publishedAt: ownershipContent.publishedAt,
      createdAt: ownershipContent.verifiedAt, // Usa verifiedAt como createdAt
      updatedAt: ownershipContent.verifiedAt,
      channelId: ownershipContent.channelId,
      channelOwnerLinkId: null,
      channelName: ownershipContent.channelName,
      type: 'VIDEO',
      categoryId: '',
      categoryName: '',
      tags: null,
      durationSeconds: 0,
      durationIso: 'PT0S',
      definition: 'hd',
      caption: false,
      // Métricas zeradas (ownership não fornece)
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      defaultLanguage: null,
      defaultAudioLanguage: null,
      validationHash: ownershipContent.validationHash,
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
        padding: const EdgeInsets.only(left: 20, right: 20, top: 2, bottom: 20),
        itemCount: 8,
        itemBuilder: (context, index) {
          return _buildSkeletonCardContent();
        },
      ),
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
                onPressed: () {
                  Navigator.pop(context);
                  topicViewerViewModel.sortByTitleAscending();
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
                onPressed: () {
                  Navigator.pop(context);
                  topicViewerViewModel.sortByTitleDescending();
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
                onPressed: () {
                  Navigator.pop(context);
                  topicViewerViewModel.sortByNewestPublished();
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
                onPressed: () {
                  Navigator.pop(context);
                  topicViewerViewModel.sortByOldestPublished();
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
                onPressed: () {
                  Navigator.pop(context);
                  topicViewerViewModel.sortByChannelNameAscending();
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
                onPressed: () {
                  Navigator.pop(context);
                  topicViewerViewModel.sortByRecentlyAdded();
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
                onPressed: () {
                  Navigator.pop(context);
                  topicViewerViewModel.shuffleContents();
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

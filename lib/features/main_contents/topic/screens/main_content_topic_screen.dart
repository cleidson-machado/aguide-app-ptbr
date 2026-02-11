import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_option.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MainContentTopicScreen extends StatefulWidget {
  const MainContentTopicScreen({super.key});

  @override
  State<MainContentTopicScreen> createState() => _MainContentTopicScreenState();
}

class _MainContentTopicScreenState extends State<MainContentTopicScreen>
    with AutomaticKeepAliveClientMixin {
  final MainContentTopicViewModel viewModel =
      injector<MainContentTopicViewModel>();
  late ScrollController _scrollController;
  Timer? _debounce; // Timer para debounce na busca
  Timer? _dialogTimer; // Timer para auto-fechar dialog

  /// Mantém o estado vivo quando a tab não está ativa
  /// Evita recriação do widget e recarregamento de dados ao trocar de tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Carrega apenas se for a primeira vez (viewModel não inicializado)
    viewModel.loadPagedContentsIfNeeded();
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancela o timer pendente ao destruir o widget
    _dialogTimer?.cancel(); // Cancela timer do dialog
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    viewModel.dispose();
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
      if (viewModel.hasMorePages && !viewModel.isLoadingMore) {
        if (kDebugMode) {
          debugPrint(
            "📜 [_MainContentTopicScreenState] Scroll trigger: carregando próxima página",
          );
        }
        viewModel.loadNextPage();
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
      viewModel.searchContents(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // OBRIGATÓRIO: chama super.build() para AutomaticKeepAliveClientMixin funcionar
    super.build(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Guia - PORTUGAL",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 6),
            Text(
              "| TEMAS - Perfil CRIADOR de Conteúdo |",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.systemPink,
              ),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () {
            _filterPopUpHandler(context);
          },
          child: const Icon(CupertinoIcons.slider_horizontal_3, size: 24),
        ),
      ),
      child: AnimatedBuilder(
        animation: viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: CupertinoSearchTextField(
                      onChanged: _onSearchChanged, // Usa handler com debounce
                    ),
                  ),
                  Expanded(child: _buildBody()),
                ],
              ),
              // Botão flutuante de reset (só aparece quando filtro manual está ativo)
              if (viewModel.isManualFilterActive)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(child: _buildResetFilterButton(context)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (viewModel.isLoading) {
      // Skeleton loader para carregamento inicial
      return _buildSkeletonGrid();
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(
          viewModel.error!,
          style: const TextStyle(color: CupertinoColors.systemRed),
        ),
      );
    }

    if (viewModel.contents.isEmpty) {
      return const Center(child: Text("Nenhum conteúdo encontrado."));
    }

    // CustomScrollView com lista vertical de cards
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pull-to-refresh control nativo do iOS
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await viewModel.refreshContents();
          },
        ),
        // Lista de conteúdos com paginação
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Se for o último item e estamos carregando, mostrar skeleton loader
                if (index == viewModel.contents.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildSkeletonCard(),
                  );
                }

                final content = viewModel.contents[index];
                // Key única baseada no ID do conteúdo para otimizar rebuilds
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildContentCard(content),
                );
              },
              childCount:
                  viewModel.contents.length + (viewModel.isLoadingMore ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(MainContentTopicModel content) {
    return Container(
      key: ValueKey('content_${content.id}'),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail com destaque no topo
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: content.contentImageUrl,
                fit: BoxFit.contain,
                memCacheWidth: 600,
                memCacheHeight: 340,
                maxWidthDiskCache: 600,
                maxHeightDiskCache: 340,
                placeholder:
                    (context, url) => Container(
                      color: CupertinoColors.systemGrey6,
                      child: const Center(child: CupertinoActivityIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: CupertinoColors.systemGrey6,
                      child: const Icon(
                        CupertinoIcons.photo,
                        size: 60,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
              ),
            ),
          ),
          // Conteúdo do card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Título e descrição
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botões Call to Action
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          // TODO: Implementar ação do botão
                        },
                        child: const Text(
                          'PLAY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: const Color(0xFFFF9500), // Laranja (systemOrange)
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          // TODO: Implementar ação do botão curtir
                        },
                        child: const Text(
                          'DETALHES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: const Color(0xFF2D7A3E), // Verde escuro
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          // TODO: Implementar ação do botão de crédito
                        },
                        child: const Text(
                          'AUTORIA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton loader para lista completa (carregamento inicial)
  Widget _buildSkeletonGrid() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: 4, // Mostra 4 skeletons placeholder
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildSkeletonCardContent(),
          );
        },
      ),
    );
  }

  /// Skeleton loader para um único card (carregamento incremental)
  Widget _buildSkeletonCard() {
    return Skeletonizer(enabled: true, child: _buildSkeletonCardContent());
  }

  /// Conteúdo do skeleton card (reutilizável)
  Widget _buildSkeletonCardContent() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skeleton da imagem
          const Bone.square(
            size: 280,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          // Skeleton do conteúdo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Bone.text(words: 3, fontSize: 18),
                const SizedBox(height: 8),
                const Bone.text(words: 5, fontSize: 14),
                const SizedBox(height: 16),
                // Skeleton do botão
                Bone.button(
                  width: double.infinity,
                  height: 50,
                  borderRadius: BorderRadius.circular(25),
                ),
              ],
            ),
          ),
        ],
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
                  await viewModel.applyManualFilter(
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
                  await viewModel.applyManualFilter(
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
                  await viewModel.applyManualFilter(
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
                  await viewModel.applyManualFilter(
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
                  await viewModel.applyManualFilter(
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
                  await viewModel.applyManualFilter(
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
                  await viewModel.resetToRandomMode();
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
              child: const Text('Cancelar'),
            ),
          ),
    );
  }

  /// Widget do botão flutuante para resetar filtro
  Widget _buildResetFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await viewModel.resetToRandomMode();
        if (context.mounted) {
          _showResetMessage(
            context,
            '🔄 Filtragem Manual Removida!\n Modo Padrão Ativado!',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.darkBackgroundGray.withValues(
            alpha: 0.25,
            red: 0.95,
            green: 0.85,
            blue: 0.85,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.darkBackgroundGray.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: CupertinoColors.white.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.clear_circled_solid,
              color: CupertinoColors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              viewModel.currentSortCriteria?.displayName ?? 'Filtro',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe mensagem de confirmação de reset
  void _showResetMessage(BuildContext context, String message) {
    if (!mounted) return; // Proteção contra widget já descartado

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

    // Auto-fechar após 1.5 segundos com proteções
    _dialogTimer?.cancel(); // Cancela timer anterior se existir
    _dialogTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return; // Verifica se widget ainda existe
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          // Ignora erro se dialog já foi fechado
          if (kDebugMode) {
            debugPrint('⚠️ Dialog já foi fechado: $e');
          }
        }
      }
    });
  }
}

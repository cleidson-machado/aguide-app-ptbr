import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TopicViewerByUserScreen extends StatefulWidget {
  const TopicViewerByUserScreen({super.key});

  @override
  State<TopicViewerByUserScreen> createState() => _TopicViewerByUserScreenState();
}

class _TopicViewerByUserScreenState extends State<TopicViewerByUserScreen>
    with AutomaticKeepAliveClientMixin {
  final MainContentTopicViewModel viewModel =
      injector<MainContentTopicViewModel>();
  late ScrollController _scrollController;
  Timer? _debounce; // Timer para debounce na busca

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
            "📜 [_TopicViewerByUserScreenState] Scroll trigger: carregando próxima página",
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
        transitionBetweenRoutes: false,
        middle: const Text("| Meus Videos Criados |"),
        trailing: GestureDetector(
          onTap: () {
            _popUpHandler(context);
          },
          child: const Icon(CupertinoIcons.globe, size: 24),
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
              animation: viewModel,
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
    if (viewModel.isLoading) {
      // Skeleton loader para carregamento inicial
      return _buildSkeletonList();
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(
          viewModel.errorMessage ?? 'Erro desconhecido',
          style: const TextStyle(color: CupertinoColors.systemRed),
        ),
      );
    }

    if (viewModel.contents.isEmpty) {
      return const Center(child: Text("Nenhum conteúdo encontrado."));
    }

    // CustomScrollView permite usar CupertinoSliverRefreshControl (pull-to-refresh nativo iOS)
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Se for o último item e estamos carregando, mostrar skeleton loader
                if (index == viewModel.contents.length) {
                  return _buildSkeletonCard();
                }

                final content = viewModel.contents[index];
                return Column(
                  // Key única baseada no ID do conteúdo para otimizar rebuilds
                  // Permite que o Flutter identifique e reutilize widgets corretamente
                  key: ValueKey('content_${content.id}'),
                  children: [
                    _buildBlogCard(content),
                    const Divider(color: CupertinoColors.systemGrey4),
                  ],
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

  Widget _buildBlogCard(MainContentTopicModel content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  content
                      .description, // Usando description no lugar de subtitle
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: content.videoThumbnailUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              // Redimensiona em memória para 160x160 (2x para telas retina)
              memCacheWidth: 160,
              memCacheHeight: 160,
              // Redimensiona no cache de disco para economizar espaço
              maxWidthDiskCache: 160,
              maxHeightDiskCache: 160,
              // Placeholder enquanto carrega (atividade indicator nativo iOS)
              placeholder:
                  (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: CupertinoColors.systemGrey5,
                    child: const Center(child: CupertinoActivityIndicator()),
                  ),
              // Widget de erro mantido igual ao original
              errorWidget:
                  (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: CupertinoColors.systemGrey5,
                    child: const Icon(
                      CupertinoIcons.photo,
                      color: CupertinoColors.white,
                    ),
                  ),
            ),
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
          return Column(
            children: [
              _buildSkeletonCardContent(),
              const Divider(color: CupertinoColors.systemGrey4),
            ],
          );
        },
      ),
    );
  }

  /// Skeleton loader para um único card (carregamento incremental)
  Widget _buildSkeletonCard() {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          _buildSkeletonCardContent(),
          const Divider(color: CupertinoColors.systemGrey4),
        ],
      ),
    );
  }

  /// Conteúdo do skeleton card (reutilizável)
  Widget _buildSkeletonCardContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 3, fontSize: 16),
                SizedBox(height: 4),
                Bone.text(words: 6, fontSize: 14),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Bone.square(size: 80, borderRadius: BorderRadius.circular(8)),
        ],
      ),
    );
  }

  Future<dynamic> _popUpHandler(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Text(
              AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
            ),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('pt', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'BR',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languagePortuguese ??
                          'Portuguese',
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('en', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'US',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languageEnglish ??
                          'English',
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('es', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'ES',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languageSpanish ??
                          'Spanish',
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('fr', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'FR',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languageFrench ?? 'French',
                    ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
          ),
    );
  }
}

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        transitionBetweenRoutes: false,
        middle: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Guia - PORTUGAL",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 6),
            Text(
              "| TEMAS - Perfil Consumidor de Conteúdo |",
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
      child: ListenableBuilder(
        listenable: viewModel,
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
                // Widget isolado com key única para evitar cache de estado visual
                return MainContentCard(
                  key: ValueKey('card_${content.id}_${content.validationHash ?? "null"}'),
                  content: content,
                  viewModel: viewModel,
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

  /// Widget do botão de validação de autoria
  /// ✅ CORRIGIDO: Renderização individual e isolada por item
  static Widget _buildValidationButton(MainContentTopicModel content) {
    // ✅ DEBUG: Log do validationHash para verificar valores
    if (kDebugMode) {
      debugPrint(
        '🔍 [ValidationButton] ID: ${content.id}, validationHash: ${content.validationHash ?? "NULL"}',
      );
    }

    // Determina cor e texto baseado no validationHash
    // ✅ REGRA: validationHash != null → AZUL (Autoria Reconhecida)
    // ✅ REGRA: validationHash == null → VERMELHO (Sem Autoria)
    final bool hasValidation = content.validationHash != null && 
                               content.validationHash!.trim().isNotEmpty;
    final Color buttonColor = hasValidation 
        ? const Color(0xFF1565C0)  // ✅ Azul para validado
        : const Color(0xFFB71C1C); // ✅ Vermelho para não validado
    final String buttonText = hasValidation
        ? 'VIDEO OU CANAL - COM AUTORIA RECONHECIDA!'
        : 'ESTE VÍDEO É SEU? MONETIZE AGORA MESMO!';

    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        color: buttonColor,
        borderRadius: BorderRadius.circular(5),
        onPressed: () {
          // TODO: Implementar ação de validação de autoria
          if (kDebugMode) {
            debugPrint(
              '🎯 [ValidationButton] Clicado - ID: ${content.id}, hasValidation: $hasValidation',
            );
          }
        },
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static Widget _buildContentCard(
    MainContentTopicModel content,
    MainContentTopicViewModel viewModel,
  ) {
    return Container(
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
                imageUrl: content.videoThumbnailUrl,
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
          // Botão de destaque - Validação de Autoria (Dinâmico)
          _MainContentTopicScreenState._buildValidationButton(content),
          // Conteúdo do card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
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
                    const SizedBox(height: 10),
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
              ],
            ),
          ),
          // Botões de ação - ToggleButtons fora do padding principal
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calcula largura disponível e divide por 3 botões
                final buttonWidth = (constraints.maxWidth - 6) / 3; // -6 para compensar borders
                return Center(
                  child: ToggleButtons(
                    isSelected: viewModel.getToggleButtonState(content.id),
                    onPressed: (int index) {
                      // Atualiza estado no ViewModel (individualizado por item)
                      viewModel.updateToggleButtonState(content.id, index);
                      
                      // Ações baseadas no botão selecionado
                      switch (index) {
                        case 0:
                          // TODO: Implementar ação de PLAY
                          if (kDebugMode) debugPrint('🎬 PLAY selecionado - Item: ${content.id}');
                          break;
                        case 1:
                          // Exibe modal de detalhes
                          if (kDebugMode) debugPrint('📋 DETALHES selecionado - Item: ${content.id}');
                          _MainContentTopicScreenState._showDetailsActionSheet(context, content);
                          break;
                        case 2:
                          // Exibe modal de autoria
                          if (kDebugMode) debugPrint('✍️ AUTORIA selecionado - Item: ${content.id}');
                          _MainContentTopicScreenState._showAuthorshipActionSheet(context, content);
                          break;
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    borderWidth: 1.5,
                    selectedColor: CupertinoColors.white,
                    fillColor: const Color(0xFFE57373),
                    color: const Color(0xFFE57373),
                    borderColor: const Color(0xFFE0E0E0),
                    selectedBorderColor: const Color(0xFFE57373),
                    constraints: BoxConstraints(
                      minHeight: 28,
                      minWidth: buttonWidth,
                      maxWidth: buttonWidth,
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'PLAY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'DETALHES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'AUTORIA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe modal de detalhes com informações sobre o conteúdo
  static Future<dynamic> _showDetailsActionSheet(
    BuildContext context,
    MainContentTopicModel content,
  ) {
    // ✅ RESPONSIVIDADE: Calcular altura máxima baseada na tela
    final screenHeight = MediaQuery.of(context).size.height;
    final maxModalHeight = screenHeight * 0.6; // 60% da altura da tela
    
    return showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            content.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB71C1C),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        //YYYYY Conteúdo scrollável com informações dinâmicas
        message: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxModalHeight,
            minHeight: 200, // Altura mínima garantida
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: content.videoThumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 160,
                        color: CupertinoColors.systemGrey6,
                        child: const Center(child: CupertinoActivityIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 160,
                        color: CupertinoColors.systemGrey6,
                        child: const Icon(CupertinoIcons.photo, size: 60),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Descrição com "mostrar mais/menos"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ExpandableDescription(description: content.description),
                ),
                const SizedBox(height: 20),
                
                // Divisor
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 1,
                  color: CupertinoColors.systemGrey5,
                ),
                const SizedBox(height: 20),
                
                // Informações do canal e categoria
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildInfoRow(
                    icon: CupertinoIcons.person_circle_fill,
                    label: 'Canal',
                    value: content.channelName,
                    iconColor: const Color(0xFFE57373),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildInfoRow(
                    icon: CupertinoIcons.folder_fill,
                    label: 'Categoria',
                    value: content.categoryName,
                    iconColor: const Color(0xFF64B5F6),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Duração e data
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          icon: CupertinoIcons.time,
                          label: 'Duração',
                          value: _formatDuration(content.durationSeconds),
                          iconColor: const Color(0xFF81C784),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoRow(
                          icon: CupertinoIcons.calendar,
                          label: 'Publicado',
                          value: _formatDate(content.publishedAt),
                          iconColor: const Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Métricas de engajamento
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF3E5F5), Color(0xFFE1F5FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'MÉTRICAS DE ENGAJAMENTO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.systemGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Seção de Tags
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TAGS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.systemGrey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Tags (se houver) ou aviso (se não houver)
                      if (content.tags != null && content.tags!.trim().isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: content.tags!
                              .split(',')
                              .map((tag) => Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 200, // Largura máxima para cada tag
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF90CAF9),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tag.trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ))
                              .toList(),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFB74D),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.tag,
                                size: 18,
                                color: Color(0xFFEF6C00),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Nenhuma tag disponível para este conteúdo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF6C00).withValues(alpha: 0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Informações técnicas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE1F5FE), Color(0xFFF3E5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'INFORMAÇÕES TÉCNICAS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.systemGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTechInfo(
                              icon: CupertinoIcons.play_rectangle_fill,
                              value: content.type,
                              label: 'Tipo',
                              color: const Color(0xFF7E57C2),
                            ),
                            Container(width: 1, height: 40, color: CupertinoColors.systemGrey4),
                            _buildTechInfo(
                              icon: CupertinoIcons.tv_fill,
                              value: content.definition.toUpperCase(),
                              label: 'Qualidade',
                              color: content.definition.toLowerCase() == 'hd'
                                  ? const Color(0xFF26A69A)
                                  : const Color(0xFFBDBDBD),
                            ),
                            Container(width: 1, height: 40, color: CupertinoColors.systemGrey4),
                            _buildTechInfo(
                              icon: CupertinoIcons.textformat,
                              value: content.caption ? 'SIM' : 'NÃO',
                              label: 'Legendas',
                              color: content.caption 
                                  ? const Color(0xFFFF7043)
                                  : const Color(0xFFBDBDBD),
                            ),
                          ],
                        ),
                        if (content.defaultLanguage != null || content.defaultAudioLanguage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                if (content.defaultLanguage != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.globe,
                                          size: 14,
                                          color: Color(0xFF5C6BC0),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Idioma: ${content.defaultLanguage}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF5C6BC0),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (content.defaultAudioLanguage != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.speaker_2_fill,
                                          size: 14,
                                          color: Color(0xFF66BB6A),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Áudio: ${content.defaultAudioLanguage}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF66BB6A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status de validação
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: content.validationHash != null && content.validationHash!.isNotEmpty
                          ? const Color(0xFFE3F2FD)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: content.validationHash != null && content.validationHash!.isNotEmpty
                            ? const Color(0xFF1565C0)
                            : const Color(0xFFB71C1C),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          content.validationHash != null && content.validationHash!.isNotEmpty
                              ? CupertinoIcons.checkmark_seal_fill
                              : CupertinoIcons.exclamationmark_triangle_fill,
                          color: content.validationHash != null && content.validationHash!.isNotEmpty
                              ? const Color(0xFF1565C0)
                              : const Color(0xFFB71C1C),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            content.validationHash != null && content.validationHash!.isNotEmpty
                                ? 'Vídeo com Autoria Reconhecida e Validada'
                                : 'Vídeo sem validação de autoria reconhecida',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: content.validationHash != null && content.validationHash!.isNotEmpty
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFFB71C1C),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        //YYYYY
        
        // Botão de compartilhar como action
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar compartilhamento
              if (kDebugMode) {
                debugPrint('📤 Compartilhar Conteúdo');
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share, size: 20, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text(
                  'Compartilhar',
                  style: TextStyle(color: CupertinoColors.activeBlue),
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

  /// Exibe modal de autoria com opções de validação e monetização
  static Future<dynamic> _showAuthorshipActionSheet(
    BuildContext context,
    MainContentTopicModel content,
  ) {
    return showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(
          'Validação de Autoria',
          style: TextStyle(fontSize: 14),
        ),
        message: const Text(
          'Escolha uma opção para validar ou monetizar este conteúdo',
          style: TextStyle(fontSize: 12),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar validação de autoria
              if (kDebugMode) {
                debugPrint('🔐 Validar Autoria - Conteúdo ID: ${content.id}');
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.checkmark_seal_fill, size: 20),
                SizedBox(width: 8),
                Text('Validar Autoria'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar monetização
              if (kDebugMode) {
                debugPrint('💰 Monetizar Conteúdo - ID: ${content.id}');
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.money_dollar_circle_fill, size: 20),
                SizedBox(width: 8),
                Text('Monetizar Agora'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar visualização de detalhes
              if (kDebugMode) {
                debugPrint('📋 Ver Detalhes - Conteúdo ID: ${content.id}');
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.info_circle_fill, size: 20),
                SizedBox(width: 8),
                Text('Ver Detalhes de Autoria'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar reivindicação de direitos
              if (kDebugMode) {
                debugPrint('⚖️ Reivindicar Direitos - ID: ${content.id}');
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.hand_raised_fill, size: 20),
                SizedBox(width: 8),
                Text('Reivindicar Direitos'),
              ],
            ),
          ),
          if (content.validationHash != null && content.validationHash!.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implementar compartilhamento de certificado
                if (kDebugMode) {
                  debugPrint('📤 Compartilhar Certificado - ID: ${content.id}');
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.share, size: 20, color: CupertinoColors.activeBlue),
                  SizedBox(width: 8),
                  Text(
                    'Compartilhar Certificado',
                    style: TextStyle(color: CupertinoColors.activeBlue),
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

  /// Formata duração em segundos para formato legível (ex: 10:25, 1:30:45)
  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${secs}s';
    }
  }

  /// Formata data ISO 8601 para formato legível (ex: 22 Fev 2026)
  static String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Formata números grandes (ex: 1.5M, 250K, 1.2K)
  static String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// Constrói linha de informação com ícone e texto
  static Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói widget de métrica com ícone, valor e label
  static Widget _buildMetric({
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

  /// Constrói widget de informação técnica com ícone, valor e label
  static Widget _buildTechInfo({
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

/// ✅ Widget Isolado para Card de Conteúdo
/// Separado do State principal para evitar rebuilds massivos causados por AnimatedBuilder
/// Cada card só reconstrói quando seus próprios dados (content) mudam
class MainContentCard extends StatelessWidget {
  final MainContentTopicModel content;
  final MainContentTopicViewModel viewModel;

  const MainContentCard({
    super.key,
    required this.content,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ DEBUG: Log de renderização para verificar rebuilds desnecessários
    if (kDebugMode) {
      debugPrint(
        '🎨 [MainContentCard] Renderizando card ID: ${content.id}, validationHash: ${content.validationHash ?? "NULL"}',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _MainContentTopicScreenState._buildContentCard(content, viewModel),
    );
  }
}

/// Widget de descrição expansível com "mostrar mais/menos"
/// Limita a 5 linhas quando recolhido e expande completamente quando solicitado
class _ExpandableDescription extends StatefulWidget {
  final String description;

  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.description,
          style: const TextStyle(
            fontSize: 15,
            color: CupertinoColors.systemGrey,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: _isExpanded ? null : 5,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? '( mostrar menos )' : '( mostrar mais )',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_exception.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';
import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_option.dart';
import 'package:portugal_guide/features/user_engagement/user_engagement_model.dart';
import 'package:portugal_guide/features/user_engagement/user_engagement_repository_interface.dart';
import 'package:portugal_guide/util/ip_service.dart';
import 'package:portugal_guide/util/metadata_collector.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class MainContentTopicScreen extends StatefulWidget {
  const MainContentTopicScreen({super.key});

  @override
  State<MainContentTopicScreen> createState() => _MainContentTopicScreenState();
}

class _MainContentTopicScreenState extends State<MainContentTopicScreen>
    with AutomaticKeepAliveClientMixin {
  final MainContentTopicViewModel viewModel =
      injector<MainContentTopicViewModel>();
  final AuthTokenManager _tokenManager = injector<AuthTokenManager>();
  late ScrollController _scrollController;
  Timer? _debounce; // Timer para debounce na busca
  Timer? _dialogTimer; // Timer para auto-fechar dialog
  double _savedScrollPosition = 0.0; // ✅ Posição do scroll antes de navegar

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
    // 🆕 Carrega os detalhes do usuário para determinar CRIADOR/CONSUMIDOR
    _loadUserDetails();
  }

  /// 🆕 Carrega os detalhes do usuário via API para determinar se é CRIADOR ou CONSUMIDOR
  Future<void> _loadUserDetails() async {
    final userId = _tokenManager.getUserId();
    if (userId != null && userId.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════════╗');
        debugPrint('║  👤 INICIANDO CARREGAMENTO DE USER DETAILS                         ║');
        debugPrint('╚════════════════════════════════════════════════════════════════════╝');
        debugPrint('   🆔 UserId: $userId');
        debugPrint('   📍 Origem: MainContentTopicScreen.initState()');
        debugPrint('───────────────────────────────────────────────────────────────────');
      }
      
      await viewModel.loadUserDetails(userId);
      
      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════════╗');
        debugPrint('║  🔄 USER DETAILS CARREGADO - ESTADO ATUAL DO VIEWMODEL             ║');
        debugPrint('╚════════════════════════════════════════════════════════════════════╝');
        debugPrint('   📊 userDetails: ${viewModel.userDetails != null ? "CARREGADO" : "NULL"}');
        debugPrint('   🎯 isContentCreator: ${viewModel.isContentCreator}');
        debugPrint('   🏷️  topicHeaderLabel: "${viewModel.topicHeaderLabel}"');
        debugPrint('   👤 userName: "${viewModel.userName}"');
        debugPrint('───────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️  [MainContentTopicScreen] UserId não disponível - não é possível carregar user details');
      }
    }
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

  /// ✅ Salva a posição atual do scroll antes de navegar
  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.position.pixels;
      if (kDebugMode) {
        debugPrint('💾 [MainContentTopicScreen] Scroll salvo: $_savedScrollPosition');
      }
    }
  }

  /// ✅ Restaura a posição do scroll após voltar da navegação
  Future<void> _restoreScrollPosition() async {
    // Aguarda o frame ser renderizado completamente
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (_scrollController.hasClients && _savedScrollPosition > 0) {
      // Usa animação suave para melhor UX
      await _scrollController.animateTo(
        _savedScrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
      if (kDebugMode) {
        debugPrint('✅ [MainContentTopicScreen] Scroll restaurado: $_savedScrollPosition');
      }
    }
  }

  /// ✅ Navega para o wizard preservando o estado do scroll
  Future<void> _navigateToWizardPreservingScroll() async {
    _saveScrollPosition();
    
    if (kDebugMode) {
      debugPrint('🚀 [MainContentTopicScreen] Navegando para wizard...');
    }
    
    // ╔════════════════════════════════════════════════════════════════════════════╗
    // ║  🎯 INICIA O FLUXO: IMAGE SLIDER → WIZARD DE VERIFICAÇÃO                   ║
    // ║                                                                            ║
    // ║  1️⃣ Image Slider (Promo): user_promo_main_contents_screen.dart            ║
    // ║     - 3 páginas com imagens promocionais                                   ║
    // ║     - Ao finalizar, navega automaticamente para o wizard                   ║
    // ║                                                                            ║
    // ║  2️⃣ Wizard (Verificação): user_verified_content_wizard_screen.dart        ║
    // ║     - 3 etapas com formulários                                             ║
    // ║     - Ocupa tela inteira, fora do padrão de navegação por Tabs            ║
    // ╚════════════════════════════════════════════════════════════════════════════╝
    // Navega primeiro para o Image Slider (que depois abre o wizard)
    await Modular.to.pushNamed(AppRoutes.userPromoSlider);
    
    if (kDebugMode) {
      debugPrint('🔙 [MainContentTopicScreen] Retornou do wizard');
    }
    
    // Restaura scroll após voltar
    await _restoreScrollPosition();
  }

  @override
  Widget build(BuildContext context) {
    // OBRIGATÓRIO: chama super.build() para AutomaticKeepAliveClientMixin funcionar
    super.build(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        backgroundColor: CupertinoColors.systemGroupedBackground, // ✅ Força cor fixa (cinza claro iOS)
        border: null, // ✅ Remove borda que aparece com scroll
        middle: const Text(
          "Guia - PORTUGAL",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                  // 🆕 Header com animação de texto dinâmico (CRIADOR/CONSUMIDOR)
                  // ✅ Key única força reconstrução da animação quando viewModel muda
                  Container(
                    key: ValueKey('header_${viewModel.isContentCreator}_${viewModel.userName}'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      height: 24, // ✅ Altura adequada para a animação
                      child: Center(
                        child: AnimatedTextKit(
                          key: ValueKey('anim_${viewModel.isContentCreator}_${viewModel.userName}_${DateTime.now().millisecondsSinceEpoch}'),
                          animatedTexts: [
                            RotateAnimatedText(
                              viewModel.topicHeaderLabel, // ✅ Dinâmico: CRIADOR ou CONSUMIDOR
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.systemPink,
                              ),
                              textAlign: TextAlign.center,
                              rotateOut: false, // ✅ Sem rotação de saída
                              duration: const Duration(milliseconds: 800), // ✅ Duração da animação de entrada
                            ),
                            if (viewModel.userName.isNotEmpty)
                              RotateAnimatedText(
                                "Bem-Vindo - ${viewModel.userName}!", // ✅ Usa nome da API
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.systemPink,
                                ),
                                textAlign: TextAlign.center,
                                rotateOut: false, // ✅ Sem rotação de saída
                                duration: const Duration(milliseconds: 800), // ✅ Duração da animação de entrada
                              ),
                          ],
                          repeatForever: true,
                          pause: const Duration(milliseconds: 15000), // 15 segundos pausado
                          displayFullTextOnTap: false,
                          stopPauseOnTap: false,
                          isRepeatingAnimation: true,
                          totalRepeatCount: 999999, // Loop infinito
                        ),
                      ),
                    ),
                  ),
                  // Campo de busca
                  Container(
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
                        placeholder: 'Pesquisar',
                        onChanged: _onSearchChanged, // Usa handler com debounce
                      ),
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
      // ✅ NOVO: UI amigável para erros
      return _buildErrorView(viewModel.error!, viewModel.isAuthError);
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
                  onNavigateToWizard: _navigateToWizardPreservingScroll, // ✅ Passa callback
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 HANDLER DE VALIDAÇÃO DE AUTORIA VIA POST
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handler que executa validação POST ao clicar no botão VERMELHO
  /// 
  /// Fluxo:
  /// 1. Exibe modal de loading
  /// 2. Chama API POST /api/v1/ownership/validate
  /// 3. Fecha loading e exibe resultado (VERIFIED ou REJECTED)
  /// 4. Se VERIFIED, recarrega lista para atualizar cor do botão
  /// 5. Se REJECTED, oferece opção de "REGISTRO AVANÇADO" para wizard
  static Future<void> _handleValidationPost(
    BuildContext context,
    String contentId,
    MainContentTopicViewModel viewModel,
    VoidCallback onNavigateToWizard, {
    bool isRetry = false, // 🆕 Se é retry, usa spinner mais rápido
  }) async {
    if (kDebugMode) {
      debugPrint('🚀 [_handleValidationPost] Iniciando validação POST');
      debugPrint('   Content ID: $contentId');
      debugPrint('   Is Retry: $isRetry');
    }

    // Verificar se context está válido antes de iniciar
    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint('❌ [_handleValidationPost] Context não montado, abortando');
      }
      return;
    }

    // 1️⃣ Exibir modal de loading (rápido para retry, normal para primeira vez)
    if (isRetry) {
      // Spinner rápido para retry (sem texto descritivo, só spinner)
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CupertinoActivityIndicator(
            radius: 20,
            color: CupertinoColors.activeBlue,
          ),
        ),
      );
    } else {
      _showValidationLoadingDialog(context);
    }

    // Delay reduzido para retry (300ms) vs normal (800ms)
    final delayDuration = isRetry 
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 800);
    
    await Future.delayed(delayDuration);

    try {
      // 2️⃣ Chamar API POST /api/v1/ownership/validate
      final response = await viewModel.validateOwnershipViaPost(contentId);

      if (kDebugMode) {
        debugPrint('📦 [_handleValidationPost] Response recebido: ${response.status}');
      }

      // 3️⃣ Fechar loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (kDebugMode) {
          debugPrint('✅ [_handleValidationPost] Loading dialog fechado');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  [_handleValidationPost] Context não montado, não pode fechar loading');
        }
        return;
      }

      // Pequeno delay para transição visual
      await Future.delayed(const Duration(milliseconds: 200));

      if (!context.mounted) {
        if (kDebugMode) {
          debugPrint('⚠️  [_handleValidationPost] Context não montado após delay');
        }
        return;
      }

      // 4️⃣ Exibir modal de resultado
      _showValidationResultDialog(
        context,
        response,
        onNavigateToWizard: onNavigateToWizard, // 🆕 Passa callback para wizard
        onDismiss: () {
          // 5️⃣ Se VERIFIED, recarregar lista para atualizar UI
          if (response.isVerified) {
            if (kDebugMode) {
              debugPrint('✅ [_handleValidationPost] Recarregando lista após validação');
            }
            viewModel.refreshContents();
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [_handleValidationPost] Erro capturado: $e');
      }

      // Fechar loading dialog em caso de erro
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          if (kDebugMode) {
            debugPrint('✅ [_handleValidationPost] Loading dialog fechado (erro)');
          }
        } catch (navError) {
          if (kDebugMode) {
            debugPrint('⚠️  [_handleValidationPost] Erro ao fechar loading: $navError');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('❌ [_handleValidationPost] Erro: $e');
      }

      // Exibir erro ao usuário
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Color(0xFFEF5350),
                  size: 28,
                ),
                SizedBox(width: 8),
                Text('Erro na Validação'),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════

  /// Widget do botão de validação de autoria
  /// ✅ CORRIGIDO: Renderização individual e isolada por item
  /// ✅ PRESERVA SCROLL: Recebe callback para navegação que preserva posição
  /// 🆕 VALIDAÇÃO POST: Agora chama API de validação ao clicar no botão VERMELHO
  static Widget _buildValidationButton(
    BuildContext context,
    MainContentTopicModel content,
    MainContentTopicViewModel viewModel, // 🆕 Adicionado para chamar validação POST
    VoidCallback onNavigateToWizard, // ✅ Callback para navegação
  ) {
    // ✅ DEBUG: Log do validationHash para verificar valores
    if (kDebugMode) {
      debugPrint(
        '🔍 [ValidationButton] ID: ${content.id}, validationHash: ${content.validationHash ?? "NULL"}',
      );
    }

    // Determina cor e texto baseado no validationHash
    // ✅ REGRA: validationHash != null → AZUL (Autoria Reconhecida)
    // ✅ REGRA: validationHash == null → VERMELHO (Sem Autoria)
    final bool hasValidation = content.validationHash != null && content.validationHash!.trim().isNotEmpty;
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
          if (hasValidation) {
            // ✅ Botão AZUL: Mostra modal informativo (já validado)
            _showValidatedContentDialog(context, content);
          } else {
            // 🆕 Botão VERMELHO: Chama validação POST
            if (kDebugMode) {
              debugPrint(
                '🔐 [ValidationButton] Iniciando validação POST - ID: ${content.id}',
              );
            }
            _handleValidationPost(
              context,
              content.id,
              viewModel,
              onNavigateToWizard, // 🆕 Passa callback para wizard
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

  /// Exibe modal informativo para conteúdo já validado
  static void _showValidatedContentDialog(
    BuildContext context,
    MainContentTopicModel content,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: Color(0xFF1565C0),
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Conteúdo Validado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Este conteúdo já está vinculado e validado como pertencente ao criador.',
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Benefícios Ativos:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitRow('Autoria reconhecida publicamente'),
                  _buildBenefitRow('Monetização ativa'),
                  _buildBenefitRow('Suporte prioritário'),
                  _buildBenefitRow('Estatísticas detalhadas'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para exibir itens de benefício
  static Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: Color(0xFF4CAF50),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContentCard(
    BuildContext context,
    MainContentTopicModel content,
    MainContentTopicViewModel viewModel,
    VoidCallback onNavigateToWizard, // ✅ Callback para navegação
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
          // 🆕 Agora chama validação POST ao clicar (botão VERMELHO)
          _MainContentTopicScreenState._buildValidationButton(
            context, 
            content,
            viewModel, // 🆕 Passa viewModel para chamar validação POST
            onNavigateToWizard, // ✅ Repassa callback
          ),
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
                          // ✅ PLAY: Registra engagement antes de reproduzir
                          if (kDebugMode) debugPrint('🎬 PLAY selecionado - Item: ${content.id}');
                          
                          // Logar engajamento (HISTÓRICO DE VÍDEOS NAVEGADOS)
                          _MainContentTopicScreenState._logEngagementStatic(
                            context,
                            contentId: content.id,
                            contentTitle: content.title,
                            engagementType: UserEngagementType.clickToView,
                            source: 'home',
                          );
                          
                          // TODO: Implementar reprodução do vídeo
                          break;
                        case 1:
                          // ✅ DETALHES: Registra engagement ao visualizar detalhes
                          if (kDebugMode) debugPrint('📋 DETALHES selecionado - Item: ${content.id}');
                          
                          // Logar engajamento como PARTIAL_VIEW
                          _MainContentTopicScreenState._logEngagementStatic(
                            context,
                            contentId: content.id,
                            contentTitle: content.title,
                            engagementType: UserEngagementType.partialView,
                            source: 'home',
                          );
                          
                          _MainContentTopicScreenState._showDetailsActionSheet(context, content);
                          break;
                        case 2:
                          // ✅ AUTORIA: Registra engagement ao verificar autoria
                          if (kDebugMode) debugPrint('✍️ AUTORIA selecionado - Item: ${content.id}');
                          
                          // Logar engajamento como PARTIAL_VIEW
                          _MainContentTopicScreenState._logEngagementStatic(
                            context,
                            contentId: content.id,
                            contentTitle: content.title,
                            engagementType: UserEngagementType.partialView,
                            source: 'home',
                          );
                          
                          _MainContentTopicScreenState._handleAuthorshipCheck(
                            context,
                            content,
                            viewModel,
                            onNavigateToWizard: onNavigateToWizard,
                          );
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
              fontSize: 16,
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
            minHeight: 250, // Altura mínima garantida
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
                                ? 'Vídeo COM Autoria Reconhecida!'
                                : 'Vídeo SEM autoria reconhecida',
                            style: TextStyle(
                              fontSize: 14,
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
          child: const Text('Sair'),
        ),
      ),
    );
  }

  //YYYYY Conteúdo scrollável com informações dinâmicas -FIM

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 VALIDAÇÃO DE AUTORIA VIA POST (Modals)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Exibe modal de loading durante validação POST
  /// Inclui spinner e mensagem de processamento
  static void _showValidationLoadingDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(radius: 16),
              SizedBox(height: 20),
              Text(
                'Validando autoria...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Aguarde enquanto verificamos seus dados',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exibe modal de resultado da validação (VERIFIED ou REJECTED)
  /// 
  /// [context] - Contexto da tela
  /// [response] - Resposta da API com status e detalhes
  /// [onNavigateToWizard] - Callback para navegar ao wizard de registro avançado
  /// [onDismiss] - Callback executado ao fechar o modal (opcional)
  static void _showValidationResultDialog(
    BuildContext context,
    OwnershipValidationResponse response, {
    VoidCallback? onNavigateToWizard,
    VoidCallback? onDismiss,
  }) {
    final isVerified = response.isVerified;
    final icon = isVerified 
        ? CupertinoIcons.checkmark_seal_fill 
        : CupertinoIcons.xmark_circle_fill;
    final iconColor = isVerified 
        ? const Color(0xFF4CAF50) // Verde
        : const Color(0xFFEF5350); // Vermelho
    final title = isVerified 
        ? '✅ Autoria Confirmada!' 
        : '❌ Autoria Não Confirmada';

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Mensagem da API
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                response.message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Detalhes (condicional baseado no status)
            if (isVerified) ...[
              const SizedBox(height: 16),
              const Text(
                'Benefícios Ativos:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildBenefitRow('Autoria reconhecida publicamente'),
              _buildBenefitRow('Monetização ativa'),
              _buildBenefitRow('Suporte prioritário'),
              _buildBenefitRow('Estatísticas detalhadas'),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Hash de Validação:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      response.validationHash.length > 20
                          ? '${response.validationHash.substring(0, 20)}...'
                          : response.validationHash,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: CupertinoColors.systemGrey2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE), // Vermelho claro
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF5350),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Possíveis motivos:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Canal do YouTube não coincide\n'
                      '• Conteúdo não pertence ao usuário\n'
                      '• Verificação ainda pendente',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              // 🆕 Botão "REGISTRO AVANÇADO" para navegar ao wizard
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: const Color(0xFFB71C1C), // Vermelho escuro
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () {
                    // Fechar modal e navegar para wizard
                    Navigator.of(context).pop();
                    if (onNavigateToWizard != null) {
                      if (kDebugMode) {
                        debugPrint('🚀 [ValidationResult] Navegando para REGISTRO AVANÇADO');
                      }
                      onNavigateToWizard();
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_fill,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'REGISTRO AVANÇADO',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              if (onDismiss != null) onDismiss();
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  
  /// ✅ Helper estático para logar engagement de widgets estáticos
  /// Necessário porque o _buildContentCard é estático e não tem acesso direto aos membros da instância
  static Future<void> _logEngagementStatic(
    BuildContext context, {
    required String contentId,
    required String contentTitle,
    String engagementType = 'CLICK_TO_VIEW',
    String source = 'home',
  }) async {
    try {
      // Buscar instância do repository do injector
      final engagementRepository = injector<UserEngagementRepositoryInterface>();
      final tokenManager = injector<AuthTokenManager>();
      
      // Obter userId do token JWT
      final userId = tokenManager.getUserId();
      
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️  [EngagementTracking] UserId não encontrado - ignorando tracking');
        }
        return;
      }

      // Detectar plataforma
      final platform = Platform.isAndroid ? 'Android' : 'iOS';
      
      // 🆕 Coletar IP público do usuário
      final userIp = await IpService.getPublicIP();
      
      // 📊 Coletar metadados do dispositivo, app e sessão
      final metadata = await MetadataCollector.collectMetadata(
        previousScreen: source,
      );
      final metadataJson = MetadataCollector.toJsonString(metadata);
      
      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════════╗');
        debugPrint('║  📊 ENGAGEMENT TRACKING - Registrando interação do usuário        ║');
        debugPrint('╚════════════════════════════════════════════════════════════════════╝');
        debugPrint('   👤 UserId: $userId');
        debugPrint('   🎬 ContentId: $contentId');
        debugPrint('   📝 Title: $contentTitle');
        debugPrint('   🔖 Type: $engagementType');
        debugPrint('   🏠 Source: $source');
        debugPrint('   📱 Platform: $platform');
        debugPrint('   🌐 User IP: $userIp');
        debugPrint('   📦 Metadata: ${metadata.keys.join(", ")}');
        debugPrint('   ⏰ Timestamp: ${DateTime.now().toIso8601String()}');
        debugPrint('───────────────────────────────────────────────────────────────────');
        
        // Exibir resumo dos metadados coletados
        if (metadata.containsKey('device')) {
          final device = metadata['device'] as Map<String, dynamic>;
          debugPrint('   📦 Device: ${device['model']} - ${device['os']} ${device['osVersion']}');
        }
        if (metadata.containsKey('app')) {
          final app = metadata['app'] as Map<String, dynamic>;
          debugPrint('   📦 App: v${app['version']} (${app['buildNumber']})');
        }
        if (metadata.containsKey('network')) {
          final network = metadata['network'] as Map<String, dynamic>;
          debugPrint('   📦 Network: ${network['connectionType']}');
        }
        if (metadata.containsKey('performance')) {
          final perf = metadata['performance'] as Map<String, dynamic>;
          debugPrint('   📦 Battery: ${perf['batteryLevel']}% (${perf['batteryState']})');
        }
        debugPrint('───────────────────────────────────────────────────────────────────');
      }

      // Criar modelo de engagement
      final engagement = UserEngagementModel(
        userId: userId,
        contentId: contentId,
        engagementType: engagementType,
        engagementStatus: UserEngagementStatus.active,
        repeatCount: 1,
        deviceType: 'mobile',
        platform: platform,
        source: source,
        userIp: userIp,
        metadata: metadataJson,
        engagedAt: DateTime.now(),
      );

      // Enviar para API (não bloqueia a navegação)
      final result = await engagementRepository.createEngagement(engagement);

      if (result != null && kDebugMode) {
        debugPrint('✅ Engagement registrado com sucesso!');
        debugPrint('   🆔 ID gerado: ${result.id}');
        debugPrint('   📊 Status: ${result.engagementStatus}');
        debugPrint('╚════════════════════════════════════════════════════════════════════╝');
        debugPrint('');
      } else if (kDebugMode) {
        debugPrint('⚠️  Falha ao registrar engagement (API pode estar indisponível)');
        debugPrint('╚════════════════════════════════════════════════════════════════════╝');
        debugPrint('');
      }
    } catch (e) {
      // ✅ NÃO bloqueia a navegação do usuário se o tracking falhar
      if (kDebugMode) {
        debugPrint('❌ Erro ao logar engagement: $e');
        debugPrint('╚════════════════════════════════════════════════════════════════════╝');
        debugPrint('');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica ownership e decide se abre modal ou exibe mensagem de alerta
  /// 
  /// [onNavigateToWizard] - Callback para navegar ao wizard de registro avançado
  static Future<void> _handleAuthorshipCheck(
    BuildContext context,
    MainContentTopicModel content,
    MainContentTopicViewModel viewModel, {
    VoidCallback? onNavigateToWizard,
  }) async {
    // Exibir loading enquanto verifica
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(radius: 14),
              SizedBox(height: 16),
              Text(
                'Verificando autoria...',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 📍 PONTO DE CONSUMO DO ENDPOINT: GET /api/v1/ownership/user/{userId}/content
      // Verifica se usuário é dono do conteúdo antes de permitir ações de autoria
      final result = await viewModel.checkContentOwnership(content.id);

      // Fechar loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      if (result.isOwner) {
        // ✅ É DONO: Abrir modal de autoria com dados de ownership
        if (result.contents != null && result.contents!.isNotEmpty) {
          await _showAuthorshipActionSheet(
            context, 
            content,
            result.contents!.first, // Passa dados de ownership
          );
        } else {
          // Fallback: não deveria acontecer, mas trata caso não tenha dados
          _showOwnershipDeniedMessage(
            context,
            'Erro: Dados de ownership não encontrados.',
            onNavigateToWizard: onNavigateToWizard,
            contentId: content.id,
            viewModel: viewModel,
          );
        }
      } else {
        // ❌ NÃO É DONO: Exibir mensagem de alerta
        final message = result.error?.message ?? 
                        'Este conteúdo não pertence ao usuário logado';
        _showOwnershipDeniedMessage(
          context,
          message,
          onNavigateToWizard: onNavigateToWizard,
          contentId: content.id,
          viewModel: viewModel,
        );
      }
    } catch (e) {
      // Fechar loading dialog em caso de erro
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (kDebugMode) {
        debugPrint('❌ [_handleAuthorshipCheck] Erro: $e');
      }

      if (context.mounted) {
        _showOwnershipDeniedMessage(
          context,
          'Erro ao verificar autoria. Tente novamente.',
          onNavigateToWizard: onNavigateToWizard,
          contentId: content.id,
          viewModel: viewModel,
        );
      }
    }
  }

  /// Exibe modal de autoria com opções de validação e monetização
  /// Recebe dados reais do endpoint de ownership para exibir informações verificadas
  static Future<dynamic> _showAuthorshipActionSheet(
    BuildContext context,
    MainContentTopicModel content,
    OwnershipContentModel ownership,
  ) {
    // Formatar data de verificação
    String formattedVerifiedAt = 'N/A';
    try {
      final verifiedDate = DateTime.parse(ownership.verifiedAt);
      formattedVerifiedAt = '${verifiedDate.day}/${verifiedDate.month}/${verifiedDate.year} ${verifiedDate.hour.toString().padLeft(2, '0')}:${verifiedDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erro ao formatar data de verificação: $e');
      }
    }

    // Hash de validação abreviado (primeiros 16 caracteres)
    final shortHash = ownership.validationHash.length > 16 
        ? '${ownership.validationHash.substring(0, 16)}...' 
        : ownership.validationHash;

  //ZZZZ - Modal de autoria com informações reais e opções de ação - INÍCIO
    return showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status de verificação com ícone
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ownership.verified 
                        ? CupertinoIcons.checkmark_seal_fill 
                        : CupertinoIcons.exclamationmark_triangle_fill,
                    color: ownership.verified 
                        ? CupertinoColors.systemGreen 
                        : CupertinoColors.systemOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ownership.verified 
                          ? 'Conteúdo Auditado!' 
                          : 'Verificação Pendente!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ownership.verified 
                            ? CupertinoColors.systemBlue 
                            : CupertinoColors.systemPink,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Canal verificado
              RichText(
                textAlign: TextAlign.center,
                softWrap: true,
                overflow: TextOverflow.visible,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                  children: [
                    const TextSpan(
                      text: 'CANAL: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: CupertinoColors.black,
                      ),
                    ),
                    TextSpan(
                      text: ownership.channelName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        message: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Data de verificação - Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)], //KKKK
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemIndigo,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 42,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'VERIFICADO EM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.systemGrey,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedVerifiedAt,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              
              // Hash de validação - Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)], //KKKK
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemIndigo,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.lock_shield_fill,
                      size: 42,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'HASH DE VALIDAÇÃO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.systemGrey,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortHash,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                        fontFamily: 'Courier',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              
              // ID de ownership - Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)], //KKKK
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemIndigo,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.number_circle_fill,
                      size: 42,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'HASH de PROPRIEDADE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.systemGrey,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ownership.ownershipId.substring(0, 13)}...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                        fontFamily: 'Courier',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              
              // Mensagem de parabéns - Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)], //KKKK
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemIndigo,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      size: 60,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CONTEÚDO CAPITALIZADO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.darkBackgroundGray,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      softWrap: true,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.black,
                          height: 1.6,
                        ),
                        children: [
                          TextSpan(
                            text: 'Este conteúdo é ',
                          ),
                          TextSpan(
                            text: 'PROPRIETÁRIO',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: CupertinoColors.systemPink,
                            ),
                          ),
                          TextSpan(
                            text: '\n e está ',
                          ),
                          TextSpan(
                            text: 'PROTEGIDO ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: CupertinoColors.systemPink,
                            ),
                          ),
                          TextSpan(
                            text: 'por nossa \n tecnologia de validação.\n\n',
                          ),
                          TextSpan(
                            text: 'Você pode gerenciar seus ',
                          ),
                          TextSpan(
                            text: 'GANHOS ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: CupertinoColors.systemPink,
                              letterSpacing: 0.3,
                            ),
                          ),
                          TextSpan(
                            text: 'e os ',
                          ),
                          TextSpan(
                            text: 'DIREITOS AUTORAIS ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: CupertinoColors.systemPink,
                            ),
                          ),
                          TextSpan(
                            text: 'deste conteúdo \n em seu ',
                          ),
                          TextSpan(
                            text: 'painel de controle',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: '.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Sair'),
        ),
      ),
    );
  }
  //ZZZZ - Modal de autoria com informações reais e opções de ação - FIM

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

  /// ✅ NOVO: Widget de erro amigável com suporte a reautenticação
  /// Exibe mensagem clara e ação apropriada baseado no tipo de erro
  Widget _buildErrorView(Exception error, bool isAuthError) {
    final String message = viewModel.errorMessage ?? 'Erro desconhecido';
    final IconData icon = isAuthError 
        ? CupertinoIcons.lock_shield_fill 
        : CupertinoIcons.exclamationmark_triangle_fill;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone do erro
            Icon(
              icon,
              size: 64,
              color: isAuthError 
                  ? CupertinoColors.systemOrange 
                  : CupertinoColors.systemRed,
            ),
            const SizedBox(height: 24),
            
            // Mensagem amigável
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.black,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Botão de ação (reautenticar ou tentar novamente)
            if (isAuthError) ...[
              // Botão de reautenticação para erros de auth
              CupertinoButton.filled(
                onPressed: () {
                  if (kDebugMode) {
                    debugPrint('🔐 [MainContentTopicScreen] Redirecionando para login');
                  }
                  Modular.to.navigate(AppRoutes.login);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.arrow_right_circle_fill),
                    SizedBox(width: 8),
                    Text('Fazer Login Novamente'),
                  ],
                ),
              ),
            ] else ...[
              // Botão de tentar novamente para outros erros
              CupertinoButton.filled(
                onPressed: () {
                  if (kDebugMode) {
                    debugPrint('🔄 [MainContentTopicScreen] Tentando recarregar');
                  }
                  viewModel.refreshContents();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.refresh),
                    SizedBox(width: 8),
                    Text('Tentar Novamente'),
                  ],
                ),
              ),
            ],
            
            // Link de ajuda/suporte (opcional)
            if (error is NetworkException) ...[
              const SizedBox(height: 16),
              const Text(
                'Dica: Verifique sua conexão Wi-Fi ou dados móveis',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
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
              child: const Text('Sair'),
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

  /// Modal de erro para vinculação de conteúdo
  /// Exibe ícone vermelho de erro com mensagem
  /// Auto-fecha após 5 segundos
  static void _showContentLinkageErrorMessage(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🔴 [ERROR MODAL] Tentando exibir modal de erro...');
      debugPrint('🔴 [ERROR MODAL] Context mounted: ${context.mounted}');
    }

    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint('❌ [ERROR MODAL] Context não está montado, abortando');
      }
      return;
    }

    bool isDialogOpen = true; // Flag para controlar se dialog ainda está aberto

    try {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false, // ✅ Desabilita fechar tocando fora (evita erro)
        builder: (BuildContext dialogContext) {
          if (kDebugMode) {
            debugPrint('✅ [ERROR MODAL] Builder executado, criando dialog');
          }
          
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              // Previne fechar com botão voltar
              if (kDebugMode) {
                debugPrint('⚠️ [ERROR MODAL] Tentativa de fechar com back button bloqueada');
              }
            },
            child: const CupertinoAlertDialog(
              title: Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.systemRed,
                size: 48,
              ),
              content: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Vinculação\n Não Realizada com Sucesso!',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        // Callback executado quando dialog é fechado (por qualquer motivo)
        isDialogOpen = false;
        if (kDebugMode) {
          debugPrint('🔴 [ERROR MODAL] Dialog foi fechado (callback .then)');
        }
      });

      if (kDebugMode) {
        debugPrint('✅ [ERROR MODAL] Modal exibida com sucesso');
      }

      // Auto-fechar após 5 segundos com proteção
      Timer(const Duration(milliseconds: 5000), () {
        if (kDebugMode) {
          debugPrint('⏰ [ERROR MODAL] Timer de 5s disparado');
          debugPrint('   isDialogOpen: $isDialogOpen');
          debugPrint('   context.mounted: ${context.mounted}');
        }

        // Só tenta fechar se dialog ainda estiver aberto E context válido
        if (isDialogOpen && context.mounted) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
            isDialogOpen = false; // Marca como fechado
            if (kDebugMode) {
              debugPrint('✅ [ERROR MODAL] Modal fechada automaticamente após 5 segundos');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ [ERROR MODAL] Erro ao fechar: $e');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ [ERROR MODAL] Dialog já foi fechado ou context inválido');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ERROR MODAL] Erro ao exibir modal: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 VALIDAÇÃO RÁPIDA DE RETRY
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🔄 Validação rápida para retry (com animação Lottie)
  /// Exibe animação Lottie por 5 segundos → Mostra modal de confirmação visual
  /// 
  /// ⚠️  NOTA: Por enquanto apenas visual, SEM chamada de API backend
  /// 🔑 Recebe NavigatorState ao invés de BuildContext para evitar problemas de context desativado
  static Future<void> _handleQuickRetryValidation(
    BuildContext context,
    NavigatorState navigator,
    String contentId,
    MainContentTopicViewModel viewModel,
  ) async {
    if (kDebugMode) {
      debugPrint('🔄 [QuickRetry] Iniciando validação visual com Lottie');
      debugPrint('   Content ID: $contentId');
    }

    bool animationShown = false;

    try {
      // 1️⃣ Exibir animação Lottie usando showDialog (fundo transparente)
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.5), // Fundo semi-transparente
        builder: (dialogContext) => PopScope(
          canPop: false, // Impede fechar com back button
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animated/lottie_spinner_001.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ),
        ),
      );
      animationShown = true;

      if (kDebugMode) {
        debugPrint('✅ [QuickRetry] Animação Lottie exibida (showDialog)');
      }

      // 2️⃣ Delay de 5 segundos (animação visual)
      await Future.delayed(const Duration(seconds: 5));

      if (kDebugMode) {
        debugPrint('✅ [QuickRetry] Delay de 5 segundos completo');
      }

      // 3️⃣ Chamar API (COMENTADO - apenas visual por enquanto)
      // response = await viewModel.validateOwnershipViaPost(contentId);
      // if (kDebugMode) {
      //   debugPrint('📦 [QuickRetry] Response recebida: ${response.status}');
      // }
    } finally {
      // 4️⃣ SEMPRE fechar animação (finally garante execução)
      if (animationShown) {
        if (kDebugMode) {
          debugPrint('🔄 [QuickRetry] Fechando animação via navigator.pop()...');
        }

        try {
          // Fechar dialog usando navigator capturado
          navigator.pop();
          if (kDebugMode) {
            debugPrint('✅ [QuickRetry] Animação fechada com sucesso');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ [QuickRetry] Erro ao fechar animação: $e');
          }
        }

        // Delay para garantir que animação de fechamento complete
        await Future.delayed(const Duration(milliseconds: 500));

        if (kDebugMode) {
          debugPrint('✅ [QuickRetry] Delay pós-fechamento completo (500ms)');
        }
      }
    }

    // 5️⃣ Verificar se context ainda está válido antes de mostrar resultado
    // Usar navigator.context que é mais estável que o context do dialog
    final validContext = navigator.context;
    
    if (kDebugMode) {
      debugPrint('🔍 [QuickRetry] Verificando context...');
      debugPrint('   context original.mounted: ${context.mounted}');
      debugPrint('   navigator.context.mounted: ${validContext.mounted}');
    }

    if (!validContext.mounted) {
      if (kDebugMode) {
        debugPrint('⚠️  [QuickRetry] Navigator context não montado após fechar animação');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('✅ [QuickRetry] Context válido, prosseguindo...');
    }

    // 6️⃣ Mostrar modal de erro de vinculação usando context válido
    if (kDebugMode) {
      debugPrint('❌ [QuickRetry] CHAMANDO _showContentLinkageErrorMessage...');
    }

    _showContentLinkageErrorMessage(validContext);

    if (kDebugMode) {
      debugPrint('🏁 [QuickRetry] Fluxo visual completo finalizado');
    }
  }

  /// Exibe mensagem de alerta quando usuário NÃO é dono do conteúdo
  /// Layout melhorado com explicação detalhada e opções de ação
  /// 
  /// [onNavigateToWizard] - Callback para navegar ao wizard de registro avançado
  /// [contentId] - ID do conteúdo para retry de validação POST
  /// [viewModel] - ViewModel para disparar validação POST novamente
  static void _showOwnershipDeniedMessage(
    BuildContext context,
    String message, {
    VoidCallback? onNavigateToWizard,
    String? contentId,
    MainContentTopicViewModel? viewModel,
  }) {
    // Usar mensagem padrão se a mensagem da API for genérica
    final useDefaultMessage = message.contains('não pertence') || 
                              message.contains('not found') ||
                              message.contains('NOT_FOUND');

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Calcular largura proporcional à tela (90% da largura)
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth * 0.9;
        
        return Center(
          child: Container(
            width: dialogWidth,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título com ícone de alerta
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemPink.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          color: CupertinoColors.systemPink,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'AUTORIA de Vinculação Indisponível...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.systemPink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Conteúdo com mensagem explicativa formatada com RichText
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: useDefaultMessage
                      ? RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              // Primeiro parágrafo - Saudação e problema
                              TextSpan(
                                text: 'Olá! Sentimos muito!\n',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.systemBlue
                                ),
                              ),
                              TextSpan(
                                text: 'Nosso sistema não conseguiu associar este conteúdo à sua conta ',
                              ),
                              TextSpan(
                                text: '\n Google / YouTube',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                              TextSpan(text: '.\n\n'),
                              
                              // Segundo parágrafo - Instruções
                              TextSpan(
                                text: 'Por favor, tente novamente fazendo:\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: '• Logout da sua conta atual\n'),
                              TextSpan(text: '• Limpando o cache do aplicativo\n'),
                              TextSpan(text: '• Efetuando um novo login\n\n'),
                              
                              // Terceiro parágrafo - Alternativa
                              TextSpan(
                                text: 'Caso o esse comportamento persista, utilize a opção ',
                              ),
                              TextSpan(
                                text: '\n "REGISTRO AVANÇADO"',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                              TextSpan(
                                text: '\n para que nossa equipe analise novamente, em detalhes, o vínculo desse conteúdo à sua conta.',
                              ),
                            ],
                          ),
                        )
                      : Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: CupertinoColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                
                // Divisor
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator,
                ),
                
                // 🆕 Botão "REGISTRO AVANÇADO" (VERMELHO - Layout atualizado)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: CupertinoButton(
                    color: const Color(0xFFB71C1C), // Vermelho escuro (consistente)
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(10),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (kDebugMode) {
                        debugPrint('🚀 [OwnershipDenied] Navegando para REGISTRO AVANÇADO');
                      }
                      // 🆕 Navegar para wizard (Slider → Wizard)
                      if (onNavigateToWizard != null) {
                        onNavigateToWizard();
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.doc_text_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'REGISTRO AVANÇADO',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Divisor
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator,
                ),
                
                // 🔄 Botão "TENTAR NOVAMENTE" (Degradê Coral → Rosa)
                if (contentId != null && viewModel != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF6B6B), // Coral/vermelho claro
                            Color(0xFFEE5A6F), // Rosa avermelhado
                            Color(0xFFE94B82), // Rosa forte
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          if (kDebugMode) {
                            debugPrint('🔄 [OwnershipDenied] TENTAR NOVAMENTE selecionado');
                          }
                          
                          // 🔑 CRÍTICO: Capturar navigator ANTES de qualquer operação assíncrona
                          final capturedNavigator = Navigator.of(context, rootNavigator: true);
                          final capturedContext = context; // Capturar context também
                          
                          // 1️⃣ Exibir modal intermediária de reautenticação recomendada (SEM fechar a atual)
                          showCupertinoDialog(
                            context: context,
                            barrierDismissible: true, // ✅ Permite fechar tocando fora
                            builder: (dialogContext) {
                              // Largura proporcional
                              final screenWidth = MediaQuery.of(dialogContext).size.width;
                              final dialogWidth = screenWidth * 0.88;
                              
                              return Center(
                                child: Container(
                                  width: dialogWidth,
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 🔴 Título principal (vermelho/rosa)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                                        child: Text(
                                          'AVISO IMPORTANTE!',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: CupertinoColors.systemRed.withOpacity(0.9),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      
                                      // Subtítulo
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                                        child: Text(
                                          'A Validação NÃO SERÁ possível!',  
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: CupertinoColors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // 📋 Conteúdo com instruções
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGrey6,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Center(
                                              child: Text(
                                                'Para melhores resultados,\n siga, exatamente, os passos abaixo:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: CupertinoColors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            
                                            // Lista de passos numerados
                                            _buildStep(
                                              '1. Faça ',
                                              'logout',
                                              ' da sua conta Google ou Local atual.',
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            _buildStep(
                                              '2. ',
                                              'Limpe o cache',
                                              ' do aplicativo (opcional).',
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            _buildStep(
                                              '3. Faça ',
                                              'login novamente',
                                              ', de preferência com uma Conta Google.',
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            _buildStepMultiBold([
                                              {'text': '4. Utilize a ', 'bold': false},
                                              {'text': 'mesma Conta Google', 'bold': true},
                                              {'text': ' que você usa na administração do seu ', 'bold': false},
                                              {'text': 'canal no YouTube', 'bold': true},
                                              {'text': '.', 'bold': false},
                                            ]),
                                            const SizedBox(height: 8),
                                            
                                            _buildStep(
                                              '5. E tente ',
                                              'verificar a autoria',
                                              ' novamente desse conteúdo.',
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Divisor
                                      Container(
                                        height: 0.5,
                                        color: CupertinoColors.separator,
                                      ),
                                      
                                      // 🔵 Botão "Entendi! Vamos tentar!?" (azul link)
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        onPressed: () async {
                                    if (kDebugMode) {
                                      debugPrint('🔄 [Retry] Fechando modals e disparando validação...');
                                      debugPrint('🔄 [Retry] Content ID: $contentId');
                                    }
                                    
                                    // Fechar modal de reautenticação
                                    Navigator.pop(dialogContext);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                    
                                    // Fechar modal principal (Ownership Denied)
                                    capturedNavigator.pop();
                                    await Future.delayed(const Duration(milliseconds: 200));
                                    
                                    // ✅ Verificar se context ainda está válido
                                    if (!capturedContext.mounted) {
                                      if (kDebugMode) {
                                        debugPrint('⚠️ [Retry] Context não montado, abortando validação');
                                      }
                                      return;
                                    }
                                    
                                    // 🆕 NOVO: Passar navigator capturado (válido) ao invés de context
                                    _handleQuickRetryValidation(
                                      capturedContext,
                                      capturedNavigator,
                                      contentId,
                                      viewModel,
                                    );
                                  },
                                        child: const Text(
                                          'Entendi! Vamos tentar assim mesmo!?',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: CupertinoColors.activeBlue,
                                          ),
                                        ),
                                      ),
                                      
                                      // Divisor
                                      Container(
                                        height: 0.5,
                                        color: CupertinoColors.separator,
                                      ),
                                      
                                      // 🔴 Botão "Cancelar" (fecha todas as modals)
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        onPressed: () {
                                          if (kDebugMode) {
                                            debugPrint('❌ [Retry] Cancelar selecionado - fechando todas as modals');
                                          }
                                          
                                          // Fechar modal intermediária
                                          Navigator.pop(dialogContext);
                                          
                                          // Fechar modal principal (Ownership Denied) usando navigator capturado
                                          capturedNavigator.pop();
                                          
                                          if (kDebugMode) {
                                            debugPrint('✅ [Retry] Todas as modals fechadas, retornando à view principal');
                                          }
                                        },
                                        child: const Text(
                                          'Cancelar',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w400,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.refresh_circled_solid,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'TENTAR NOVAMENTE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper para construir linha de passo com texto em negrito (single bold)
  static Widget _buildStep(String prefix, String boldText, String suffix) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 11,
          color: CupertinoColors.black,
          height: 1.5,
        ),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: boldText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: suffix),
        ],
      ),
    );
  }

  /// Helper avançado para construir linha com múltiplos trechos em negrito
  /// 
  /// Aceita lista de Maps com 'text' e 'bold' para cada segmento
  /// Exemplo: [{'text': 'Prefixo ', 'bold': false}, {'text': 'Negrito', 'bold': true}]
  static Widget _buildStepMultiBold(List<Map<String, dynamic>> segments) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 11,
          color: CupertinoColors.black,
          height: 1.5,
        ),
        children: segments.map((segment) {
          final text = segment['text'] as String;
          final isBold = segment['bold'] as bool;
          
          return TextSpan(
            text: text,
            style: isBold 
                ? const TextStyle(fontWeight: FontWeight.w700) 
                : null,
          );
        }).toList(),
      ),
    );
  }
}

/// ✅ Widget Isolado para Card de Conteúdo
/// Separado do State principal para evitar rebuilds massivos causados por AnimatedBuilder
/// Cada card só reconstrói quando seus próprios dados (content) mudam
class MainContentCard extends StatelessWidget {
  final MainContentTopicModel content;
  final MainContentTopicViewModel viewModel;
  final VoidCallback onNavigateToWizard; // ✅ Callback para navegação preservando scroll

  const MainContentCard({
    super.key,
    required this.content,
    required this.viewModel,
    required this.onNavigateToWizard,
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
      child: _MainContentTopicScreenState._buildContentCard(
        context, 
        content, 
        viewModel,
        onNavigateToWizard, // ✅ Repassa callback
      ),
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

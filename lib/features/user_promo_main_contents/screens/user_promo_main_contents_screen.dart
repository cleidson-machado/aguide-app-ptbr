import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';

/// 🎯 Tela de Promoção/Onboarding com 3 Estágios (6 Páginas Internas)
/// 
/// Estrutura: Cada estágio tem 2 páginas com transição automática:
/// 1️⃣ Estágio 1:
///    - Página 1: Imagem abertura + barra progresso (5s) → AUTO-AVANÇA
///    - Página 2: Mensagem publicitária → AGUARDA SWIPE
/// 2️⃣ Estágio 2:
///    - Página 3: Imagem abertura + barra progresso (5s) → AUTO-AVANÇA
///    - Página 4: Mensagem publicitária → AGUARDA SWIPE
/// 3️⃣ Estágio 3:
///    - Página 5: Imagem abertura + barra progresso (5s) → AUTO-AVANÇA
///    - Página 6: Mensagem publicitária → AGUARDA SWIPE (última)
/// 
/// - Dots indicadores: 3 estágios (não 6 páginas)
/// - Botão "Pular" no topo direito (abre wizard)
/// - Barra de progresso animada nas páginas de abertura
class UserPromoMainContentsScreen extends StatefulWidget {
  const UserPromoMainContentsScreen({super.key});

  @override
  State<UserPromoMainContentsScreen> createState() =>
      _UserPromoMainContentsScreenState();
}

class _UserPromoMainContentsScreenState
    extends State<UserPromoMainContentsScreen> with SingleTickerProviderStateMixin {
  // Controller para gerenciar a navegação entre páginas
  final PageController _pageController = PageController();
  
  // Índice da página atual (0 a 5)
  int _currentPage = 0;
  
  // Total de páginas (6 páginas = 3 estágios × 2 páginas cada)
  static const int _totalPages = 6;
  
  // Total de estágios visuais (usado nos dots)
  static const int _totalStages = 3;
  
  // Timer para auto-avanço nas páginas de abertura
  Timer? _autoAdvanceTimer;
  
  // Controller de animação para a barra de progresso
  AnimationController? _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    // Inicia a animação da primeira página se for página de abertura
    if (_isOpeningPage(_currentPage)) {
      _startAutoAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _progressController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Verifica se a página é de abertura (páginas ímpares: 0, 2, 4)
  bool _isOpeningPage(int pageIndex) {
    return pageIndex % 2 == 0;
  }

  /// Calcula o estágio atual (0, 1 ou 2) baseado na página
  int _getCurrentStage(int pageIndex) {
    return pageIndex ~/ 2;
  }

  /// Inicia o timer de auto-avanço e animação da barra
  void _startAutoAdvance() {
    _progressController?.reset();
    _progressController?.forward();
    
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(seconds: 5), () {
      if (_currentPage < _totalPages - 1 && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Cancela o timer e reseta a animação
  void _cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _progressController?.stop();
    _progressController?.reset();
  }

  /// Pula o onboarding
  void _skipOnboarding() {
    _cancelAutoAdvance();
    _handleFinish();
  }

  /// Finaliza o onboarding (última página ou "Pular")
  void _handleFinish() {
    _cancelAutoAdvance();
    // ═══════════════════════════════════════════════════════════════════════
    // ✅ NAVEGA PARA O WIZARD após finalizar o slider
    // ═══════════════════════════════════════════════════════════════════════
    // Fecha o slider e abre o wizard de verificação de conteúdo
    Navigator.of(context).pop(); // Fecha o slider
    Modular.to.pushNamed(AppRoutes.userVerifiedContentWizard); // Abre o wizard
  }

  /// Callback quando a página muda
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Se é página de abertura (0, 2, 4), inicia auto-avanço
    if (_isOpeningPage(index)) {
      _startAutoAdvance();
    } else {
      // Se é página de mensagem (1, 3, 5), cancela auto-avanço
      _cancelAutoAdvance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Sem NavigationBar para tela inteira
      child: SafeArea(
        child: Stack(
          children: [
            // ═══════════════════════════════════════════════════════════════
            // PageView com os 6 estágios (3 grupos × 2 páginas)
            // ═══════════════════════════════════════════════════════════════
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildPage1Opening(),      // Estágio 1 - Abertura (auto-avança)
                _buildPage2Message(),      // Estágio 1 - Mensagem (aguarda)
                _buildPage3Opening(),      // Estágio 2 - Abertura (auto-avança)
                _buildPage4Message(),      // Estágio 2 - Mensagem (aguarda)
                _buildPage5Opening(),      // Estágio 3 - Abertura (auto-avança)
                _buildPage6Message(),      // Estágio 3 - Mensagem (aguarda)
              ],
            ),

            // ═══════════════════════════════════════════════════════════════
            // Botão "Pular" no topo direito
            // ═══════════════════════════════════════════════════════════════
            Positioned(
              top: 16,
              right: 16,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: CupertinoColors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                onPressed: _skipOnboarding,
                child: const Text(
                  'Pular',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // ═══════════════════════════════════════════════════════════════
            // Indicadores de Página (Dots) - Apenas no bottom
            // ═══════════════════════════════════════════════════════════════
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildPageIndicators(),
            ),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 1 - Estágio 1 Abertura (Imagem tela cheia)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage1Opening() {
    return _buildFullScreenImage(
      label: 'Abertura - Estágio 1',
      assetPath: 'assets/promo/stage1_opening.jpg',
      backgroundColor: CupertinoColors.white,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 2 - Estágio 1 Mensagem (Texto + Imagem centro)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage2Message() {
    return _buildMessagePage(
      topText: 'SEU CONTEÚDO É ÓTIMO!\nAGORA FAÇA ELE RENDER!\nMAIS, BEM MAIS!',
      bottomText: 'TRANSFORME CADA VÍDEO EM\nCRESCIMENTO REAL: MAIS\nINSCRITOS, MAIS FÃS E MAIS\nOPORTUNIDADES DE GANHAR COM\nO QUE VOCÊ JÁ SABE',
      imageAsset: 'assets/promo/stage1_center_image.jpg',
      backgroundColor: const Color(0xFF4A90E2), // Azul royal
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 3 - Estágio 2 Abertura (Imagem tela cheia)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage3Opening() {
    return _buildFullScreenImage(
      label: 'Abertura - Estágio 2',
      assetPath: 'assets/promo/stage2_opening.jpg',
      backgroundColor: CupertinoColors.systemGreen.withValues(alpha: 0.1),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 4 - Estágio 2 Mensagem (Texto + Imagem centro)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage4Message() {
    return _buildMessagePage(
      topText: 'PARE DE DEPENDER\nSÓ DO "ALGORITMO"\nDO YOUTUBE...',
      bottomText: 'GANHE CONSISTÊNCIA NO\nCRESCIMENTO: MAIS ALCANCE PARA\nSEUS VÍDEOS E MAIS TRÁFEGO\nRECORRENTE PARA O SEU CANAL.',
      imageAsset: 'assets/promo/stage2_center_image.jpg',
      backgroundColor: const Color(0xFF4A90E2), // Azul royal (mesmo da página 2)
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 5 - Estágio 3 Abertura (Imagem tela cheia)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage5Opening() {
    return _buildFullScreenImage(
      label: 'Abertura - Estágio 3',
      assetPath: 'assets/promo/stage3_opening.jpg',
      backgroundColor: CupertinoColors.systemOrange.withValues(alpha: 0.1),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 6 - Estágio 3 Mensagem (Texto + Imagem centro)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage6Message() {
    return _buildMessagePage(
      topText: 'GANHE MAIS POR USUÁRIO\nDIRETO COM QUEM\nTE ACOMPANHA',
      bottomText: 'DO VÍDEO AO SERVIÇO: NÓS\nFAZEMOS A PONTE PARA VOCÊ\nFECHAR CONSULTORIAS E\nATENDIMENTOS COM SEU PÚBLICO.',
      imageAsset: 'assets/promo/stage3_center_image.jpg',
      backgroundColor: const Color(0xFF4A90E2), // Azul royal (consistência visual)
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Widget Reutilizável: Imagem em Tela Cheia (Páginas de Abertura)
  /// Com barra de progresso animada no topo (5 segundos)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildFullScreenImage({
    required String label,
    required String assetPath,
    required Color backgroundColor,
  }) {
    // TODO: Adicionar 3 imagens de abertura fullscreen (páginas 1, 3, 5):
    //       - assets/promo/stage1_opening.jpg (Página 1 - Estágio 1)
    //       - assets/promo/stage2_opening.jpg (Página 3 - Estágio 2)
    //       - assets/promo/stage3_opening.jpg (Página 5 - Estágio 3)
    //       Substituir Container placeholder por: Image.asset(assetPath, fit: BoxFit.cover)
    return Stack(
      children: [
        // Imagem de fundo (placeholder)
        Container(
          width: double.infinity,
          height: double.infinity,
          color: backgroundColor,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.photo_fill_on_rectangle_fill,
                    size: 120,
                    color: CupertinoColors.systemGrey2,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    assetPath,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey3,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 1,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '📸 Imagem de Abertura',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Auto-avança em 5s',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════════
        // Barra de Progresso Animada no Topo
        // ═══════════════════════════════════════════════════════════════
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AnimatedBuilder(
                animation: _progressController!,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressController!.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Widget Reutilizável: Página de Mensagem (Texto + Imagem Centro)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildMessagePage({
    required String topText,
    required String bottomText,
    required String imageAsset,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              // ➤ Texto Superior (Título)
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    topText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: CupertinoColors.white,
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // ➤ Imagem Central (Placeholder ou Image.asset)
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.white,
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildCenterImagePlaceholder(imageAsset),
                  ),
                ),
              ),

              // ➤ Texto Inferior (Descrição)
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    bottomText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: CupertinoColors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Placeholder para Imagem Central (nas páginas de mensagem)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildCenterImagePlaceholder(String assetPath) {
    // TODO: Adicionar 3 imagens centrais (páginas 2, 4, 6):
    //       - assets/promo/stage1_center_image.jpg (Página 2 - Mensagem Estágio 1)
    //       - assets/promo/stage2_center_image.jpg (Página 4 - Mensagem Estágio 2)
    //       - assets/promo/stage3_center_image.jpg (Página 6 - Mensagem Estágio 3)
    //       Substituir Container placeholder por: Image.asset(assetPath, fit: BoxFit.cover)
    return Container(
      color: CupertinoColors.systemGrey6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.photo,
              size: 60,
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 12),
            Text(
              assetPath,
              style: const TextStyle(
                fontSize: 11,
                color: CupertinoColors.systemGrey2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Indicadores de Página (Dots) - Mostra 3 estágios (não 6 páginas)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPageIndicators() {
    final currentStage = _getCurrentStage(_currentPage);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalStages, (index) {
        final isActive = index == currentStage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color:
                isActive
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

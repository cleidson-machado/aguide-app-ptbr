import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
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
    extends State<UserPromoMainContentsScreen> with TickerProviderStateMixin {
  // Controller para gerenciar a navegação entre páginas
  final PageController _pageController = PageController();
  
  // Índice da página atual (0 a 6)
  int _currentPage = 0;
  
  // Total de páginas (7 páginas = 3 estágios × 2 páginas cada + 1 página extra)
  static const int _totalPages = 7;
  
  // Total de estágios visuais (usado nos dots)
  static const int _totalStages = 3;
  
  // Timer para auto-avanço nas páginas de abertura
  Timer? _autoAdvanceTimer;
  
  // Controller de animação para a barra de progresso
  AnimationController? _progressController;
  
  // ╔═══════════════════════════════════════════════════════════════════════╗
  // ║ CONTROLLERS DOS CÍRCULOS COLORIDOS ANIMADOS - INÍCIO                 ║
  // ╚═══════════════════════════════════════════════════════════════════════╝
  AnimationController? _yellowCircleController;      // Círculo amarelo grande
  AnimationController? _purpleCircleController;      // Círculo roxo grande
  AnimationController? _orangeCircleController;      // Círculo laranja médio
  AnimationController? _pinkCircleController;        // Círculo rosa médio
  AnimationController? _cyanCircleController;        // Círculo cyan médio
  AnimationController? _lightPurpleCircleController; // Círculo roxo claro médio
  // ╔═══════════════════════════════════════════════════════════════════════╗
  // ║ CONTROLLERS DOS CÍRCULOS COLORIDOS ANIMADOS - FIM                    ║
  // ╚═══════════════════════════════════════════════════════════════════════╝

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    // ╔═══════════════════════════════════════════════════════════════════════╗
    // ║ INICIALIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - INÍCIO               ║
    // ╚═══════════════════════════════════════════════════════════════════════╝
    
    // Animação do círculo amarelo (movimento diagonal lento)
    _yellowCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    // Animação do círculo roxo (movimento diagonal oposto, mais rápido)
    _purpleCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    // Animação do círculo laranja (órbita próxima)
    _orangeCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    
    // Animação do círculo rosa (órbita próxima)
    _pinkCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    // Animação do círculo cyan (órbita próxima)
    _cyanCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    // Animação do círculo roxo claro (órbita próxima)
    _lightPurpleCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    
    // ╔═══════════════════════════════════════════════════════════════════════╗
    // ║ INICIALIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - FIM                  ║
    // ╚═══════════════════════════════════════════════════════════════════════╝
    
    // Inicia a animação da primeira página se for página de abertura
    if (_isOpeningPage(_currentPage)) {
      _startAutoAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _progressController?.dispose();
    _yellowCircleController?.dispose();
    _purpleCircleController?.dispose();
    _orangeCircleController?.dispose();
    _pinkCircleController?.dispose();
    _cyanCircleController?.dispose();
    _lightPurpleCircleController?.dispose();
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
  void _startAutoAdvance({int durationSeconds = 5}) {
    _progressController?.reset();
    _progressController?.duration = Duration(seconds: durationSeconds);
    _progressController?.forward();
    
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(Duration(seconds: durationSeconds), () {
      if (_currentPage < _totalPages - 1 && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else if (_currentPage == _totalPages - 1 && mounted) {
        // Última página - finaliza onboarding
        _handleFinish();
      }
    });
  }

  /// Cancela o timer e reseta a animação
  void _cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _progressController?.stop();
    _progressController?.reset();
  }

  /// Pula o onboarding - vai direto para a página 7 (loading)
  void _skipOnboarding() {
    _cancelAutoAdvance();
    // Navega para a página 7 (loading Lottie)
    _pageController.animateToPage(
      6, // Página 7 (índice 6)
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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
    } else if (index == 5) {
      // Página 6 - auto-avanço de 15 segundos
      _startAutoAdvance(durationSeconds: 15);
    } else if (index == 6) {
      // Página 7 (Loading Lottie) - BLOQUEADA por 3 segundos
      // Usuário não pode sair desta página até o timer acabar
      _startAutoAdvance(durationSeconds: 3);
    } else {
      // Se é página de mensagem (1, 3), cancela auto-avanço
      _cancelAutoAdvance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Bloqueia o botão de voltar do sistema quando na página 7 (loading)
      canPop: _currentPage != 6,
      child: CupertinoPageScaffold(
      // Sem NavigationBar para tela inteira
      child: SafeArea(
        child: Stack(
          children: [
            // ═══════════════════════════════════════════════════════════════
            // PageView com os 7 estágios (3 grupos × 2 páginas + 1 loading)
            // Página 7: Gestos bloqueados durante carregamento
            // ═══════════════════════════════════════════════════════════════
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              // Bloqueia gestos na página 7 (loading)
              physics: _currentPage == 6
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              children: [
                _buildPage1Opening(),      // Estágio 1 - Abertura (auto-avança)
                _buildPage2Message(),      // Estágio 1 - Mensagem (aguarda)
                _buildPage3Opening(),      // Estágio 2 - Abertura (auto-avança)
                _buildPage4Message(),      // Estágio 2 - Mensagem (aguarda)
                _buildPage5Opening(),      // Estágio 3 - Abertura (auto-avança)
                _buildPage6Message(),      // Estágio 3 - Mensagem (aguarda)
                _buildPage7Blank(),        // Página Extra - Loading Lottie (bloqueado)
              ],
            ),

            // ═══════════════════════════════════════════════════════════════
            // Botão "Pular" no topo direito
            // Oculto na página 7 (página em branco)
            // ═══════════════════════════════════════════════════════════════
            if (_currentPage != 6) // Esconde botão na página 7
              Positioned(
                top: 16,
                right: 16,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: CupertinoColors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
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
            // Oculto na página 7 (página em branco)
            // ═══════════════════════════════════════════════════════════════
            if (_currentPage != 6) // Esconde dots na página 7
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: _buildPageIndicators(),
              ),
          ],
        ),
      ),
      ), // Fechamento do PopScope
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 1 - Estágio 1 Abertura (Imagem tela cheia)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage1Opening() {
    return _buildFullScreenImage(
      label: 'Abertura - Estágio 1',
      assetPath: 'assets/promo/stage1_opening.png',
      backgroundColor: CupertinoColors.white,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 2 - Estágio 1 Mensagem (Texto + Imagem centro com círculos animados)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage2Message() {
    return _buildPage2MessageWithFloatingCircles();
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 3 - Estágio 2 Abertura (Imagem tela cheia)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage3Opening() {
    return _buildFullScreenImage(
      label: 'Abertura - Estágio 2',
      assetPath: 'assets/promo/stage2_opening.png',
      backgroundColor: CupertinoColors.systemGreen.withValues(alpha: 0.1),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 4 - Estágio 2 Mensagem (Texto + Imagem centro com círculos animados)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage4Message() {
    return _buildPage4MessageWithFloatingCircles();
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 5 - Estágio 3 Abertura (Imagem tela cheia)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage5Opening() {
    return _buildFullScreenImage(
      label: 'Abertura - Estágio 3',
      assetPath: 'assets/promo/stage3_opening.png',
      backgroundColor: CupertinoColors.systemOrange.withValues(alpha: 0.1),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 6 - Estágio 3 Mensagem (Texto + Imagem centro com círculos animados)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage6Message() {
    return _buildPage6MessageWithFloatingCircles();
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 7 - Página Extra com Animação Lottie (não conta nos dots)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage7Blank() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 67, 123, 208), // Azul profundo
            Color.fromARGB(255, 92, 111, 119), // Ciano vibrante
            Color.fromARGB(255, 213, 198, 118), // Amarelo dourado
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animação Lottie
            Lottie.asset(
              'assets/animated/lottie_spinner_001.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Carregando...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
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
    return Stack(
      children: [
        // ═══════════════════════════════════════════════════════════════
        // Fundo com Gradiente
        // ═══════════════════════════════════════════════════════════════
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 67, 123, 208), // Azul profundo
                Color.fromARGB(255, 92, 111, 119), // Ciano vibrante
                Color.fromARGB(255, 213, 198, 118), // Amarelo dourado
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════════
        // Imagem PNG com Transparência (sobreposta ao gradiente)
        // ═══════════════════════════════════════════════════════════════
        Positioned.fill(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover, // Preenche toda a tela (pode cortar bordas)
            errorBuilder: (context, error, stackTrace) {
              // Fallback caso a imagem não carregue
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 60,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar:\n$assetPath',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
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
  /// PÁGINA 2 ESPECIAL - Com Imagem de Retrato e Círculos Flutuantes
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage2MessageWithFloatingCircles() {
    const backgroundColor = Color(0xFF4A90E2); // Azul royal

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            const Color.fromARGB(255, 24, 88, 161).withValues(alpha: 1.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              // ➤ Texto Superior (Título)
              Expanded(
                flex: 6,
                child: Center(
                  child: Text(
                    'OS SEUS VÍDEOS \n E CONTEÚDO JÁ SÃO \n ÓTIMOS! AGORA FAÇA\nELES RENDEREM MAIS...\n MUITO MAIS!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: CupertinoColors.white,
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // ➤ Imagem Central com Círculos Animados (sem sombras)
              Expanded(
                flex: 20,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ RENDERIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - INÍCIO                ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                      
                      // ═══════════════════════════════════════════════
                      // Círculo Amarelo (canto superior direito)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _yellowCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: -15 + (_yellowCircleController!.value * 20),
                            right: -10 + (_yellowCircleController!.value * 15),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFC107), // Amarelo vibrante (sem alpha)
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Roxo (canto inferior esquerdo)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _purpleCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            bottom: -10 + (_purpleCircleController!.value * 25),
                            left: 10 + (_purpleCircleController!.value * 20),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 203, 90, 209), // Roxo vibrante (sem alpha)
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Laranja (lado direito médio)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _orangeCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 100 + (_orangeCircleController!.value * 30),
                            right: 10 + (_orangeCircleController!.value * 15),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF6B35), // Laranja vibrante
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Rosa (lado esquerdo superior)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _pinkCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 50 + (_pinkCircleController!.value * 25),
                            left: 20 + (_pinkCircleController!.value * 12),
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF69B4), // Rosa pink
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Cyan (lado direito inferior)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _cyanCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            bottom: 50 + (_cyanCircleController!.value * 20),
                            right: 30 + (_cyanCircleController!.value * 18),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00BCD4), // Cyan/Turquesa
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Roxo Claro (lado esquerdo médio)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _lightPurpleCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 150 + (_lightPurpleCircleController!.value * 35),
                            left: 15 + (_lightPurpleCircleController!.value * 10),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF9C27B0), // Roxo claro/magenta
                              ),
                            ),
                          );
                        },
                      ),

                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ RENDERIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - FIM                   ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝

                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ IMAGEM DA MULHER (CENTRO DA PÁGINA 2) - INÍCIO                       ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                      Positioned.fill(
                        child: Image.asset(
                          'assets/promo/stage1_opening_retrato.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: CupertinoColors.systemGrey6,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.exclamationmark_triangle,
                                      size: 50,
                                      color: CupertinoColors.systemRed,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Erro ao carregar\nstage1_opening_retrato.png',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ IMAGEM DA MULHER (CENTRO DA PÁGINA 2) - FIM                          ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                    ],
                  ),
                ),
              ),

              // ➤ Texto Inferior (Descrição)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(
                  'TRANSFORME CADA VÍDEO EM\nCRESCIMENTO REAL: MAIS\nINSCRITOS, MAIS FÃS E MAIS\nOPORTUNIDADES DE GANHAR COM\nO QUE VOCÊ JÁ SABE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: CupertinoColors.white,
                    height: 1.3,
                  ),
                ),
              ),
              
              // Espaçador flexível para manter dots no lugar
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 4 ESPECIAL - Com Imagem de Retrato e Círculos Flutuantes
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage4MessageWithFloatingCircles() {
    const backgroundColor = Color(0xFF4A90E2); // Azul royal

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            const Color.fromARGB(255, 24, 88, 161).withValues(alpha: 1.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              // ➤ Texto Superior (Título)
              Expanded(
                flex: 6,
                child: Center(
                  child: Text(
                    'VOCÊ PODE DEIXAR \n DE DEPENDER APENAS \n DO "ALGORITMO" LIMITADO\n DO YOUTUBE E OUTRAS REDES!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: CupertinoColors.white,
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // ➤ Imagem Central com Círculos Animados (sem sombras)
              Expanded(
                flex: 20,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ RENDERIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - INÍCIO                ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                      
                      // ═══════════════════════════════════════════════
                      // Círculo Amarelo (canto superior direito)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _yellowCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: -15 + (_yellowCircleController!.value * 20),
                            right: -10 + (_yellowCircleController!.value * 15),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFC107), // Amarelo vibrante (sem alpha)
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Roxo (canto inferior esquerdo)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _purpleCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            bottom: -10 + (_purpleCircleController!.value * 25),
                            left: 10 + (_purpleCircleController!.value * 20),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 203, 90, 209), // Roxo vibrante (sem alpha)
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Laranja (lado direito médio)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _orangeCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 100 + (_orangeCircleController!.value * 30),
                            right: 10 + (_orangeCircleController!.value * 15),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF6B35), // Laranja vibrante
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Rosa (lado esquerdo superior)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _pinkCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 50 + (_pinkCircleController!.value * 25),
                            left: 20 + (_pinkCircleController!.value * 12),
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF69B4), // Rosa pink
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Cyan (lado direito inferior)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _cyanCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            bottom: 50 + (_cyanCircleController!.value * 20),
                            right: 30 + (_cyanCircleController!.value * 18),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00BCD4), // Cyan/Turquesa
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Roxo Claro (lado esquerdo médio)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _lightPurpleCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 150 + (_lightPurpleCircleController!.value * 35),
                            left: 15 + (_lightPurpleCircleController!.value * 10),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF9C27B0), // Roxo claro/magenta
                              ),
                            ),
                          );
                        },
                      ),

                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ RENDERIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - FIM                   ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝

                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ IMAGEM DA MULHER (CENTRO DA PÁGINA 4) - INÍCIO                       ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                      Positioned.fill(
                        child: Image.asset(
                          'assets/promo/stage2_opening_retrato.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: CupertinoColors.systemGrey6,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.exclamationmark_triangle,
                                      size: 50,
                                      color: CupertinoColors.systemRed,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Erro ao carregar\nstage2_opening_retrato.png',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ IMAGEM DA MULHER (CENTRO DA PÁGINA 4) - FIM                          ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                    ],
                  ),
                ),
              ),

              // ➤ Texto Inferior (Descrição)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(
                  'GANHE CONSISTÊNCIA NO\nCRESCIMENTO: MAIS ALCANCE PARA\nSEUS VÍDEOS E MAIS TRÁFEGO\nRECORRENTE PARA O SEU CANAL.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: CupertinoColors.white,
                    height: 1.3,
                  ),
                ),
              ),
              
              // Espaçador flexível para manter dots no lugar
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PÁGINA 6 ESPECIAL - Com Imagem de Retrato e Círculos Flutuantes
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPage6MessageWithFloatingCircles() {
    const backgroundColor = Color(0xFF4A90E2); // Azul royal

    return Stack(
      children: [
        // ═══════════════════════════════════════════════════════════════
        // Conteúdo principal da página
        // ═══════════════════════════════════════════════════════════════
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor,
                const Color.fromARGB(255, 24, 88, 161).withValues(alpha: 1.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  // ➤ Texto Superior (Título)
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Text(
                        'VOCÊ VAI GANHAR\nMUITO MAIS POR USUÁRIO\nUTILIZANDO NOSSA TECNOLOGIA\nDE VENDAS E RELACIONAMENTO\nCOM SUA AUDIÊNCIA!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: CupertinoColors.white,
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // ➤ Imagem Central com Círculos Animados (sem sombras)
                  Expanded(
                flex: 20,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ RENDERIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - INÍCIO                ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                      
                      // ═══════════════════════════════════════════════
                      // Círculo Amarelo (canto superior direito)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _yellowCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: -15 + (_yellowCircleController!.value * 20),
                            right: -10 + (_yellowCircleController!.value * 15),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFC107), // Amarelo vibrante (sem alpha)
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Roxo (canto inferior esquerdo)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _purpleCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            bottom: -10 + (_purpleCircleController!.value * 25),
                            left: 10 + (_purpleCircleController!.value * 20),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 203, 90, 209), // Roxo vibrante (sem alpha)
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Laranja (lado direito médio)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _orangeCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 100 + (_orangeCircleController!.value * 30),
                            right: 10 + (_orangeCircleController!.value * 15),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF6B35), // Laranja vibrante
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Rosa (lado esquerdo superior)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _pinkCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 50 + (_pinkCircleController!.value * 25),
                            left: 20 + (_pinkCircleController!.value * 12),
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF69B4), // Rosa pink
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Cyan (lado direito inferior)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _cyanCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            bottom: 50 + (_cyanCircleController!.value * 20),
                            right: 30 + (_cyanCircleController!.value * 18),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00BCD4), // Cyan/Turquesa
                              ),
                            ),
                          );
                        },
                      ),

                      // ═══════════════════════════════════════════════
                      // Círculo Roxo Claro (lado esquerdo médio)
                      // ═══════════════════════════════════════════════
                      AnimatedBuilder(
                        animation: _lightPurpleCircleController!,
                        builder: (context, child) {
                          return Positioned(
                            top: 150 + (_lightPurpleCircleController!.value * 35),
                            left: 15 + (_lightPurpleCircleController!.value * 10),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF9C27B0), // Roxo claro/magenta
                              ),
                            ),
                          );
                        },
                      ),

                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ RENDERIZAÇÃO DOS CÍRCULOS COLORIDOS ANIMADOS - FIM                   ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝

                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ IMAGEM DA MULHER (CENTRO DA PÁGINA 6) - INÍCIO                       ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                      Positioned.fill(
                        child: Image.asset(
                          'assets/promo/stage3_opening_retrato.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: CupertinoColors.systemGrey6,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.exclamationmark_triangle,
                                      size: 50,
                                      color: CupertinoColors.systemRed,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Erro ao carregar\nstage3_opening_retrato.png',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // ╔═══════════════════════════════════════════════════════════════════════╗
                      // ║ IMAGEM DA MULHER (CENTRO DA PÁGINA 6) - FIM                          ║
                      // ╚═══════════════════════════════════════════════════════════════════════╝
                    ],
                  ),
                ),
              ),

                  // ➤ Texto Inferior (Descrição)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      'DO VÍDEO AO SERVIÇO: NÓS\nFAZEMOS A PONTE PARA VOCÊ\nFECHAR CONSULTORIAS E\nATENDIMENTOS COM SEU PÚBLICO.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: CupertinoColors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
              
                  // Espaçador flexível para manter dots no lugar
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════════
        // Barra de Progresso Animada no Topo (15 segundos)
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
  /// Indicadores de Página (Dots) - Mostra 3 estágios (não 6 páginas)
  /// ═══════════════════════════════════════════════════════════════════════
  Widget _buildPageIndicators() {
    final currentStage = _getCurrentStage(_currentPage);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalStages, (index) {
        final isActive = index == currentStage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color:
                isActive
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey2,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}

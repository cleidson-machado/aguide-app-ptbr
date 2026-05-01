import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/main_contents/relation/relation_welcome_view_model.dart';
import 'package:portugal_guide/features/main_contents/relation/screens/main_relation_stepper_form_screen.dart';

/// Tela de boas-vindas/saída da aba Relações.
///
/// Estado controlado por [_cancelCount]:
///   _cancelCount == 0  →  Layout WELCOME
///   _cancelCount  > 0  →  Layout EXIT (timer 6s → auto-home)
///
/// [AnimationController] criado UMA vez em [initState] e nunca recriado.
/// Cada cancelamento chama reset()+forward() no mesmo controller.
///
/// Consome endpoint: GET /api/v1/users/{userId}/details
class MainRelationWelcomeScreen extends StatefulWidget {
  const MainRelationWelcomeScreen({super.key});

  @override
  State<MainRelationWelcomeScreen> createState() =>
      _MainRelationWelcomeScreenState();
}

class _MainRelationWelcomeScreenState extends State<MainRelationWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final ProfileWelcomeViewModel _viewModel;
  late final AuthTokenManager _authManager;

  /// Controller único — criado em initState, nunca recriado ou redisposado.
  late final AnimationController _progressController;

  /// Contador de cancelamentos.
  /// 0 = WELCOME  |  > 0 = EXIT (cada incremento reinicia o ciclo)
  int _cancelCount = 0;

  bool get _isExitMode => _cancelCount > 0;

  @override
  void initState() {
    super.initState();
    _viewModel = injector<ProfileWelcomeViewModel>();
    _authManager = injector<AuthTokenManager>();

    // Controller criado UMA vez para todo o ciclo de vida do widget
    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    // Única fonte de verdade: redireciona quando a animação completa
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _redirectToHome();
      }
    });

    _loadUserDetails();
  }

  /// Entra em EXIT: incrementa contador, reinicia animação.
  void _enterExitMode() {
    if (kDebugMode) {
      print(
        '🔄 [MainRelationWelcomeScreen] _enterExitMode — cancelCount: ${_cancelCount + 1}',
      );
    }
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();
    setState(() => _cancelCount++);
  }

  /// Reseta para WELCOME: zera contador e para animação.
  void _resetToWelcome() {
    if (kDebugMode) print('✅ [MainRelationWelcomeScreen] _resetToWelcome');
    _progressController.stop();
    _progressController.reset();
    if (mounted) setState(() => _cancelCount = 0);
  }

  /// Chamado após 14s: reseta estado ANTES de navegar.
  void _redirectToHome() {
    if (!mounted) return;
    if (kDebugMode) print('🏠 [MainRelationWelcomeScreen] _redirectToHome');
    
    // Reset FIRST → quando usuário voltar verá WELCOME
    _resetToWelcome();
    
    // ✅ CORRETO: Navegar de volta via pilha do Navigator
    if (Navigator.of(context).canPop()) {
      if (kDebugMode) print('📤 [MainRelationWelcomeScreen] Executando Navigator.pop()');
      Navigator.of(context).pop();
    } else {
      // Fallback: navegar para tela principal
      if (kDebugMode) print('📤 [MainRelationWelcomeScreen] Fallback: Modular.to.navigate(main)');
      Modular.to.navigate(AppRoutes.main);
    }
  }

  Future<void> _loadUserDetails() async {
    final userId = _authManager.getUserId();

    if (userId != null && userId.isNotEmpty) {
      await _viewModel.loadUserDetails(userId);
    } else {
      if (kDebugMode) {
        print(
          '❌ [MainRelationWelcomeScreen] User ID não encontrado no token JWT',
        );
      }

      if (mounted) {
        _showErrorDialog(
          'Erro de autenticação. Por favor, faça login novamente.',
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Erro'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _handleCancel() {
    if (kDebugMode) {
      print('🔴 [MainRelationWelcomeScreen] _handleCancel chamado');
    }

    // ✅ CORRETO: Esta agora é uma ROTA NAVEGADA (não mais tab direta)
    // Usar Navigator.pop() para voltar na pilha de navegação
    if (Navigator.of(context).canPop()) {
      if (kDebugMode) {
        print('📤 [MainRelationWelcomeScreen] Executando Navigator.pop()');
      }
      Navigator.of(context).pop();
    } else {
      // Fallback: navegar para tela principal
      if (kDebugMode) {
        print('📤 [MainRelationWelcomeScreen] Fallback: Modular.to.navigate(main)');
      }
      Modular.to.navigate(AppRoutes.main);
    }
  }

  void _handleStartForm() async {
    // Navega para o formulário (main_stepper_form_screen)
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => const MainRelationStepperFormScreen()),
    );

    // Se retornou 'cancelled', entra em EXIT mode
    if (result == 'cancelled' && mounted) {
      if (kDebugMode) {
        print('🔙 [MainRelationWelcomeScreen] cancelled → _enterExitMode');
      }
      _enterExitMode();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Modo EXIT: Layout simplificado sem NavigationBar
    if (_isExitMode) {
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: SafeArea(child: _buildExitContent()),
      );
    }

    // Modo WELCOME: Layout completo com NavigationBar
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleCancel,
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.label),
        ),
        middle: const Text('Relações - Ajustes'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleCancel,
          child: const Text(
            'Cancelar',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            // Loading state
            if (_viewModel.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            // Error state
            if (_viewModel.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 48,
                        color: CupertinoColors.destructiveRed,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _viewModel.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton.filled(
                        onPressed: _loadUserDetails,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Content state
            return _buildWelcomeContent();
          },
        ),
      ),
    );
  }

  /// Layout de boas-vindas (modo WELCOME)
  Widget _buildWelcomeContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Conteúdo scrollable (imagem + textos)
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Imagem de boas-vindas
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.35),
                          blurRadius: 10,
                          spreadRadius: 1.1,
                          offset: const Offset(0, 0),
                          blurStyle: BlurStyle.normal,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/forms/profile1_welcome.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Saudação personalizada
                  Text(
                    'Olá, ${_viewModel.userName}!',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Mensagem dinâmica (CRIADOR ou CONSUMIDOR) com tipo em negrito e vermelho
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          height: 1.4,
                          color: CupertinoColors.label,
                        ),
                        children: [
                          TextSpan(text: _viewModel.welcomeMessagePrefix),
                          TextSpan(
                            text: _viewModel.userTypeLabel,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.destructiveRed,
                            ),
                          ),
                          TextSpan(text: _viewModel.welcomeMessageSuffix),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Botões de ação (sempre no rodapé)
          Row(
            children: [
              // Botão Cancelar
              Expanded(
                child: CupertinoButton(
                  onPressed: _handleCancel,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.systemGrey4,
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.lato(
                      color: CupertinoColors.label,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Botão Vamos começar!
              Expanded(
                flex: 2,
                child: CupertinoButton(
                  onPressed: _handleStartForm,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.activeBlue,
                  child: Text(
                    'Vamos começar!',
                    style: GoogleFonts.lato(
                      color: CupertinoColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Margem inferior do rodapé
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Layout de despedida (modo EXIT)
  Widget _buildExitContent() {
    final userName = _authManager.getUserName() ?? 'Usuário';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Saudação personalizada
          Column(
            children: [
              Text(
                '$userName...',
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Respire fundo!',
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Imagem de despedida
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.25),
                  blurRadius: 22,
                  spreadRadius: 0.8,
                  offset: const Offset(0, 0),
                  blurStyle: BlurStyle.normal,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/forms/profile1_go_out.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Mensagem de despedida
          Text(
            'Estamos quase lá!',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Não desista!',
            style: GoogleFonts.lato(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Você pode voltar \n e terminar quando quiser.',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Estaremos aqui a sua disposição!',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            '| Até breve! |',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemBlue,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Loader horizontal animado
          // Barra de progresso — usa o controller único, sempre não-nulo
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final secsLeft = (15 - (_progressController.value * 15))
                  .ceil()
                  .clamp(0, 15);
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Redirecionando em ${secsLeft}s...',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              );
            },
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

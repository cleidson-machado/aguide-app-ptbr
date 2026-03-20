import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/home_content/screens/home_content_tab_screen.dart';
import 'package:portugal_guide/features/main_contents/profile/profile_welcome_view_model.dart';
import 'package:portugal_guide/features/main_contents/profile/screens/main_stepper_form_screen.dart';

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
class MainProfileWelcomeScreen extends StatefulWidget {
  const MainProfileWelcomeScreen({super.key});

  @override
  State<MainProfileWelcomeScreen> createState() => _MainProfileWelcomeScreenState();
}

class _MainProfileWelcomeScreenState extends State<MainProfileWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final ProfileWelcomeViewModel _viewModel;
  late final AuthTokenManager _authManager;

  /// Controller único — criado em initState, nunca recriado ou redisposado.
  late final AnimationController _progressController;

  Timer? _redirectTimer;

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
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _loadUserDetails();
  }

  /// Entra em EXIT: incrementa contador, reinicia animação e timer.
  void _enterExitMode() {
    if (kDebugMode) {
      print('🔄 [MainProfileWelcomeScreen] _enterExitMode — cancelCount: ${_cancelCount + 1}');
    }
    _redirectTimer?.cancel();
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();
    _redirectTimer = Timer(const Duration(seconds: 6), _redirectToHome);
    setState(() => _cancelCount++);
  }

  /// Reseta para WELCOME: zera contador, para animação e timer.
  void _resetToWelcome() {
    if (kDebugMode) print('✅ [MainProfileWelcomeScreen] _resetToWelcome');
    _redirectTimer?.cancel();
    _redirectTimer = null;
    _progressController.stop();
    _progressController.reset();
    if (mounted) setState(() => _cancelCount = 0);
  }

  /// Chamado após 6s: reseta estado ANTES de navegar.
  void _redirectToHome() {
    if (!mounted) return;
    if (kDebugMode) print('🏠 [MainProfileWelcomeScreen] _redirectToHome');
    // Reset FIRST → quando usuário voltar à tab verá WELCOME
    _resetToWelcome();
    context
        .findAncestorStateOfType<HomeContentTabScreenState>()
        ?.resetToFirstTab();
  }

  Future<void> _loadUserDetails() async {
    final userId = _authManager.getUserId();
    
    if (userId != null && userId.isNotEmpty) {
      await _viewModel.loadUserDetails(userId);
    } else {
      if (kDebugMode) {
        print('❌ [MainProfileWelcomeScreen] User ID não encontrado no token JWT');
      }
      
      if (mounted) {
        _showErrorDialog('Erro de autenticação. Por favor, faça login novamente.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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
      print('🔴 [MainProfileWelcomeScreen] _handleCancel chamado');
    }
    
    // ✅ CORRETO: Esta é uma TAB, não uma rota navegada
    // Não pode usar Navigator.pop() pois não há para onde voltar
    // Solução: Acessar o HomeContentTabScreen e resetar para primeira tab
    
    final homeState = context.findAncestorStateOfType<HomeContentTabScreenState>();
    
    if (kDebugMode) {
      print('🔍 [MainProfileWelcomeScreen] homeState encontrado: ${homeState != null}');
    }
    
    if (homeState != null) {
      if (kDebugMode) {
        print('✅ [MainProfileWelcomeScreen] Chamando resetToFirstTab()');
      }
      homeState.resetToFirstTab();
    } else {
      if (kDebugMode) {
        print('❌ [MainProfileWelcomeScreen] HomeContentTabScreenState não encontrado');
      }
    }
  }

  void _handleStartForm() async {
    // Navega para o formulário (main_stepper_form_screen)
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const MainStepperFormScreen(),
      ),
    );

    // Se retornou 'cancelled', entra em EXIT mode
    if (result == 'cancelled' && mounted) {
      if (kDebugMode) {
        print('🔙 [MainProfileWelcomeScreen] cancelled → _enterExitMode');
      }
      _enterExitMode();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _redirectTimer?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Modo EXIT: Layout simplificado sem NavigationBar
    if (_isExitMode) {
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: SafeArea(
          child: _buildExitContent(),
        ),
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
          child: const Icon(
            CupertinoIcons.xmark,
            color: CupertinoColors.label,
          ),
        ),
        middle: const Text('Relações - Ajustes'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleCancel,
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            // Loading state
            if (_viewModel.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagem de boas-vindas
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/forms/profile1_welcome.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 8),

          // Saudação personalizada
          Text(
            'Olá, ${_viewModel.userName}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Mensagem dinâmica (CRIADOR ou CONSUMIDOR) com tipo em negrito e vermelho
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 18,
                height: 1.4,
                color: CupertinoColors.label,
              ),
              children: [
                TextSpan(text: _viewModel.welcomeMessagePrefix),
                TextSpan(
                  text: _viewModel.userTypeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
                TextSpan(text: _viewModel.welcomeMessageSuffix),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Botões de ação
          Row(
            children: [
              // Botão Cancelar
              Expanded(
                child: CupertinoButton(
                  onPressed: _handleCancel,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.systemGrey4,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
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
                  child: const Text(
                    'Vamos começar!',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          Text(
            'Bem, $userName...',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Imagem de despedida
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/forms/profile1_go_out.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 32),

          // Mensagem de despedida
          const Text(
            'Você já desistiu?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          const Text(
            'Não tem problema!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Vamos retomar depois!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          const Text(
            'Até mais tarde!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.destructiveRed,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Loader horizontal animado
          // Barra de progresso — usa o controller único, sempre não-nulo
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final secsLeft =
                  (6 - (_progressController.value * 6)).ceil().clamp(0, 6);
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
                    style: const TextStyle(
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

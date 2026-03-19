import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/home_content/screens/home_content_tab_screen.dart';
import 'package:portugal_guide/features/main_contents/profile/profile_welcome_view_model.dart';
import 'package:portugal_guide/features/main_contents/profile/screens/main_stepper_form_screen.dart';

/// Tela intermediária de boas-vindas exibida antes do formulário de perfil
/// 
/// Determina dinamicamente se o usuário é CRIADOR ou CONSUMIDOR baseado em:
/// - youtubeUserId e youtubeChannelId (ambos não-nulos = CRIADOR)
/// 
/// Consome endpoint: GET /api/v1/users/{userId}/details
class MainProfileWelcomeScreen extends StatefulWidget {
  const MainProfileWelcomeScreen({super.key});

  @override
  State<MainProfileWelcomeScreen> createState() => _MainProfileWelcomeScreenState();
}

class _MainProfileWelcomeScreenState extends State<MainProfileWelcomeScreen> {
  late final ProfileWelcomeViewModel _viewModel;
  late final AuthTokenManager _authManager;

  @override
  void initState() {
    super.initState();
    _viewModel = injector<ProfileWelcomeViewModel>();
    _authManager = injector<AuthTokenManager>();

    // Carregar detalhes do usuário logado
    _loadUserDetails();
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

  void _handleStartForm() {
    // Navega para o formulário (main_stepper_form_screen)
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const MainStepperFormScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            return _buildContent();
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
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

          // Mensagem dinâmica (CRIADOR ou CONSUMIDOR)
          Text(
            _viewModel.welcomeMessage,
            style: const TextStyle(
              fontSize: 18,
              height: 1.4,
              color: CupertinoColors.label,
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
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_login_view_model.dart';
import 'package:portugal_guide/features/auth_credentials/screens/auth_credentials_forgot_pass_screen.dart';
import 'package:portugal_guide/features/auth_google/auth_google_model.dart';
import 'package:portugal_guide/features/auth_google/auth_google_view_model.dart';

class AuthCredentialsLoginScreen extends StatefulWidget {
  const AuthCredentialsLoginScreen({super.key});

  @override
  State<AuthCredentialsLoginScreen> createState() => _AuthCredentialsLoginScreenState();
}

class _AuthCredentialsLoginScreenState extends State<AuthCredentialsLoginScreen> {
  final AuthCredentialsLoginViewModel _viewModel = injector<AuthCredentialsLoginViewModel>();
  final AuthGoogleViewModel _googleViewModel = injector<AuthGoogleViewModel>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isPasswordVisible = false;
  bool _isNavigating = false; // Flag para evitar múltiplas navegações

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _viewModel.addListener(_onViewModelChanged);

    // Preencher com dados de teste em modo debug
    if (kDebugMode) {
      _emailController.text = 'contato@aguide.space';
      _passwordController.text = 'admin123';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _googleViewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.state == LoginState.success && !_isNavigating) {
      _isNavigating = true; // Prevenir múltiplas navegações
      
      // Login bem-sucedido, navegar para tela principal
      if (kDebugMode) {
        print('✅ [AuthCredentialsLoginScreen] Login bem-sucedido, navegando...');
      }
      
      // Navegar para tela principal após um pequeno delay para garantir que a UI está pronta
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Modular.to.pushReplacementNamed(AppRoutes.main).then((_) {
            _isNavigating = false; // Reset flag após navegação
          }).catchError((error) {
            if (kDebugMode) {
              print('❌ [AuthCredentialsLoginScreen] Erro ao navegar: $error');
            }
            _isNavigating = false;
          });
        }
      });
    } else if (_viewModel.state == LoginState.error) {
      // Mostrar erro
      _showErrorDialog(_viewModel.errorMessage ?? 'Erro desconhecido');
    }
  }

  void _handleLogin() {
    // Limpar erros anteriores
    _viewModel.clearError();

    // Esconder teclado
    FocusScope.of(context).unfocus();

    // Chamar login
    _viewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erro no Login'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Imagem no topo
                    Container(
                      height: 250,
                      color: CupertinoColors.lightBackgroundGray,
                      child: Center(
                        child: CupertinoButton(
                          onPressed: () {}, // Placeholder para imagem
                          child: const Icon(
                            CupertinoIcons.photo,
                            size: 50,
                            color: CupertinoColors.inactiveGray,
                          ),
                        ),
                      ),
                    ),

                    // Seção de Login
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            "Welcome - Plus!",
                            style: GoogleFonts.lato(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Campo de Email
                          CupertinoTextField(
                            controller: _emailController,
                            placeholder: "Email Address",
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enabled: !_viewModel.isLoading,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: CupertinoColors.systemGrey3),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campo de Senha
                          CupertinoTextField(
                            controller: _passwordController,
                            placeholder: "Password",
                            obscureText: !_isPasswordVisible,
                            enabled: !_viewModel.isLoading,
                            padding: const EdgeInsets.all(16),
                            suffix: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              child: Icon(
                                _isPasswordVisible
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: CupertinoColors.systemGrey3),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 10),

                          // Esqueceu a senha
                          Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _viewModel.isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              const AuthCredentialsForgotPassScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                "Forgot password?",
                                style: GoogleFonts.lato(
                                  color: CupertinoColors.activeBlue,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Botão Login
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton.filled(
                              borderRadius: BorderRadius.circular(8),
                              onPressed: _viewModel.isLoading ? null : _handleLogin,
                              child: _viewModel.isLoading
                                  ? const CupertinoActivityIndicator(
                                      color: CupertinoColors.white,
                                    )
                                  : const Text("Login"),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Cadastro
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Not a member?  | ",
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _viewModel.isLoading
                                    ? null
                                    : () {
                                        Modular.to.pushNamed(AppRoutes.register);
                                      },
                                child: Text(
                                  "Register now",
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: CupertinoColors.activeBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Linha divisória
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: CupertinoColors.systemGrey3),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    "Or continue with",
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: CupertinoColors.systemGrey3),
                                ),
                              ],
                            ),
                          ),

                          // Botão Google Sign-In
                          _buildGoogleSignInButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (_viewModel.isLoading)
                Container(
                  color: CupertinoColors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 20,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Botão de login com Google
  Widget _buildGoogleSignInButton() {
    return AnimatedBuilder(
      animation: _googleViewModel,
      builder: (context, child) {
        final bool isAnyLoading = _viewModel.isLoading || _googleViewModel.isLoading;
        
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isAnyLoading ? null : _handleGoogleSignIn,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemGrey4,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_googleViewModel.isLoading)
                  const CupertinoActivityIndicator()
                else ...[
                  // Ícone Google (usando emoji temporariamente)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.destructiveRed,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _googleViewModel.isLoading 
                        ? "Autenticando..." 
                        : "Continue with Google",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Handler para login com Google
  Future<void> _handleGoogleSignIn() async {
    // Limpar erros anteriores
    _googleViewModel.clearError();
    
    // Executar login
    await _googleViewModel.signInWithGoogle();
    
    if (!mounted) return;
    
    // Verificar resultado
    if (_googleViewModel.state == OAuthState.success) {
      if (kDebugMode) {
        print('✅ [AuthCredentialsLoginScreen] Login Google bem-sucedido, navegando...');
      }
      
      // Navegar para tela principal
      if (!_isNavigating) {
        _isNavigating = true;
        Modular.to.pushReplacementNamed(AppRoutes.main).then((_) {
          _isNavigating = false;
        }).catchError((error) {
          if (kDebugMode) {
            print('❌ [AuthCredentialsLoginScreen] Erro ao navegar: $error');
          }
          _isNavigating = false;
        });
      }
    } else if (_googleViewModel.errorMessage != null) {
      // Mostrar erro
      _showErrorDialog(_googleViewModel.errorMessage!);
    }
  }
}

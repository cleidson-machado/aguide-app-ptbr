// ======================================================================
// BACKUP DA VIEW ORIGINAL - MainProfileExitScreen
// Data do backup: 20/03/2026
// 
// Contexto: Tela de despedida exibida após cancelamento do formulário
// Preservada para referência - funcionalidade mesclada em MainProfileWelcomeScreen
//
// Motivo: Problema de navegação/pilha - tela navegada não conseguia
// acessar HomeContentTabScreenState de forma confiável
// ======================================================================

// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/home_content/screens/home_content_tab_screen.dart';

/// Tela intermediária exibida quando usuário cancela o formulário de perfil
/// 
/// Funcionalidades:
/// - Mensagem de despedida personalizada
/// - Loader horizontal animado
/// - Aguarda 6 segundos automaticamente
/// - Redireciona para primeira tab (Home)
class MainProfileExitScreenBackup extends StatefulWidget {
  const MainProfileExitScreenBackup({super.key});

  @override
  State<MainProfileExitScreenBackup> createState() => _MainProfileExitScreenBackupState();
}

class _MainProfileExitScreenBackupState extends State<MainProfileExitScreenBackup>
    with SingleTickerProviderStateMixin {
  late final AuthTokenManager _authManager;
  late AnimationController _progressController;
  Timer? _redirectTimer;
  String _userName = 'Usuário';

  @override
  void initState() {
    super.initState();
    _authManager = injector<AuthTokenManager>();
    _loadUserName();

    // Animação do loader (6 segundos)
    _progressController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    // Inicia animação e timer
    _progressController.forward();

    // Timer de 6 segundos para redirecionar
    _redirectTimer = Timer(const Duration(seconds: 6), _redirectToHome);
  }

  void _loadUserName() {
    final name = _authManager.getUserName();
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name;
      });
    }
  }

  void _redirectToHome() {
    if (!mounted) return;

    if (kDebugMode) {
      print('🏠 [MainProfileExitScreenBackup] Iniciando redirecionamento para home');
    }

    // ✅ Buscar HomeContentTabScreenState ANTES de fazer pop
    // Isso funciona porque ainda estamos na árvore de widgets
    HomeContentTabScreenState? homeState;
    
    context.visitAncestorElements((element) {
      if (element.widget is HomeContentTabScreen) {
        homeState = (element as StatefulElement).state as HomeContentTabScreenState;
        if (kDebugMode) {
          print('✅ [MainProfileExitScreenBackup] HomeContentTabScreen encontrado na árvore');
        }
        return false; // Para a busca
      }
      return true; // Continua subindo na árvore
    });

    if (homeState == null) {
      if (kDebugMode) {
        print('❌ [MainProfileExitScreenBackup] HomeContentTabScreen não encontrado');
      }
      // Fallback: apenas fazer pop
      Navigator.of(context).pop();
      return;
    }

    // Fazer pop para voltar à estrutura de tabs
    Navigator.of(context).pop();

    // Usar SchedulerBinding para garantir que o pop foi concluído
    // antes de resetar a tab (evita conflitos de estado)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (homeState != null) {
        if (kDebugMode) {
          print('🎯 [MainProfileExitScreenBackup] Resetando para primeira tab');
        }
        homeState!.resetToFirstTab();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Saudação personalizada
              Text(
                'Bem, $_userName...',
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
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Column(
                    children: [
                      // Barra de progresso
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
                      // Texto de tempo restante
                      Text(
                        'Redirecionando em ${(6 - (_progressController.value * 6)).ceil()}s...',
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
        ),
      ),
    );
  }
}

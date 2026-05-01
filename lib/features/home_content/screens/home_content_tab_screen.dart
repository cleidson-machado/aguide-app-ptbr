import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/main_contents/profile/screens/main_content_profile_screen.dart';
import 'package:portugal_guide/features/main_contents/relation/screens/main_relation_welcome_screen.dart';
import 'package:portugal_guide/features/main_contents/topic/screens/main_content_topic_screen.dart';
import 'package:portugal_guide/features/user_choice/user_choice_navigation_guard.dart';

//RE-APROVEITA OS CÓDIGOGOS E VOLTA O NOME HomeScreen SE NECESSÁRIO...

class HomeContentTabScreen extends StatefulWidget {
  const HomeContentTabScreen({super.key});

  @override
  HomeContentTabScreenState createState() => HomeContentTabScreenState();
}

class HomeContentTabScreenState extends State<HomeContentTabScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MainContentTopicScreen(), //###### TEMAS
    const MainRelationWelcomeScreen(), //#### RELAÇÕES (Tela de boas-vindas intermediária) ORIGINAL
    // const UserRelationNetworkScreen(), //#### RELAÇÕES TESTE // EM PAUSA DESDE 7-04-2026 PARA TESTE SISTEMA DE MENSAGENS - REAPROVEITAR DEPOIS
    // Esta tela NÃO deve ter NavigationBar com botão voltar (é uma TAB, não rota navegada) // ⚠️ TEMPORÁRIO: UsersMessageBucketScreen como TAB para testes
    //const UsersMessageBucketScreen(), // Tela Inicial de MENSAGENS - aqui ainda em estágio de teste, depois volta para a tela de boas-vindas de relações ou para a rede de relações
    const MainContentProfileScreen(), //### PERFIL / PROFILE
  ];

  /// Gerencia navegação das tabs da barra inferior
  /// 
  /// ⚠️ LÓGICA CONDICIONAL PARA TAB "RELAÇÕES" (index 1):
  /// - Consulta backend via UserChoiceNavigationGuard
  /// - SE user NÃO possui user-choice → main_relation_welcome_screen (onboarding)
  /// - SE user JÁ possui user-choice → connections_network_screen (rede)
  /// 
  /// 📚 Documentação: x_temp_files/DESIGN_RELATIONS_TAB_ROUTING.md
  Future<void> _onItemTapped(int index) async {
    // ✅ ROTEAMENTO CONDICIONAL para botão "RELAÇÕES" (index 1)
    if (index == 1) {
      if (kDebugMode) {
        print('📍 [HomeContentTabScreen] Botão RELAÇÕES tocado → verificando user-choice...');
      }

      final guard = injector<UserChoiceNavigationGuard>();
      final decision = await guard.checkRouteDecision();

      if (decision == RelationRouteDecision.welcome) {
        // Usuário NÃO possui user-choice → onboarding
        if (kDebugMode) {
          print('🎯 [HomeContentTabScreen] Navegando para welcome/onboarding');
        }
        Modular.to.navigate(AppRoutes.relationsWelcome);
      } else {
        // Usuário JÁ possui user-choice → connections network
        if (kDebugMode) {
          print('🎯 [HomeContentTabScreen] Navegando para connections network');
        }
        Modular.to.navigate(AppRoutes.relationsConnections);
      }
      return; // ← IMPORTANTE: Não executar setState abaixo
    }

    // Comportamento normal para outras tabs (TEMAS, PERFIL)
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Método público para resetar tab para o índice 0 (TEMAS)
  void resetToFirstTab() {
    if (kDebugMode) {
      print('📌 [HomeContentTabScreen] resetToFirstTab chamado');
      print('   Current index: $_selectedIndex');
    }
    
    if (mounted) {
      setState(() {
        _selectedIndex = 0;
      });
      
      if (kDebugMode) {
        print('✅ [HomeContentTabScreen] Tab resetada para 0');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ IndexedStack mantém todas as tabs vivas na árvore de widgets
      // Isso permite que AutomaticKeepAliveClientMixin funcione corretamente
      // Apenas alterna a visibilidade entre as tabs sem destruir os widgets
      body: IndexedStack(index: _selectedIndex, children: _pages),
      // ✅ Bottom navigation bar sempre visível (condição removida)
      // Antes escondia na tab 1 para MainStepperFormScreen, mas agora é Messages
      bottomNavigationBar: SafeArea(
        child: CupertinoTabBar(
          currentIndex: _selectedIndex,
          height: 65,
          iconSize: 35,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.news_solid,
              ), // ################################## https://cupertino-icons.web.app
              label: "TEMAS",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.arrow_up_arrow_down_square,
              ), // ################## https://cupertino-icons.web.app
              label: "RELAÇÕES",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.rectangle_stack_person_crop_fill,
              ), // ############ https://cupertino-icons.web.app
              label: "PERFIL",
            ),
          ],
        ),
      ),
    );
  }
}

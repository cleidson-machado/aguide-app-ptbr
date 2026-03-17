import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portugal_guide/features/main_contents/profile/screens/main_stepper_form_screen.dart';
import 'package:portugal_guide/features/main_contents/relation/screens/main_content_relation_screen.dart';
import 'package:portugal_guide/features/main_contents/topic/screens/main_content_topic_screen.dart';

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
    //const MainContentProfileScreen(), //#### RELAÇÕES Backup Old way
    const MainStepperFormScreen(), //#### RELAÇÕES
    const MainContentRelationScreen(), //### PERFIL
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Método público para resetar tab para o índice 0 (TEMAS)
  void resetToFirstTab() {
    if (mounted) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ IndexedStack mantém todas as tabs vivas na árvore de widgets
      // Isso permite que AutomaticKeepAliveClientMixin funcione corretamente
      // Apenas alterna a visibilidade entre as tabs sem destruir os widgets
      body: IndexedStack(index: _selectedIndex, children: _pages),
      // 🎯 SOLUÇÃO: Esconde bottomNavigationBar quando MainStepperFormScreen está ativa
      bottomNavigationBar: _selectedIndex == 1 ? null : SafeArea(
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

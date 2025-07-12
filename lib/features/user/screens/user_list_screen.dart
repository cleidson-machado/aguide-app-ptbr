import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/app/core/config/injector.dart'; // ##### dependency_injector ######: Importa o Service Locator!!
import 'package:portugal_guide/features/user/user_view_model.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:portugal_guide/util/error_messages.dart';
import 'package:portugal_guide/widgets/custom_cupertino_dialog_widget.dart';
import 'package:provider/provider.dart';

// MUDANÇA: A tela agora é um StatefulWidget para gerenciar o ciclo de vida da ViewModel.
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  // MUDANÇA: A ViewModel é obtida DIRETAMENTE do nosso Service Locator 'sl'.
  // Ela já vem pronta, com o repositório injetado!
  final UserViewModel viewModel = injector<UserViewModel>();

  @override
  void initState() {
    super.initState();
    // MUDANÇA: Chamamos o método para carregar os dados quando a tela é iniciada.
    viewModel.loadUsers();
  }

  @override
  void dispose() {
    // MUDANÇA: Boa prática para limpar os listeners do ChangeNotifier.
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MUDANÇA: Usamos ChangeNotifierProvider.value para FORNECER a instância
    // JÁ EXISTENTE da ViewModel para a árvore de widgets abaixo.
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<UserViewModel>(
        builder: (context, vm, child) {
          // A partir daqui, o código é praticamente IDÊNTICO ao seu original.
          // A única diferença é que usamos a variável 'vm' vinda do builder,
          // que é a mesma instância do nosso 'viewModel'.

          // Exibe o diálogo de erro se houver erro
          if (vm.error != null && vm.error!.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(context, '${vm.error}');
              // Limpa o erro após exibir para não mostrar o diálogo novamente
              // em reconstruções desnecessárias.
              vm.error = null;
            });
          }

          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(
                AppLocalizations.of(context)!.userSimpleListViewTitle,
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.arrow_down_doc_fill),
                onPressed: () {
                  // MUDANÇA: O botão de atualizar ficou mais simples!
                  // Não precisa mais de 'Provider.of', pois já temos a 'vm'.
                  if (!vm.isLoading) {
                    vm.loadUsers();
                  }
                },
              ),
            ),
            child: SafeArea(
              child: vm.isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(radius: 20.0),
                    )
                  : vm.users.isEmpty
                      ? const Center(
                          child: Text(
                            ErrorMessages.defaultMsnFailedToLoadData,
                            style: TextStyle(
                                fontSize: 18,
                                color: CupertinoColors.systemGrey),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: CupertinoListSection.insetGrouped(
                                  children: vm.users.map((user) {
                                    return CupertinoListTile(
                                      title: Text(user.name),
                                      subtitle: Text(user.email),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          );
        },
      ),
    );
  }
}

void _showErrorDialog(BuildContext context, String message) {
  customCupertinoDialog(context, message);
}
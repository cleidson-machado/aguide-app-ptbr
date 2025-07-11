import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user/user_view_model.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:portugal_guide/util/error_messages.dart';
import 'package:portugal_guide/widgets/custom_cupertino_dialog_widget.dart';
import 'package:provider/provider.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserViewModel()..loadUsers(),
      child: Consumer<UserViewModel>(
        builder: (context, viewModel, child) {
          // Exibe o diálogo de erro se houver erro
          if (viewModel.error != null && viewModel.error!.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(context, '${viewModel.error}');
              // Limpa o erro após exibir para não mostrar o diálogo novamente
              // em reconstruções desnecessárias.
              viewModel.error = null; 
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
                  if (!viewModel.isLoading) {
                    Provider.of<UserViewModel>(context, listen: false).loadUsers();
                  }
                },
              ),
            ),
            child: SafeArea(
              child: viewModel.isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(radius: 20.0),
                    )
                  : viewModel.users.isEmpty
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
                              children: viewModel.users.map((user) {
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
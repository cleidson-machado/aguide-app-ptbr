import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user/user_view_model.dart';
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
              _showErrorDialog(context, 'Erro: ${viewModel.error}');
            });
          }
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Moc List of Users'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.arrow_down_doc_fill),
                onPressed: () {
                  Provider.of<UserViewModel>(context, listen: false).loadUsers();
                },
              ),
            ),
            child: SafeArea(
              child: viewModel.users.isEmpty
                  ? const Center(
                      child: Text(
                        ErrorMessages.ERROR_FETCHING_USERS_MESSAGE,
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

// precsisamos continuar a usar o customCupertinoDialog nesse codigo atualizado
void _showErrorDialog(BuildContext context, String message) { 
  customCupertinoDialog(context, message);
}
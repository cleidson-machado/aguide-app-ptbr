import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/app/core/config/injector.dart'; // ##### dependency_injector ######: Importa o Service Locator!!
import 'package:portugal_guide/features/user/user_view_model.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:portugal_guide/util/error_messages.dart';
import 'package:portugal_guide/widgets/custom_cupertino_dialog_widget.dart';
import 'package:provider/provider.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserViewModel viewModel = injector<UserViewModel>();

  @override
  void initState() {
    super.initState();
    viewModel.loadUsers();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<UserViewModel>(
        builder: (context, userVm, child) {
          if (userVm.error != null && userVm.error!.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(context, '${userVm.error}');
              userVm.error = null;
            });
          }

          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              transitionBetweenRoutes: false,
              middle: Text(
                AppLocalizations.of(context)!.userSimpleListViewTitle,
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.arrow_down_doc_fill),
                onPressed: () {
                  if (!userVm.isLoading) {
                    userVm.loadUsers();
                  }
                },
              ),
            ),
            child: SafeArea(
              child:
                  userVm.isLoading
                      ? const Center(
                        child: CupertinoActivityIndicator(radius: 20.0),
                      )
                      : userVm.users.isEmpty
                      ? const Center(
                        child: Text(
                          ErrorMessages.defaultMsnFailedToLoadData,
                          style: TextStyle(
                            fontSize: 18,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      )
                      : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: CupertinoListSection.insetGrouped(
                                children:
                                    userVm.users.map((user) {
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

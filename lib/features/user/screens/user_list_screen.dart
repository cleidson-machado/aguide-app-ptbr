import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/app/core/rest_api_provider.dart';
import 'package:portugal_guide/features/user/user_controller.dart';
import 'package:portugal_guide/util/error_messages.dart';
import 'package:portugal_guide/widgets/custom_cupertino_dialog_widget.dart';
import 'package:provider/provider.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = Provider.of<RestApiProvider>(context);
    final String apiUrl = appConfig.apiUrl;

    return ChangeNotifierProvider(
      create: (_) => UserController(endpoint: apiUrl)..getUsers(),
      child: Consumer<UserController>(
        builder: (context, controller, child) {
          if (controller.error.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(context, 'Erro ${controller.error}');
            });
          }
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Moc List of Users'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.arrow_down_doc_fill),
                onPressed: () {Provider.of<UserController>(context, listen: false).getUsers();
                },
              ),
            ),
            child: SafeArea(
              child: controller.isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : controller.usersModel.isNotEmpty
                      ? Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: CupertinoListSection.insetGrouped(
                                  children: controller.usersModel.map((user) {
                                    return CupertinoListTile(
                                      title: Text(user.username),
                                      subtitle: Text(user.email),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text(
                            ErrorMessages.ERROR_FETCHING_USERS_MESSAGE,
                            style: TextStyle(
                                fontSize: 18,
                                color: CupertinoColors.systemGrey),
                          ),
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
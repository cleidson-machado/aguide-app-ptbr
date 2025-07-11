import 'package:flutter/cupertino.dart';

// Exibe um diálogo de alerta no estilo Cupertino, agora com um ícone
// e cor para destacar a mensagem de erro.
customCupertinoDialog(BuildContext context, String message) {
  return showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.systemBlue,
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 14,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),  
        
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
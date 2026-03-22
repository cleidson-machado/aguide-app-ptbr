// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';

class MainContentProfileSettingsScreen extends StatefulWidget {
  const MainContentProfileSettingsScreen({super.key});

  @override
  _MainContentProfileSettingsScreenState createState() =>
      _MainContentProfileSettingsScreenState();
}

class _MainContentProfileSettingsScreenState
    extends State<MainContentProfileSettingsScreen> {
  final Map<String, bool> _settings = {
    "Money Receive": false,
    "Card Activation": true,
    "Update Feature": false,
    "Cash In": false,
    "Money Request": false,
    "Money Transfer": false,
    "Number Notification": false,
    "Email Notification": false,
  };

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          "Minhas Preferências e Ajustes",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 12),
          children: _settings.entries.map((entry) {
            return CupertinoListTile(
              title: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _getSubtitle(entry.key),
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              trailing: CupertinoSwitch(
                value: entry.value,
                activeTrackColor: CupertinoColors.activeBlue,
                onChanged: (bool value) {
                  setState(() {
                    _settings[entry.key] = value;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getSubtitle(String key) {
    switch (key) {
      case "Money Receive":
        return "If anyone sent you money";
      case "Card Activation":
        return "If card active";
      case "Update Feature":
        return "If any new update come";
      case "Cash In":
        return "If any cash in your card";
      case "Money Request":
        return "If anyone sent you money request";
      case "Money Transfer":
        return "If you sent money to someone";
      case "Number Notification":
        return "Send notification to your number";
      case "Email Notification":
        return "Send notification to your email";
      default:
        return "";
    }
  }
}

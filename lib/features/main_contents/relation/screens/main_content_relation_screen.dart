// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';

class MainContentRelationScreen extends StatefulWidget {
  const MainContentRelationScreen({super.key});

  @override
  _MainContentRelationScreenState createState() => _MainContentRelationScreenState();
}

class _MainContentRelationScreenState extends State<MainContentRelationScreen> {
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
      navigationBar: const CupertinoNavigationBar(
        middle: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Guia - PORTUGAL",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "| PERFIL - Painel de Configuração |",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.systemPink,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          // Horizontal Navigation Section
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                _buildNavigationButton("Users List", () {
                  // Navigate to Users List
                }),
                _buildNavigationButton("Add New Tema", () {
                  // Navigate to Users List
                }),
                _buildNavigationButton("Transactions", () {
                  // Navigate to Transactions
                }),
                _buildNavigationButton("Settings", () {
                  // Navigate to Settings
                }),
                _buildNavigationButton("Reports", () {
                  // Navigate to Reports
                }),
                _buildNavigationButton("Reports", () {
                  // Navigate to Reports
                }),
                _buildNavigationButton("Reports", () {
                  // Navigate to Reports
                }),
              ],
            ),
          ),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 12),
              children: _settings.entries.map((entry) {
                return CupertinoListTile(
                  title: Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Text(_getSubtitle(entry.key), style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
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
        ],
      ),
    );
  }

  Widget _buildNavigationButton(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue),
          ),
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

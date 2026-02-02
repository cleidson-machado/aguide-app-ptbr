// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:country_flags/country_flags.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';

class MainContentRelationScreen extends StatefulWidget {
  const MainContentRelationScreen({super.key});

  @override
  _MainContentRelationScreenState createState() =>
      _MainContentRelationScreenState();
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
      navigationBar: CupertinoNavigationBar(
        middle: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Guia - PORTUGAL",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 6),
            Text(
              "| Painel de Configuração |",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.systemPink,
              ),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () {
            _popUpHandler(context);
          },
          child: const Icon(CupertinoIcons.globe, size: 24),
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
              children:
                  _settings.entries.map((entry) {
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
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

  Future<dynamic> _popUpHandler(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Text(
              AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
            ),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('pt', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'BR',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languagePortuguese ??
                          'Portuguese',
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('en', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'US',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languageEnglish ??
                          'English',
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('es', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'ES',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languageSpanish ??
                          'Spanish',
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Provider.of<AppLocaleProvider>(
                    context,
                    listen: false,
                  ).changeLocale(const Locale('fr', ''));
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryFlag.fromCountryCode(
                      'FR',
                      height: 16,
                      width: 24,
                      shape: const RoundedRectangle(4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.languageFrench ?? 'French',
                    ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
          ),
    );
  }
}

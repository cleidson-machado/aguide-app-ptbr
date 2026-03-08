// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:country_flags/country_flags.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_details_view_model.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'user_preferences_settings_screen.dart';

class MainContentRelationScreen extends StatefulWidget {
  const MainContentRelationScreen({super.key});

  @override
  _MainContentRelationScreenState createState() =>
      _MainContentRelationScreenState();
}

class _MainContentRelationScreenState extends State<MainContentRelationScreen> {
  final UserDetailsViewModel viewModel = injector<UserDetailsViewModel>();

  @override
  void initState() {
    super.initState();
    // Carregar detalhes do usuário (ID hardcoded do exemplo fornecido)
    viewModel.loadUserDetails('aa736f39-4f54-4741-a6c4-6d7b0ba6e7cf');
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  void _navigateToPreferences() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const UserPreferencesSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
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
                _buildNavigationButton("Minhas Preferências e Ajustes", () {
                  _navigateToPreferences();
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

          // Conteúdo Principal
          Expanded(
            child: ChangeNotifierProvider.value(
              value: viewModel,
              child: Consumer<UserDetailsViewModel>(
                builder: (context, vm, child) {
                  if (vm.isLoading) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }

                  if (vm.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          '❌ ${vm.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!vm.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "📋 Nenhum dado de usuário disponível.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    );
                  }

                  final user = vm.userDetails!;
                  return _buildUserDetailsContent(user);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsContent(user) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👤 Informações do Usuário',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Nome Completo', user.fullName),
                const SizedBox(height: 8),
                _buildInfoRow('Nome', user.name),
                const SizedBox(height: 8),
                _buildInfoRow('Sobrenome', user.surname),
                const SizedBox(height: 8),
                _buildInfoRow('E-mail', user.email),
                const SizedBox(height: 8),
                _buildInfoRow('Role', user.role, color: CupertinoColors.systemPink),
                const SizedBox(height: 8),
                _buildInfoRow('Status', user.active ? 'Ativo ✅' : 'Inativo ❌'),
                const SizedBox(height: 8),
                _buildInfoRow('Criado em', dateFormat.format(user.createdAt)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Telefones Card
          const Text(
            '📞 Telefones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(height: 12),
          
          if (user.phones.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Nenhum telefone cadastrado',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...user.phones.map((phone) => _buildPhoneCard(phone)).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? CupertinoColors.label,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneCard(phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: phone.isPrimary 
              ? CupertinoColors.systemGreen 
              : CupertinoColors.systemGrey5,
          width: phone.isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                phone.type == 'MOBILE' 
                    ? CupertinoIcons.phone_fill 
                    : CupertinoIcons.device_phone_portrait,
                color: phone.isPrimary 
                    ? CupertinoColors.systemGreen 
                    : CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phone.formattedNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: phone.isPrimary ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (phone.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge(
                'Tipo',
                phone.type,
                color: CupertinoColors.systemBlue,
              ),
              if (phone.isVerified)
                _buildBadge(
                  '✓',
                  'Verificado',
                  color: CupertinoColors.systemGreen,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (phone.hasWhatsApp)
                _buildAppBadge('WhatsApp', CupertinoColors.systemGreen),
              if (phone.hasTelegram)
                _buildAppBadge('Telegram', CupertinoColors.systemBlue),
              if (phone.hasSignal)
                _buildAppBadge('Signal', CupertinoColors.systemIndigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String value, {required Color color}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAppBadge(String appName, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        appName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
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

// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_details_view_model.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_preferences_settings_screen.dart';

class MainContentRelationScreen extends StatefulWidget {
  const MainContentRelationScreen({super.key});

  @override
  _MainContentRelationScreenState createState() =>
      _MainContentRelationScreenState();
}

class _MainContentRelationScreenState extends State<MainContentRelationScreen> {
  final UserDetailsViewModel viewModel = injector<UserDetailsViewModel>();
  final AuthTokenManager _tokenManager = injector<AuthTokenManager>();

  @override
  void initState() {
    super.initState();
    // Carregar detalhes do usuário logado (userId extraído do token JWT)
    final userId = _tokenManager.getUserId();
    if (userId != null) {
      viewModel.loadUserDetails(userId);
    } else {
      // Se não houver userId no token, definir erro no viewModel
      viewModel.setError('Usuário não autenticado. Por favor, faça login novamente.');
    }
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
          Container(
            height: 70,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Avatar Mocado
          _buildMockedAvatar(),
          
          const SizedBox(height: 20),
          
          // Nome Completo
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Emblema OAuth Provider ou Local User
          _buildOAuthProviderBadge(user.oauthProvider),
          
          const SizedBox(height: 16),
          
          // E-mail
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E-mail',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.label,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Role
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.role,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Seção de Telefones
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TELEFONES',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de Telefones
          if (user.phones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum telefone cadastrado',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...user.phones.map((phone) {
              return phone.isPrimary 
                  ? _buildPrimaryPhoneCard(phone)
                  : _buildSecondaryPhoneCard(phone);
            }).toList(),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Avatar mocado circular
  Widget _buildMockedAvatar() {
    // ════════════════════════════════════════════════════════════════════════════
    // ⚠️  TODO: IMPLEMENTAR ARMAZENAMENTO E EXIBIÇÃO DE FOTO DE PERFIL DO USUÁRIO
    // ════════════════════════════════════════════════════════════════════════════
    // PENDENTE: Definir estratégia de armazenamento de imagens de perfil:
    //   - Opção 1: Cloud Storage (AWS S3, Firebase Storage, etc.)
    //   - Opção 2: CDN própria
    //   - Opção 3: Base64 no banco de dados (não recomendado para produção)
    // 
    // Após decisão, atualizar UserDetailsModel para incluir campo photoUrl
    // e substituir URL mockada abaixo pela URL real do usuário.
    // ════════════════════════════════════════════════════════════════════════════
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          const CircleAvatar(
            radius: 60, // 120px de diâmetro total
            backgroundImage: NetworkImage(
              "https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // TODO: Implementar lógica de troca de imagem
              // Opções: Câmera, Galeria, Remover foto
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.black,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                CupertinoIcons.pencil,
                color: CupertinoColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Emblema/Badge do OAuth Provider ou Local User
  Widget _buildOAuthProviderBadge(String? oauthProvider) {
    // Determinar cor e ícone baseado no provider
    Color badgeColor;
    IconData badgeIcon;
    String displayText;
    Color textColor;

    // Se for null, é um usuário local restrito
    if (oauthProvider == null) {
      badgeColor = const Color(0xFFFFCDD2); // Vermelho claro (Red 100)
      badgeIcon = CupertinoIcons.person_crop_circle_badge_xmark;
      displayText = 'Restricted Local User';
      textColor = CupertinoColors.black;
    } else {
      textColor = CupertinoColors.white;
      
      switch (oauthProvider.toUpperCase()) {
      case 'GOOGLE':
        badgeColor = const Color(0xFF4285F4); // Google Blue
        badgeIcon = CupertinoIcons.globe;
        displayText = 'Google Account';
        break;
      case 'FACEBOOK':
        badgeColor = const Color(0xFF1877F2); // Facebook Blue
        badgeIcon = CupertinoIcons.person_circle_fill;
        displayText = 'Facebook Account';
        break;
      case 'APPLE':
        badgeColor = CupertinoColors.black;
        badgeIcon = CupertinoIcons.device_phone_portrait;
        displayText = 'Apple ID';
        break;
      case 'LINKEDIN':
        badgeColor = const Color(0xFF0A66C2); // LinkedIn Blue
        badgeIcon = CupertinoIcons.briefcase_fill;
        displayText = 'LinkedIn Account';
        break;
        default:
          badgeColor = const Color(0xFF6C757D); // Cinza neutro
          badgeIcon = CupertinoIcons.checkmark_seal_fill;
          displayText = '$oauthProvider Account';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Card do telefone principal (destacado)
  Widget _buildPrimaryPhoneCard(phone) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone de telefone mocado (verde)
          _buildMockedPhoneIcon(isGreen: true, size: 40),
          
          const SizedBox(width: 16),
          
          // Informações do telefone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phone.formattedNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildPhoneSubtitle(phone),
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Ícones de apps (WhatsApp, Telegram)
          Column(
            children: [
              if (phone.hasWhatsApp)
                GestureDetector(
                  onTap: () => _openWhatsApp(phone.fullNumber),
                  child: _buildMockedWhatsAppIcon(size: 36),
                ),
              if (phone.hasWhatsApp && phone.hasTelegram)
                const SizedBox(height: 8),
              if (phone.hasTelegram)
                GestureDetector(
                  onTap: () => _openTelegram(phone.fullNumber),
                  child: _buildMockedTelegramIcon(size: 36),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Card de telefone secundário (menor)
  Widget _buildSecondaryPhoneCard(phone) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Número
          Expanded(
            child: Text(
              phone.formattedNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ),
          
          // Ícones de apps
          if (phone.hasWhatsApp)
            GestureDetector(
              onTap: () => _openWhatsApp(phone.fullNumber),
              child: _buildMockedWhatsAppIcon(size: 28),
            ),
          if (phone.hasWhatsApp && phone.hasTelegram)
            const SizedBox(width: 8),
          if (phone.hasTelegram)
            GestureDetector(
              onTap: () => _openTelegram(phone.fullNumber),
              child: _buildMockedTelegramIcon(size: 28),
            ),
        ],
      ),
    );
  }

  // Constrói o subtítulo do telefone (Principal • Celular • Verificado)
  String _buildPhoneSubtitle(phone) {
    final parts = <String>[];
    
    if (phone.isPrimary) parts.add('Principal');
    if (phone.type == 'MOBILE') parts.add('Celular');
    if (phone.type == 'LANDLINE') parts.add('Fixo');
    if (phone.isVerified) parts.add('Verificado');
    
    return parts.join(' • ');
  }

  // Ícone de telefone mocado (placeholder)
  Widget _buildMockedPhoneIcon({bool isGreen = false, double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isGreen ? const Color(0xFF34C759) : CupertinoColors.systemGrey3,
      ),
      child: Icon(
        CupertinoIcons.phone_fill,
        size: size * 0.5,
        color: CupertinoColors.white,
      ),
    );
  }

  // Ícone do WhatsApp mocado (placeholder - verde)
  // TODO: Substituir por imagem PNG com fundo transparente
  Widget _buildMockedWhatsAppIcon({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF25D366), // Verde WhatsApp
      ),
      child: Center(
        child: Text(
          'W',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  // Ícone do Telegram mocado (placeholder - azul)
  // TODO: Substituir por imagem PNG com fundo transparente
  Widget _buildMockedTelegramIcon({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF0088CC), // Azul Telegram
      ),
      child: Center(
        child: Text(
          'T',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  // Abre WhatsApp com o número (deep link)
  void _openWhatsApp(String phoneNumber) async {
    // Remove caracteres não numéricos
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('https://wa.me/$cleanNumber');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showErrorDialog('Não foi possível abrir o WhatsApp');
      }
    }
  }

  // Abre Telegram com o número (deep link)
  void _openTelegram(String phoneNumber) async {
    // Remove caracteres não numéricos
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('https://t.me/$cleanNumber');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showErrorDialog('Não foi possível abrir o Telegram');
      }
    }
  }

  // Mostra diálogo de erro
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
                Color.fromARGB(255, 67, 123, 208), // Azul profundo
                Color.fromARGB(255, 92, 111, 119), // Ciano vibrante
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: CupertinoColors.white,
              letterSpacing: 0.3,
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

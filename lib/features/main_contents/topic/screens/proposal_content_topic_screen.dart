import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';

class ProposalMainContentTopicScreen extends StatelessWidget {
  const ProposalMainContentTopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainContentTopicViewModel()..loadAllContents(),
      child: Consumer<MainContentTopicViewModel>(
        builder: (context, vm, child) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text(">> Perfil de Consumidor - Default <<"),
              trailing: GestureDetector(
                onTap: () => _showLanguageModal(context),
                child: const Icon(CupertinoIcons.globe, size: 24),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CupertinoSearchTextField(
                    onChanged: (value) {
                      vm.searchContents(value);
                    },
                  ),
                ),
                Expanded(
                  child: _buildBody(vm),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(MainContentTopicViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (vm.error != null) {
      return Center(child: Text(vm.error!));
    }
    if (vm.contents.isEmpty) {
      return const Center(child: Text("Nenhum conteúdo encontrado."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: vm.contents.length,
      itemBuilder: (context, index) {
        final content = vm.contents[index];
        return Column(
          children: [
            _buildBlogCard(content),
            const Divider(color: CupertinoColors.systemGrey4),
          ],
        );
      },
    );
  }

  Widget _buildBlogCard(MainContentTopicModel content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  content.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              content.contentImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: CupertinoColors.systemGrey5,
                  child: const Icon(
                    CupertinoIcons.photo,
                    color: CupertinoColors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
        ),
        actions: <CupertinoActionSheetAction>[
          _buildLangAction(context, 'pt', 'BR',
              AppLocalizations.of(context)?.languagePortuguese ?? 'Portuguese'),
          _buildLangAction(context, 'en', 'US',
              AppLocalizations.of(context)?.languageEnglish ?? 'English'),
          _buildLangAction(context, 'es', 'ES',
              AppLocalizations.of(context)?.languageSpanish ?? 'Spanish'),
          _buildLangAction(context, 'fr', 'FR',
              AppLocalizations.of(context)?.languageFrench ?? 'French'),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _buildLangAction(
      BuildContext context, String langCode, String countryCode, String label) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Provider.of<AppLocaleProvider>(context, listen: false)
            .changeLocale(Locale(langCode, ''));
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CountryFlag.fromCountryCode(
            countryCode,
            height: 16,
            width: 24,
            shape: const RoundedRectangle(4),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';

class MainContentTopicScreen extends StatefulWidget {
  const MainContentTopicScreen({super.key});

  @override
  State<MainContentTopicScreen> createState() => _MainContentTopicScreenState();
}

class _MainContentTopicScreenState extends State<MainContentTopicScreen> {
  final MainContentTopicViewModel viewModel = injector<MainContentTopicViewModel>();

  @override
  void initState() {
    super.initState();
    viewModel.loadAllContents();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(">> Perfil de Consumidor - Default <<"),
        trailing: GestureDetector(
          onTap: () {
            _popUpHandler(context);
          },
          child: const Icon(CupertinoIcons.globe, size: 24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: CupertinoSearchTextField(
              onChanged: (value) {
                viewModel.searchContents(value);
              },
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: viewModel,
              builder: (context, child) {
                return _buildBody();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (viewModel.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    
    if (viewModel.error != null) {
      return Center(
        child: Text(
          viewModel.error!,
          style: const TextStyle(color: CupertinoColors.systemRed),
        ),
      );
    }
    
    if (viewModel.contents.isEmpty) {
      return const Center(child: Text("Nenhum conteúdo encontrado."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: viewModel.contents.length,
      itemBuilder: (context, index) {
        final content = viewModel.contents[index];
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
                  content.description, // Usando description no lugar de subtitle
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
              content.contentImageUrl, // Usando contentImageUrl no lugar de image
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

  Future<dynamic> _popUpHandler(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
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
                  AppLocalizations.of(context)?.languagePortuguese ?? 'Portuguese',
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
                  AppLocalizations.of(context)?.languageEnglish ?? 'English',
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
                  AppLocalizations.of(context)?.languageSpanish ?? 'Spanish',
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
          child: Text(
            AppLocalizations.of(context)?.cancel ?? 'Cancel',
          ),
        ),
      ),
    );
  }
}
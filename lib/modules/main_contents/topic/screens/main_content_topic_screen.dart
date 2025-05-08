import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';

/// 📝 Main Screen - This will Be a List of register contents or any stuff shared by a User...
/// NOTE: REMEMBER!! REBUILD THIS SCREEN TO MATCH YOUR RESPECTIVE MODEL CLASS................ lib/modules/main_contents/topic/main_content_topic_model.dart
class MainContentTopicScreen extends StatelessWidget {
  const MainContentTopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> blogPosts = List.generate(25, (index) {
      return {
        "title": "Blog Post ${index + 1}",
        "subtitle": "Short description of the blog post.",
        "image": "https://picsum.photos/200/300?random=$index",
      };
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(">> Perfil de Consumidor - Default <<"),
        trailing: GestureDetector(
          // Na classe MainContentTopicScreen, atualize o método onTap
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              builder:
                  (BuildContext context) => CupertinoActionSheet(
                    title: Text(
                      AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
                    ),
                    actions: <CupertinoActionSheetAction>[
                      CupertinoActionSheetAction(
                        onPressed: () {
                          // ###################################################### Mudar para Português 
                          Provider.of<LocaleProvider>(
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
                            Text(AppLocalizations.of(context)?.languagePortuguese ?? 'Portuguese'),
                          ],
                        ),
                      ),
                      CupertinoActionSheetAction(
                        onPressed: () {
                          // ###################################################### Mudar para Inglês
                          Provider.of<LocaleProvider>(
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
                            Text(AppLocalizations.of(context)?.languageEnglish ?? 'English'),
                          ],
                        ),
                      ),
                      CupertinoActionSheetAction(
                        onPressed: () {
                          // ###################################################### Mudar para Espanhol
                          Provider.of<LocaleProvider>(
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
                            Text(AppLocalizations.of(context)?.languageSpanish ?? 'Spanish'),
                          ],
                        ),
                      ),
                      CupertinoActionSheetAction(
                        onPressed: () {
                          // ###################################################### Mudar para Francês
                          Provider.of<LocaleProvider>(
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
                            Text(AppLocalizations.of(context)?.languageFrench ?? 'French'),
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
          },
          child: const Icon(CupertinoIcons.globe, size: 24),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: CupertinoSearchTextField(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: blogPosts.length,
              itemBuilder: (context, index) {
                final post = blogPosts[index];
                return Column(
                  children: [
                    _buildBlogCard(post),
                    const Divider(color: CupertinoColors.systemGrey4),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogCard(Map<String, String> post) {
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
                  post["title"]!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post["subtitle"]!,
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
              post["image"]!,
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
}

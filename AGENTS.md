# AGENTS.md — portugal_guide

Guia para agentes que alteram este repositório. Descreve o que o código e os ficheiros de configuração fazem hoje. A referência longa de arquitetura continua em [`.github/copilot-instructions.md`](.github/copilot-instructions.md); este ficheiro não a substitui nem a copia.

Não há `package.json`. O manifesto é [`pubspec.yaml`](pubspec.yaml). O nome do pacote Dart é `portugal_guide`.

## 1. Visão geral e stack

App Flutter para brasileiros que planeiam morar, trabalhar ou viajar em Portugal. `publish_to: none`, versão `1.0.0+1`.

| Peça | O que o repositório usa |
|---|---|
| SDK | Dart `>=3.13.5 <4.0.0`, Flutter `>=3.47.6` (`pubspec.yaml`) |
| UI | `CupertinoApp.router` em `lib/app/app_custom_main_widget.dart`. `uses-material-design: true` no pubspec. `Material` aparece em ecrãs pontuais (por exemplo a tab home e um ecrã de teste do chatbot), não como app raiz |
| Rotas | `flutter_modular` (`AppRouteModule` + `CustomRouteManager`) |
| Injeção | **GetIt** em `lib/app/core/config/injector.dart`. `provider` só para tema e locale. O Modular está no projeto por causa das rotas; os repositórios e ViewModels registam-se no GetIt |
| Estado | ViewModels que estendem `ChangeNotifier` |
| HTTP | **Dio** na maioria dos repositórios (via `GenCrudRepository` e `AuthHttpInterceptor`). **`package:http`** em `auth_credentials`, `auth_google` e em `lib/util/http_client_helper.dart`. Os dois clientes coexistem |
| Configuração | `flutter_dotenv`. `main.dart` carrega `.env.prod`. Chaves lidas por `EnvKeyHelperConfig` |
| i18n | ARB + `flutter gen-l10n`. Idiomas: `en` (template), `pt`, `es`, `fr` |
| Persistência local | `shared_preferences` (`AuthTokenManager` e prefs gerais) |
| Imagens remotas | `cached_network_image` nos ecrãs que mostram thumbnail de rede |

Toolchain Android **dos ficheiros Gradle** (fonte a seguir quando o README divergir):

- Android Gradle Plugin `9.0.1` e Kotlin `2.3.20` em `android/settings.gradle.kts`
- Gradle `9.1.0` em `android/gradle/wrapper/gradle-wrapper.properties`
- Java source/target 17 em `android/app/build.gradle.kts`
- `android.builtInKotlin=false` e `android.newDsl=false` em `android/gradle.properties`
- Cache Gradle/Kotlin e compilação incremental Kotlin desligados no mesmo ficheiro, com comentário a apontar para Kotlin `>= 2.4.20`
- `compileSdk`, `ndkVersion`, `minSdk` e `targetSdk` vêm de `flutter.*`, não estão fixos no `build.gradle.kts`
- `applicationId` / `namespace`: `br.com.aguideptbr.portugal_guide`
- O `release` ainda assina com a config `debug` (TODO no Gradle)

iOS: `IPHONEOS_DEPLOYMENT_TARGET = 15.0` nas configurações do `Runner` em `ios/Runner.xcodeproj/project.pbxproj`.

O [`README.md`](README.md) ainda descreve AGP 8.11.1, Gradle 8.14.3 e Kotlin 2.2.20. Isso não corresponde aos ficheiros Gradle acima. Para versões de SDK, NDK e Xcode, o README e [`FLUTTER_BUILD_COMMANDS.md`](FLUTTER_BUILD_COMMANDS.md) são o sítio onde o projeto as documenta; não as duplique a partir de memória.

## 2. Estrutura de pastas

```
.
├── lib/
│   ├── main.dart                 # dotenv, GetIt, Provider, ModularApp
│   ├── app/
│   │   ├── app_custom_main_widget.dart
│   │   ├── core/
│   │   │   ├── auth/             # token, interceptor Dio, erros de auth
│   │   │   ├── base/             # BaseModel (id + toMap)
│   │   │   ├── config/           # injector.dart, correlation id
│   │   │   └── repositories/     # GenCrudRepository + interface
│   │   ├── helpers/              # EnvKeyHelperConfig, widget de erro de .env
│   │   ├── routing/              # AppRoutes, AppRouteModule, CustomRouteManager
│   │   ├── routing_guards/       # AuthGuard, OwnerContentGuard
│   │   └── theme/                # AppThemeProvider (Cupertino light/dark)
│   ├── features/                 # um bounded context por pasta
│   ├── resources/
│   │   ├── l10n/                 # app_en.arb, app_pt.arb, app_es.arb, app_fr.arb
│   │   ├── translation/          # AppLocalizations gerado
│   │   └── locale_provider.dart
│   ├── util/                     # http autenticado, excepções, mensagens de erro
│   └── widgets/                  # widgets Cupertino reutilizáveis
├── test/features/                # testes (hoje: compatibilidade de SDK/UI)
├── assets/                       # icon, promo, animated, forms
├── android/  ios/
├── x_temp_files/                 # rascunhos, JSON de exemplo, notas de análise
└── .github/copilot-instructions.md
```

Não há pasta `linux/`, `web/`, `windows/` ou `macos/` no working tree, embora `.metadata` liste essas plataformas como migráveis.

### `lib/features/`

Cada pasta é um contexto. A forma interna **não é uniforme**: umas têm `screens/`, `models/`, `viewmodels/`, `widgets/`; outras deixam model, repositório e ViewModel na raiz da feature.

| Pasta | Papel no código actual |
|---|---|
| `auth_credentials` | Login/registo na API própria. Service com `package:http`, não Dio |
| `auth_google` | Google Sign-In. Service, mock service, ViewModel, ecrã |
| `user` | Utilizador, telefone, lista e detalhes. Repositórios Dio que estendem o CRUD genérico |
| `main_contents/topic` | Conteúdos (`/contents`), ordenação, ownership |
| `main_contents/profile` | Perfil e definições (inclui escolha de idioma) |
| `main_contents/relation` | Onboarding de relações, stepper, ecrãs e backups |
| `home_content` | Tab principal depois do login: temas, relações, perfil |
| `topic_viewer_by_user` | Leitura de tópicos por utilizador. Adapta ownership para o model de topic |
| `user_choice` | Escolha/onboarding e `UserChoiceNavigationGuard` (a tab Relações decide o destino) |
| `user_verified_content` | Wizard de conteúdo verificado |
| `user_message_flow` | Conversas, bucket, modelos próprios (`MessageUserData`) e notificação in-app |
| `user_relation_network` | Rede de ligações. Model local, não o de `main_contents/relation` |
| `user_tracking_data` | Pontos, histórico, leaderboard |
| `user_engagement` | Metadados de sessão/dispositivo/rede |
| `user_promo_main_contents` | Slider de promoção, rota própria |
| `user_promo_start_app` | Pasta de promoção no arranque (só `screens/` no tree) |
| `chatbot` | Chat com service/controller. Inclui ecrãs de teste (`test_main_chat_screen_code_*.dart`) |

Rotas vivas em `AppRouteModule`: `/` e `/login` (login), `/home`, slider de promo, wizard de verificação, welcome de relações, rede de relações, bucket de mensagens, topic viewer. `AppRoutes` ainda declara `/admin` e `/sales`, mas essas entradas estão comentadas no module.

`AuthGuard` existe e está mapeado só para admin/sales. `canActivate` devolve sempre `false` (comentário no ficheiro: simulação). Não trate isto como autorização real.

Contextos que outros importam e que não se devem dobrar para um caso de uso local: `user`, `auth_credentials`, `auth_google`, `main_contents`. O resto adapta-se. Exemplos já no código: `TopicViewerContentAdapter` e `MessageUserData` em `user_message_flow`.

## 3. Comandos

Não há scripts npm. Comandos do dia a dia:

```bash
flutter pub get
flutter run
flutter analyze
dart format .
flutter test
flutter gen-l10n
```

`analysis_options.yaml` inclui `package:flutter_lints/flutter.yaml` e exclui `build/**`, `android/**`, `ios/**`. Nenhuma regra extra está activa (`prefer_single_quotes` está comentada).

Builds documentados no README e em `.vscode/tasks.json` (as tasks usam `--no-pub`; corra `flutter pub get` antes):

```bash
flutter build apk --debug
flutter build appbundle --release
flutter build ios --debug --simulator
flutter build ios --release --no-codesign
```

Scripts na raiz:

| Script | O que faz |
|---|---|
| `./android_build_check.sh` | `flutter doctor`, **`flutter clean`**, `pub get`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter build apk --debug` |
| `./ios_build_check.sh` | O equivalente para simulador iOS. Só em macOS. Também faz `flutter clean` |
| `./android_build_apks.sh` | Procura `pubspec.yaml` e corre `flutter build apk --release` |
| `./test_google_oauth_fix.sh` | `flutter clean`, `pub get`, **apaga `ios/Pods` e `ios/Podfile.lock`**, `pod install --repo-update`, e arranca o simulador |

`flutter analyze` sem flags é a verificação estrita. `--no-fatal-infos` é o que os scripts de build check usam: infos aparecem e não falham o script; erros e warnings falham.

Não corra os scripts de check (eles fazem `flutter clean`) em paralelo com `flutter run` ou com outro build. O README pede para preservar `pubspec.lock`, `ios/Podfile.lock` e os `Package.resolved` do Xcode. `test_google_oauth_fix.sh` apaga o `Podfile.lock`; não o use como verificação de rotina.

Depois de editar ARB: `flutter gen-l10n` (ou o próximo `flutter pub get` / build, porque `flutter: generate: true` e [`l10n.yaml`](l10n.yaml) apontam `arb-dir` para `lib/resources/l10n` e a saída para `lib/resources/translation/app_localizations.dart`).

Uma alteração pequena de UI não precisa de build nativo completo. Mudança de `pubspec.yaml` ou de código nativo justifica `flutter analyze` e, quando o âmbito for grande, os scripts de check.

## 4. Convenções observadas no código

**Nomes.** Ficheiros em `snake_case`, com o prefixo da feature: `user_repository.dart`, `user_repository_interface.dart`, `user_list_view_model.dart`. Ecrãs terminam em `_screen.dart`. Imports usam `package:portugal_guide/...`.

**View.** Widgets Cupertino. Voltar com `CupertinoNavigationBarBackButton` onde há barra de navegação. A shell pós-login é `HomeContentTabScreen` (`IndexedStack` de tabs). Uma tab não se fecha com `Navigator.pop()`.

**ViewModel.** Estende `ChangeNotifier`. Estado privado, leitura por getter, escrita seguida de `notifyListeners()`. O repositório entra pelo construtor, tipado pela interface (`UserListViewModel` é o exemplo limpo).

**Model.** `BaseModel` exige `id` e `toMap()`. O padrão em `UserModel` é `fromMap` / `toMap`, `fromJson` / `toJson`, `copyWith`, `==` e `hashCode`. Os campos nem sempre são `final` (em `UserModel`, `name`, `surname` e `email` são mutáveis). Siga o model da feature que está a editar; não imponha imutabilidade a um model partilhado só para alinhar estilo.

**Repositório.** Interface `*RepositoryInterface` que muitas vezes estende `GenCrudRepositoryInterface<T>`. Implementação concreta estende `GenCrudRepository<T>` **ou** implementa a interface à mão. `GenCrudRepository` recebe `endpoint`, `fromMap` e um `Dio` opcional. Novos endpoints de feature passam por `EnvKeyHelperConfig` (`apiBaseUrl` e afins), como `MainContentTopicRepository` e `AuthCredentialsService`. Não escreva URL de API no ecrã.

**Registo.** Interface e serviço: `registerLazySingleton` em `injector.dart`. ViewModel: `registerFactory`. O cliente `http.Client` e o `SharedPreferences` também nascem ali. Se criar um tipo injectável, registe-o nesse ficheiro; o Modular não é o contentor usado pelos ViewModels.

**i18n.** Texto de UI que já tem chave vem de `AppLocalizations.of(context)`, com fallback quando o ecrã já faz isso (`?.selectLanguage ?? '...'` no perfil). Chaves novas entram nos quatro ARB. Locale inicial: idioma do dispositivo se for `en`, `es`, `pt` ou `fr`; senão `en` (`AppLocaleProvider`).

**Log.** Código recente guarda `debugPrint` com `kDebugMode` (`UserListViewModel`, `AuthCredentialsService`, `AuthHttpInterceptor`). Há muito `print` antigo, por vezes com `// ignore_for_file: avoid_print`. Código novo usa `debugPrint` dentro de `kDebugMode`. Não use o `Logger` global de `main.dart` para dados de pessoa, token ou password. O interceptor já corta o token no log de debug; mantenha esse corte.

**Listas e imagem.** Onde a lista é dinâmica, os itens levam `ValueKey`. Thumbnail remoto usa `CachedNetworkImage`.

**Testes.** `flutter_test`, em `test/features/...`. O único teste presente (`test/features/app/flutter_sdk_compatibility_test.dart`) cobre fontes, tema Cupertino, locales e skeleton, com `addTearDown` no `ChangeNotifier`. Não há `mockito` no `pubspec.yaml`. Teste novo não chama rede nem lê `.env` real.

**Ficheiros que não são produção.** Rascunho, JSON de exemplo e nota de análise vão para `x_temp_files/`. Teste vai para `test/features/[feature]/`. Backup de ecrã, quando for pedido, fica ao lado do original com sufixo `_backup.dart` (já há vários em `main_contents`). Não crie ficheiro de apoio na raiz.

**Lint que o analyzer já aplica.** `flutter_lints` inclui `avoid_print`. Não desligue a regra no `analysis_options.yaml` para fazer um ficheiro passar. Um `ignore` pontual só se o ficheiro já viver assim e a tarefa não for limpá-lo.

## 5. Práticas a seguir

1. **Classifique a feature antes de editar.** Se o alvo é `user`, `auth_credentials`, `auth_google` ou `main_contents`, procure quem importa `lib/features/<essa pasta>/`. Mudança de interface, de retorno público de ViewModel ou de model partilhado afecta consumidores. Nesse caso, adapte na feature que precisa do dado (`TopicViewerContentAdapter` é o precedente). Não invente método de repositório para um endpoint que não esteja já chamado no código ou confirmado por quem mantém a API.
2. **A menor diff que resolve o pedido.** Sem renomear em massa, sem “alinhar” Dio e `http`, sem mover ecrãs de teste do chatbot.
3. **Erro de rede na UI.** `try/catch` no ViewModel, mensagem via i18n ou `lib/util/error_messages.dart`, sem stack trace no widget. `UserListViewModel.loadUsers` é a forma: liga loading, limpa o erro, chama o repositório, mapeia a excepção, `notifyListeners` no `finally`.
4. **Dispose.** `ScrollController`, `TextEditingController`, `Timer` e o ViewModel criado no ecrã libertam-se no `dispose`.
5. **Segredos.** URL, token e client id só via `EnvKeyHelperConfig` / `.env.*`. Esses ficheiros já estão em `assets` do pubspec; não copie valores para código, teste, log ou para este documento. Há ficheiros de cliente OAuth na raiz do repo; não os duplique nem os cite com o conteúdo.
6. **O bypass de certificado em `main.dart` (`MyHttpOverrides`) está marcado no próprio ficheiro como só para teste local.** Não o replique noutra feature nem o trate como configuração de produção.
7. **Não dê `Navigator.pop()` para sair de uma tab** de `HomeContentTabScreen`. Feche o dialog; o índice da tab muda no estado do pai.
8. **Dependência nova, lockfile, Gradle, CI ou contrato de API:** pare e peça confirmação. Confira no pub.dev se o pacote suporta Android e iOS e se não exige Dart acima de `3.13.5` nem um AGP acima do que `settings.gradle.kts` fixa (`9.0.1`).
9. **Git.** Não faça commit, push, nem mude de branch sem pedido explícito. Não use `git add .` / `git add -A`. Não faça commit em `main`/`master`. Mensagem no formato Conventional Commits quando um commit for pedido.

### Onde olhar antes de uma alteração grande

- Injeção e ordem de registo: `lib/app/core/config/injector.dart`
- Rotas: `lib/app/routing/app_routes.dart` e `app_route_module.dart`
- Contrato CRUD: `lib/app/core/repositories/`
- Regras longas de DDD, performance e backups: `.github/copilot-instructions.md`
- Comandos de build já escritos: `README.md` e `FLUTTER_BUILD_COMMANDS.md` (toolchain Android: preferir os `.gradle.kts` e o wrapper, secção 1)

# Referência operacional — portugal_guide

Fonte canônica: `.github/copilot-instructions.md`. Este arquivo guarda o que a skill precisa sem reler as 1800 linhas. Se o caso não estiver aqui, leia a seção correspondente do arquivo canônico antes de decidir.

## Pastas

```
lib/
├── app/
│   ├── core/            # auth, config/injector.dart, repositories genéricos, base
│   ├── helpers/         # EnvKeyHelperConfig
│   ├── routing/         # flutter_modular (app_route_module.dart)
│   ├── routing_guards/
│   └── theme/
├── features/[feature]/  # bounded context
│   ├── screens/
│   ├── [feature]_view_model.dart
│   ├── [feature]_model.dart
│   ├── [feature]_repository.dart
│   └── [feature]_repository_interface.dart
├── resources/translation/
├── util/
└── widgets/
```

Interfaces genéricas: `GenCrudRepositoryInterface<T>` em `lib/app/core/repositories/`.

Registro GetIt:

```dart
injector.registerLazySingleton<MainContentTopicRepositoryInterface>(
  () => MainContentTopicRepository(),
);
injector.registerFactory<MainContentTopicViewModel>(
  () => MainContentTopicViewModel(
    repository: injector<MainContentTopicRepositoryInterface>(),
  ),
);
```

Navegação: `Modular.to.navigate(AppRoutes.main)`, `Modular.to.pop()`.

## CORE e consumidoras

CORE (cuidado extra): `user`, `auth_credentials`, `auth_google`, `main_contents`.

Consumidoras citadas no guia: `user_message_flow`, `user_verified_content`, `user_choice`, `user_tracking_data`. Trate qualquer outra feature que importe uma CORE como consumidora.

Análise de impacto:

```bash
rg "import.*features/user/" lib/features/
```

Troque `user` pelo nome da feature alvo.

## O que não fazer em contrato compartilhado

- Não adicionar método em `*_repository_interface.dart` sem aprovação.
- Não acrescentar campo em Model usado por várias features. Crie um modelo local na consumidora.
- Não mudar ViewModel genérico da CORE para um caso de uma consumidora. Crie ViewModel na consumidora.
- Não criar método que chama endpoint não confirmado. Se o endpoint não existe, componha com os que existem (por exemplo `getAll` + `getUserDetails(id)`), ou filtre no cliente.
- Warning de tipo em cascata (`List<UserDetailsModel>` não cabe em `List<UserModel>`): reverta. Não "conserte" propagando a mudança.

Adapter na consumidora: modelo próprio (`MessageUserData`), factory que junta modelos da CORE, ViewModel que só chama métodos já existentes.

Caso real: `user_message_flow` precisava do rótulo PRODUTOR/CONSUMIDOR. Alterar `user` e chamar `GET /users/details` (inexistente) quebrou `UsersMessageBucketScreen`. O correto foi isolar `MessageUserData` e `MessageUserListViewModel` na consumidora.

## Breaking change em CORE (só se aprovada)

Comentário no método novo:

```dart
/// ⚠️ BREAKING CHANGE (Data: AAAA-MM-DD)
/// Endpoint: MÉTODO /caminho (CONFIRMADO existente)
/// Features afetadas: ...
/// Migração: ...
```

E `x_temp_files/BREAKING_CHANGES.md`:

```markdown
## AAAA-MM-DD - Tipo.metodo()

**Mudança:**
**Motivo:**
**Endpoint Backend:** (CONFIRMADO existente)
**Features Afetadas:**
**Migration Guide:**
```

## DRY

- URL repetida: helper privado descritivo (`_buildOwnershipEndpoint`), não `_getEndpoint`.
- Magic number/string: constante nomeada.
- Mesmo padrão de rota em 3+ repositórios: classe central (o guia cita `lib/app/core/api/api_endpoints.dart`). Só crie se o arquivo já for o lugar do projeto ou o desenvolvedor concordar; não invente um módulo novo se um helper local resolve.

## Performance de lista

- Debounce 500 ms em busca; cancelar `Timer` no `dispose`.
- `CachedNetworkImage` com placeholder `CupertinoActivityIndicator`.
- `ValueKey` por item.
- `ValueListenableBuilder` no notifier específico, não `AnimatedBuilder` da ViewModel inteira.
- Skeleton/loading. `ScrollController`: add no `initState`, remove e dispose no `dispose`, e dispose da ViewModel.

## Lint que este projeto trata como defeito

- `deprecated_member_use`: trocar na hora (ex.: `surfaceVariant` → `surfaceContainerHighest`).
- `prefer_const_constructors`, `prefer_const_declarations`, `prefer_const_literals_to_create_immutables`.
- `unnecessary_import`: em tela Cupertino, não importar `material.dart` se não for usado.
- `avoid_print`: `if (kDebugMode) debugPrint(...)`.

Meta: 0 errors, warnings ≤ 5, hints < 10. Pare se o analyze mostrar error ou se código novo usa API deprecated.

`analysis_options.yaml` inclui `package:flutter_lints/flutter.yaml` e liga `prefer_const_constructors`, `prefer_const_declarations`, `avoid_print`, `unnecessary_import`.

## Tela preta ao fechar dialog

Causa: `Navigator.pop()` numa tela que é tab (não foi aberta com `push` / `Modular.to.navigate`). `canPop()` falso significa tab ou rota raiz.

| Tipo | Como sair |
|------|-----------|
| Tab | `context.findAncestorStateOfType<HomeContentTabScreenState>()?.resetToFirstTab()` |
| Rota navegada | `Navigator.pop()` ou `Modular.to.navigate(...)` |
| Dialog | `Navigator.pop(result)` e só depois navegar, com `mounted` |

Não faça dois `pop` no mesmo `onPressed`. Não faça `setState` e em seguida `pop`.

Exemplos no repo: `lib/features/main_contents/profile/screens/main_stepper_form_screen.dart` (tab), `lib/features/user_verified_content/screens/user_verified_content_wizard_screen.dart` (rota).

## Android / iOS

Baseline 03/10/2026: Flutter 3.47.6, Dart 3.13.5, AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, Java 17, JDK local 21, min API 24, compile/target alinhados ao Flutter (SDK 36), NDK 28.2.13676358, iOS 15+.

`android.builtInKotlin=false` e `android.newDsl=false` mantêm o DSL legado até a migração para Built-in Kotlin do Flutter.

Alinhar `compileSdk` de plugins antigos no `android/build.gradle.kts` lendo o valor de `:app`, com o callback registrado antes de `evaluationDependsOn(":app")`. Não fixar API 35.

Problemas de build conhecidos: `x_temp_files/ANDROID_BUILD_ISSUES.md`. Comandos de build: `FLUTTER_BUILD_COMMANDS.md` na raiz.

Scripts, quando a mudança justificar:

```bash
./android_build_check.sh
./ios_build_check.sh
```

Eles fazem clean, pub get, analyze e build debug (iOS também `pod install`).

## Backup de screen

Arquivo `[nome]_backup.dart` no mesmo diretório. Classe com sufixo `Backup`. Cabeçalho:

```dart
// ======================================================================
// BACKUP DA VIEW ORIGINAL - [NomeClasse]
// Data do backup: [data]
// Contexto: [onde a view é usada]
// Preservada para facilitar reutilização futura se necessário.
// Para restaurar: renomear este arquivo removendo o sufixo "_backup"
// ======================================================================
// ignore_for_file: library_private_types_in_public_api
```

Restaurar: tirar `_backup` do arquivo e `Backup` das classes.

## Segurança e testes

- Segredos só em `.env` / `EnvKeyHelperConfig`. Nunca commitar `.env`.
- HTTPS. Validar input antes da API.
- Testes em `test/features/[feature]/[arquivo]_test.dart`, pacote `flutter_test`. Cobertura desejada 70%. Mock de dependência. Sem internet real, sem token, sem escrever fora do teste.

## Git

Confirmar antes de: `git commit`, `git push`, `git reset`, `git rebase`, `git pull`, `git merge`, `git checkout`/`switch` que troca de branch, `git push --force`.

`git status`, `git diff` e `git log` não precisam de confirmação.

Stage arquivo a arquivo, depois de listar os caminhos. Proibido `git add .`, `git add -A`, `git add --all`.

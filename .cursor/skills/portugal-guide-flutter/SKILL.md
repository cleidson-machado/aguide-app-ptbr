---
name: portugal-guide-flutter
description: Atua como dev sênior Flutter/Dart no projeto portugal_guide (aguide-app-ptbr). Aplica MVVM, Repository Pattern e DDD com Cupertino, GetIt, flutter_modular e i18n. Use ao refatorar, corrigir lint, melhorar performance ou arquitetura, criar ou revisar código Dart/Flutter, alterar pubspec, Gradle, telas, rotas ou features deste app. Antes de mudar uma feature, analisa dependências, evita alterar interfaces, models e viewmodels compartilhados, prefere Adapter Pattern na feature consumidora e não assume endpoints inexistentes.
---

# Portugal Guide — Flutter sênior

Atue como dev sênior Flutter/Dart deste repositório. Priorize estabilidade. Questione má prática, proponha a alternativa segura e só então implemente.

A base de conhecimento canônica é [`.github/copilot-instructions.md`](../../../.github/copilot-instructions.md). Antes de refatorar, tocar feature CORE, navegação, performance, lint, Gradle ou contrato de API, leia a seção correspondente desse arquivo. Detalhes operacionais condensados estão em [reference.md](reference.md). Se esta skill e o arquivo canônico divergirem, siga o arquivo canônico.

## Antes de mexer em qualquer feature

1. Classifique o alvo: **CORE** (`user`, `auth_credentials`, `auth_google`, `main_contents`) ou **consumidora** (o restante de `lib/features/`).
2. Mapeie dependências. Busque imports de `lib/features/[feature]/` no projeto antes de editar.
3. Responda o checklist. Se qualquer resposta for "sim" para quebra de contrato, ou "não" para endpoint, pare e proponha Adapter na feature consumidora.
   - Quais features importam esta?
   - A mudança altera `*_repository_interface.dart`, retorno de ViewModel público ou Model compartilhado?
   - O endpoint backend existe e foi confirmado? Nunca assuma.
   - Dá para resolver só na feature consumidora?
   - A lógica pertence a este bounded context?
4. Não altere interfaces, models ou viewmodels compartilhados para atender uma feature. A consumidora se adapta à CORE.
5. Mudança em CORE só com aprovação explícita do desenvolvedor, e só quando beneficia todas as features dependentes. Documente breaking change no código e em `x_temp_files/BREAKING_CHANGES.md` (template em [reference.md](reference.md)).

## Arquitetura

- MVVM + Repository Pattern + DDD. Cada pasta em `lib/features/` é um bounded context.
- Contrato em `*_repository_interface.dart`; implementação em `*_repository.dart`. ViewModel depende da interface.
- Injeção em `lib/app/core/config/injector.dart` (GetIt): `registerLazySingleton` da interface, `registerFactory` do ViewModel.
- Rotas e guards: `flutter_modular` em `lib/app/routing/` e `lib/app/routing_guards/`.
- UI: widgets **Cupertino**. Voltar com `CupertinoNavigationBarBackButton`. Não introduza Material sem necessidade real.
- ViewModels estendem `ChangeNotifier`, expõem estado por getters e chamam `notifyListeners()`.
- Models imutáveis (`final`), com `fromJson`, `toJson` e `copyWith`.
- i18n via `AppLocalizations.of(context)` com fallback. Sem string de UI hardcoded quando já existe chave. Idiomas: pt-BR, en-US, es-ES, fr-FR. Arquivos em `lib/resources/translation/`.
- URL de API só via `EnvKeyHelperConfig`. Sem URL, token ou segredo hardcoded. Sem PII em log.
- Auth: `auth_credentials` (API própria) e `auth_<provider>` (OAuth). A palavra `core` fica reservada a `lib/app/core/`. Não criar `core_auth`, `auth` genérico ou `login`.

## Código que este projeto exige

- DRY: endpoint, validação ou literal repetido vira helper privado ou constante nomeada. Três ou mais repositórios com o mesmo padrão de rota justificam centralizar.
- `const` em construtores, literais e valores imutáveis de compile-time.
- Imagem remota: `CachedNetworkImage` (com `memCacheWidth` / `memCacheHeight` quando o tamanho de exibição é conhecido).
- Busca que chama API: debounce de 500 ms. Cancele o `Timer` no `dispose`.
- `dispose` de `ScrollController`, `TextEditingController`, `Timer`, streams e ViewModel.
- Log: `debugPrint` dentro de `kDebugMode`. Não use `print`.
- Lista: `ValueKey` por item. Evite `AnimatedBuilder` genérico que reconstrói a lista inteira; prefira `ValueListenableBuilder` no pedaço que muda.
- Tela em tab (`IndexedStack`, `CupertinoTabView`, filha de `HomeContentTabScreen`): não use `Navigator.pop()` para "sair". Feche o dialog primeiro; depois reset da tab no estado pai. `setState` imediatamente antes de `pop` é proibido.
- Exceção assíncrona: try-catch, mensagem amigável via i18n, sem stacktrace na UI.

## Onde criar arquivos

| Tipo | Destino |
|------|---------|
| Código de produção | `lib/` (ou config oficial na raiz: `pubspec.yaml`, `analysis_options.yaml`) |
| Teste | `test/features/[feature]/[arquivo]_test.dart` |
| Rascunho, JSON de exemplo, log, análise | `x_temp_files/` (criar se não existir) |

Não crie arquivo de apoio na raiz. Nomeie rascunhos `x_temp_files/analise_[recurso].md` ou `x_temp_files/debug_[feature].json`.

Backup de view, quando pedido: mesmo diretório, sufixo `_backup.dart`, classe com sufixo `Backup` e cabeçalho com data e contexto. Ver [reference.md](reference.md).

## Pacotes e build Android/iOS

Antes de propor dependência no `pubspec.yaml`, confira plataformas no pub.dev e o efeito em Gradle/AGP/SDK. Baseline aprovada em 03/10/2026: Flutter 3.47.6, Dart 3.13.5, AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, Java source/target 17 (JDK local 21), Android API 24+, SDK 36, NDK 28.2.13676358, iOS 15+. Flags `android.builtInKotlin=false` e `android.newDsl=false`.

Pare e avise se o pacote exigir Dart > 3.13.5, não tiver Android oficial, pedir AGP > 9.0.1 ou NDK incompatível. Não adicione o pacote sem concordância.

Depois de mudar `pubspec.yaml`, config nativa ou uma feature grande feita sobretudo no iOS, rode:

```bash
dart format <arquivos alterados>
flutter analyze
```

Sugira `./android_build_check.sh` e `./ios_build_check.sh` quando dependências ou código nativo mudarem, ou quando a sessão tocar muitos arquivos. Não rode build completo por edição pequena de UI. Meta do analyze: 0 errors e no máximo 5 warnings. Não entregue código novo com API deprecated, `print`, import desnecessário ou `const` faltando.

Testes: mock de API e banco; `setUp` / `tearDown`; sem rede real, sem credencial e sem alterar arquivo do sistema.

## Git

Pergunte e espere confirmação antes de qualquer comando que altere branch local ou remota: `commit`, `push`, `pull`, `checkout`/`switch` de branch, `reset`, `rebase`, `merge`, `cherry-pick`. Explique o risco de alterar a branch atual.

Comandos só de leitura (`status`, `diff`, `log`) podem rodar sem perguntar.

Nunca `git add .`, `git add -A` ou `git add --all`. Liste os caminhos e adicione um a um, depois de o desenvolvedor confirmar.

## Como responder

- Se o pedido quebra CORE, assume endpoint ou muda contrato compartilhado, não implemente. Explique o impacto e entregue o desenho com Adapter na feature consumidora.
- Prefira a menor diff que resolve o problema. Sem refactor oportunista.
- Ao reportar mudança em CORE aprovada, inclua o breaking change e quem precisa migrar.

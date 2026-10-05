# Análise Detalhada de Upgrade do Flutter

**Projeto:** portugal_guide (aguide-app-ptbr)  
**Ambiente:** macOS 15.6.1 (arm64) · Xcode 16.0 · CocoaPods 1.16.2 · Android SDK 35 · Java 21 (JBR do Android Studio)  
**Flutter atual:** 3.32.0 stable (maio/2025) · **Dart:** 3.8.0  
**Stable mais recente:** 3.44.7 (docs refletem essa versão em 2026-05)  
**Gap:** 4 releases stable atrás (3.35 → 3.38 → 3.41 → 3.44) — ~1 ano e 2 meses de defasagem  
**Data da análise:** 2026-07-22  
**Fontes:** [Upgrade Flutter](https://docs.flutter.dev/install/upgrade) · [Breaking changes](https://docs.flutter.dev/release/breaking-changes) · `flutter doctor -v` · `flutter pub outdated`

---

## 1. Resumo Executivo

| Aspecto | Situação |
|---------|----------|
| Viabilidade do upgrade | ✅ Alta — projeto em `stable`, Dart constraint `>=3.7.2 <4.0.0` não bloqueia |
| Risco de quebra no código Dart | 🟡 Médio-baixo — app é Cupertino; a maioria dos breaking changes 3.35–3.44 é Material |
| Risco na toolchain Android | 🟡 Médio — Kotlin embutido (3.44), abiFilters padrão (3.35), Gradle/AGP podem pedir ajuste |
| Risco na toolchain iOS | 🟡 Médio — adoção de UISceneDelegate (3.38) exige migração do Runner |
| Ganho em dependências | ✅ Alto — 15+ pacotes diretos estão travados pelo Dart 3.8.0 e destravam com o upgrade |
| Custo estimado | Baixo a moderado: upgrade + regeneração de builds + correção de depreciações pontuais |

**Veredito:** o upgrade é recomendado. Você ganha mais do que perde — especialmente porque várias dependências do projeto **já estão bloqueadas** pela versão atual do Dart (coluna "Resolvable" ≠ "Latest" no `pub outdated`). Quanto mais tempo parado em 3.32, maior o custo do salto futuro.

---

## 2. O que você GANHA atualizando

### 2.1 Destravamento de dependências (impacto direto e mensurável)

O `flutter pub outdated` mostra que estes pacotes **diretos** não conseguem chegar à versão mais recente com Dart 3.8.0 (Latest exige SDK mais novo):

| Pacote | Atual | Resolvível hoje | Latest (pede SDK novo) |
|--------|-------|-----------------|------------------------|
| device_info_plus | 10.1.2 | 12.4.0 | **13.2.0** |
| google_fonts | 5.1.0 | 6.3.2 | **8.2.0** |
| package_info_plus | 8.3.1 | 9.0.1 | **10.2.1** |
| flutter_modular | 6.3.4 | 6.4.1 | **7.1.0** |
| lottie | 3.3.1 | 3.3.1 | **3.5.1** |
| shared_preferences | 2.5.3 | 2.5.3 | **2.5.5** |
| path_provider | 2.1.5 | 2.1.5 | **2.1.6** |
| intl | 0.20.2 | 0.20.2 | **0.20.3** |
| cupertino_icons | 1.0.8 | 1.0.8 | **1.0.9** |

Além disso, plugins críticos de plataforma (transitivos) estão presos em versões antigas: `google_sign_in_android` (6.2.1 → 7.2.15), `google_sign_in_ios` (5.9.0 → 6.3.0), `shared_preferences_android` (2.4.13 → 2.4.27), `url_launcher_*`, `sqflite_*`. **Correções de bugs e compatibilidade com Android 15+/iOS 18+ estão nessas versões que você não consegue usar hoje.**

### 2.2 Ganhos do framework (3.35 → 3.44)

- **Correções de bugs e hot fixes** acumulados de 4 releases stable (cada stable recebe hot fixes de alta severidade).
- **Desempenho:** melhorias contínuas do engine/Impeller em iOS e Android, threads mescladas (menos overhead de raster).
- **Android:** `abiFilters` padrão (APKs menores), suporte melhor a Android 16/17 (incl. regras de telas grandes no 17), page transition Predictive Back nativo.
- **iOS:** adoção de `UISceneDelegate` (alinhamento com exigências futuras da Apple — em algum momento isso vira requisito de App Store).
- **Tooling:** Dart 3.9+/3.10+ com melhorias de análise, `dart fix` cobrindo mais migrações automaticamente, DevTools mais recente.
- **Ecossistema:** o CI dos plugins oficiais testa contra a **stable mais recente** — ficar para trás significa ser cada vez menos testado pelos mantenedores de pacotes.

### 2.3 Ganhos de manutenção

- `flutter_lints` 4.0.0 → 6.0.0 (regras mais atuais, alinhadas ao objetivo de "0 errors" do projeto).
- `build_runner` destrava para a série 2.15.x (a 2.4.x usa `build_resolvers`/`build_runner_core` **descontinuados**).
- Reduz o tamanho do "salto" futuro: upgrade incremental agora é mais barato que um mega-upgrade depois.

---

## 3. O que você pode PERDER ou precisar ajustar

### 3.1 Breaking changes relevantes para ESTE projeto (3.35 → 3.44)

O app é **Cupertino-first**, o que elimina a maioria das quebras (Material). Ainda assim, estes itens tocam o projeto:

| Versão | Mudança | Impacto aqui |
|--------|---------|--------------|
| 3.35 | [Default abiFilters no Android](https://docs.flutter.dev/release/breaking-changes/default-abi-filters-android) | 🟡 Revisar `android/app/build.gradle.kts` se houver abiFilters customizados; APKs debug/release podem mudar de composição |
| 3.35 | `$FLUTTER_ROOT/version` → `bin/cache/flutter.version.json` | 🟢 Só afeta scripts que leem a versão (verificar `android_build_check.sh`/`ios_build_check.sh`) |
| 3.38 | [UISceneDelegate adoption](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) | 🟡 **Principal item iOS** — migrar `Info.plist`/`AppDelegate` do Runner conforme o guia; plugins como `google_sign_in` dependem disso para callbacks de URL |
| 3.38 | [CupertinoDynamicColor wide gamut](https://docs.flutter.dev/release/breaking-changes/wide-gamut-cupertino-dynamic-color) | 🟡 App usa Cupertino — cores dinâmicas podem renderizar ligeiramente diferente; validar visualmente |
| 3.38 | Page transition Android = Predictive Back | 🟢 App usa transições Cupertino via flutter_modular; validar navegação no Android |
| 3.41 | [FontWeight controla weight de fontes variáveis](https://docs.flutter.dev/release/breaking-changes/font-weight-variation) | 🟡 Projeto usa `google_fonts` — pesos de fonte podem mudar sutilmente; revisão visual |
| 3.44 | [Kotlin embutido no Flutter](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) | 🟡 **Principal item Android** — remover declaração do plugin Kotlin em `settings.gradle.kts`/`build.gradle.kts` conforme o guia |
| 3.44 | `IconData` marcada como `final` | 🟢 Só quebra se alguém estende `IconData` (improvável aqui) |
| 3.44 | `cacheExtent`/`cacheExtentStyle` deprecados | 🟡 Verificar usos em listas com scroll infinito (feature de conteúdos) |
| 3.44 | Restrições de orientação ignoradas em telas grandes (Android 17) | 🟢 Comportamento novo do SO, não do seu código |

Itens 100% Material (Radio redesign, SnackBar, DropdownButtonFormField, AppBar color, tokens M3, etc.) **não afetam** este app Cupertino — a menos que haja telas Material escondidas.

### 3.2 Riscos de toolchain

- **Xcode:** você está no 16.0. Releases novas do Flutter tendem a exigir Xcode 16.x+ — hoje OK, mas o build iOS deve ser revalidado (pods serão regenerados; rodar `pod install`, possivelmente `pod repo update`).
- **Gradle/AGP/Java:** projeto usa Gradle 8.7 + Java 21. O Flutter 3.44 valida versões mínimas de AGP/Gradle/Kotlin mais novas; pode ser preciso subir AGP/Gradle. Atenção redobrada dada a regra do projeto de preservar o build Android (histórico de quebras pós-sessões iOS).
- **Licenças Android pendentes** (apontado no `flutter doctor`): rodar `flutter doctor --android-licenses` antes de tudo.
- **`.flutter-plugins` → `.flutter-plugins-dependencies`** (desde 3.32/3.35): scripts ou CI que leiam `.flutter-plugins` quebram.

### 3.3 Riscos de código Dart

- **Depreciações novas** vão aparecer no `flutter analyze` (meta do projeto: 0 errors / <5 warnings). A maioria é migrável com `dart fix --apply`.
- **i18n:** desde 3.32 o `flutter gen-l10n` gera código **em source** (não mais pacote sintético). O projeto usa `generate: true` + `l10n.yaml` — como você já está na 3.32 isso já deve estar absorvido, mas confirme que não há import de `package:flutter_gen/gen_l10n/...` legado.
- **Mudanças sutis de comportamento:** física de springs (3.32), foco/semântica, wide gamut — exigem teste visual, não geram erro de compilação.

### 3.4 O que você NÃO perde

- Não há quebra de linguagem: Dart continua 3.x (constraint `<4.0.0` segue válida).
- Nada do seu código Cupertino/MVVM/Repository é removido — apenas deprecações com período de migração.
- É reversível: o SDK é um checkout git — dá para voltar à 3.32.0 com `git checkout 3.32.0` no diretório do Flutter (ou usar FVM para manter as duas).

---

## 4. Custo/benefício de NÃO atualizar

- Dependências cada vez mais travadas (várias já estão hoje).
- Pacotes novos e correções de segurança de plugins exigem SDK mais novo.
- Divergência crescente com os requisitos das lojas (target SDK Android, UISceneDelegate/iOS).
- O upgrade futuro será maior, mais arriscado e mais caro do que fazer agora em passo controlado.

---

## 5. Plano de upgrade recomendado (passo a passo)

```bash
# 0. Pré-condições
git status                                # branch limpa ou commit do trabalho atual
flutter doctor --android-licenses         # resolver licenças pendentes

# 1. Upgrade do SDK (canal stable)
flutter channel                           # confirmar 'stable'
flutter upgrade                           # 3.32.0 → 3.44.x

# 2. Dependências
flutter clean
flutter pub get
flutter pub outdated                      # ver o que destravou
flutter pub upgrade                       # minor/patch seguros
# (opcional, em etapa separada) flutter pub upgrade --major-versions

# 3. Migrações automáticas
dart fix --dry-run                        # revisar
dart fix --apply

# 4. Validação (scripts do projeto)
flutter analyze                           # meta: 0 errors
./android_build_check.sh                  # build Android completo
./ios_build_check.sh                      # build iOS completo (pods regenerados)

# 5. Teste funcional nos emuladores
flutter run                               # iOS Simulator e Pixel API 35
```

**Pontos de inspeção manual pós-upgrade:**
1. Guia [built-in Kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin) → ajustar `android/settings.gradle.kts`.
2. Guia [UISceneDelegate](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) → ajustar `ios/Runner` (crítico para o Google Sign-In).
3. Login Google (OAuth) nas duas plataformas — plugins `google_sign_in_*` vão subir de versão.
4. Fontes (`google_fonts`) e cores Cupertino — revisão visual rápida das telas principais.
5. Listas paginadas com scroll infinito — conferir se não usam `cacheExtent` deprecado.

**Estratégia conservadora (alternativa):** usar [FVM](https://fvm.app) para instalar a 3.44.x lado a lado sem tocar na 3.32.0 global, validar o projeto e só então promover. Zero risco de bloquear seu dia a dia.

---

## 6. Conclusão

| | |
|---|---|
| **Ganhos** | Destravamento de ~15 pacotes diretos + plugins de plataforma, correções e desempenho de 4 releases, compatibilidade com Android 16/17 e requisitos iOS futuros, lints e tooling modernos, upgrade futuro mais barato |
| **Perdas/custos** | 2 migrações de toolchain (Kotlin embutido no Android, UISceneDelegate no iOS), depreciações a corrigir no `analyze`, revalidação visual (fontes/cores) e funcional (OAuth, navegação), possível bump de AGP/Gradle |
| **Recomendação** | **Atualizar agora**, em branch dedicada, seguindo o plano da seção 5 e validando com `android_build_check.sh` e `ios_build_check.sh` antes do merge |

O risco real para este projeto é concentrado na camada nativa (Android Gradle/Kotlin e iOS Runner), não no código Dart — que, por ser Cupertino + MVVM bem isolado, escapa da maior parte dos breaking changes do período.
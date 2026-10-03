# Guia: Upgrade do Flutter no Ambiente Local (macOS) com FVM

**Projeto:** portugal_guide (aguide-app-ptbr)  
**Flutter global:** 3.32.0 stable em `~/development/flutter` (permanece intocado na Opção B)  
**FVM:** já instalado via Homebrew (`/opt/homebrew/bin/fvm`)  
**Data:** 2026-07-22  
**Complementa:** [ANALISE_UPGRADE_FLUTTER.md](ANALISE_UPGRADE_FLUTTER.md)

---

## Opção A — Upgrade global (altera o default do Mac)

Afeta **todos** os projetos da máquina.

```bash
flutter channel        # confirmar que está no canal 'stable'
flutter upgrade        # 3.32.0 → 3.44.x em ~/development/flutter
```

**Reversão:** o SDK é um checkout git — para voltar:

```bash
cd ~/development/flutter
git checkout 3.32.0
flutter --version      # reconstrói o cache da versão antiga
```

---

## Opção B — Versão nova SÓ neste projeto (recomendado para testes)

Usa FVM para instalar a 3.44.x lado a lado, sem tocar no Flutter global.

### Passo 1 — Instalar a versão no cache do FVM

```bash
fvm install 3.44.7
# ou listar versões disponíveis primeiro:
fvm releases
```

### Passo 2 — Fixar a versão na raiz do projeto

```bash
cd /Users/cleidson/MobileApps/Apps_Yard/aguide-app-ptbr
fvm use 3.44.7
```

Isso cria:
- `.fvmrc` → registra a versão do projeto (pode ser commitado, para o time usar a mesma versão)
- `.fvm/flutter_sdk` → symlink para o SDK 3.44.7 no cache do FVM

### Passo 3 — Usar sempre com o prefixo `fvm` dentro do projeto

```bash
fvm flutter --version
fvm flutter pub get
fvm flutter analyze
fvm flutter run
fvm flutter build apk --debug
fvm flutter build ios --debug --simulator
```

### Passo 4 — Integração com VS Code

Criar/ajustar `.vscode/settings.json` na raiz do projeto:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk"
}
```

A extensão Dart passa a usar a 3.44.7 neste workspace (hot reload, debug, analyzer).

### Passo 5 — Gitignore

Adicionar ao `.gitignore`:

```
.fvm/
```

O `.fvmrc` **pode** ser commitado; o diretório `.fvm/` (symlink) **não** deve.

---

## Resultado final

| Contexto | Versão usada |
|---|---|
| Qualquer projeto (comando `flutter`) | 3.32.0 global — inalterado |
| Este projeto via `fvm flutter` / VS Code | 3.44.7 |
| Voltar atrás neste projeto | `fvm use 3.32.0` ou apagar `.fvmrc` e `.fvm/` |

---

## ⚠️ Cuidados e recomendações

1. **Scripts do projeto:** `android_build_check.sh` e `ios_build_check.sh` chamam `flutter` direto (global). Para testá-los com a versão do FVM:

   ```bash
   PATH="$PWD/.fvm/flutter_sdk/bin:$PATH" ./android_build_check.sh
   PATH="$PWD/.fvm/flutter_sdk/bin:$PATH" ./ios_build_check.sh
   ```

   Ou prefixar os comandos internos com `fvm` (edição dos scripts).

2. **Licenças Android pendentes** (apontado no `flutter doctor -v`): resolver antes dos builds:

   ```bash
   flutter doctor --android-licenses
   ```

3. **Branch dedicada:** fazer o teste de upgrade em branch separada — `pubspec.lock`, arquivos Gradle e Pods podem mudar.

4. **Validação completa após trocar a versão:**

   ```bash
   fvm flutter clean
   fvm flutter pub get
   fvm flutter pub outdated        # ver dependências destravadas
   fvm dart fix --dry-run          # migrações automáticas (revisar antes)
   fvm flutter analyze             # meta do projeto: 0 errors
   ```

5. **Pontos de inspeção manual** (detalhes em [ANALISE_UPGRADE_FLUTTER.md](ANALISE_UPGRADE_FLUTTER.md), seção 5):
   - Migração para Kotlin embutido (Android, Flutter 3.44)
   - Adoção de UISceneDelegate (iOS, Flutter 3.38) — crítico para Google Sign-In
   - Login Google (OAuth) nas duas plataformas
   - Revisão visual de fontes (`google_fonts`) e cores Cupertino
   - Listas com scroll infinito (`cacheExtent` deprecado na 3.44)

6. **Promoção para o global:** só depois de validar tudo no projeto via FVM, rodar `flutter upgrade` no SDK global (Opção A) — ou manter o FVM como padrão de trabalho por projeto.

---

## Comandos FVM úteis

```bash
fvm list                # versões instaladas no cache do FVM
fvm releases            # todas as releases disponíveis para instalar
fvm use <versão>        # fixa versão no projeto atual
fvm global <versão>     # (opcional) define default do FVM na máquina
fvm remove <versão>     # remove versão do cache
fvm doctor              # diagnóstico da configuração FVM do projeto
```

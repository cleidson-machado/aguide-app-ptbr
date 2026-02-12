# GitHub Copilot - Instruções do Projeto

## Visão Geral
Este é um projeto **Flutter 3.x+ com Dart 3.x** seguindo arquitetura MVVM (Model-View-ViewModel). O app é multi-idioma (i18n) com suporte a português, inglês, espanhol e francês. Usa **Cupertino widgets** (design iOS) e integração com API REST para consumo de conteúdos.

## Estrutura de Pastas OBRIGATÓRIA
```
lib/
├── app/
│   ├── core/
│   │   ├── config/         # Injeção de dependência, rotas
│   │   └── constants/      # Constantes globais
│   └── app_custom_main_widget.dart
├── features/               # Funcionalidades por domínio (ORGANIZAÇÃO PRINCIPAL)
│   ├── main_contents/
│   │   ├── topic/
│   │   │   ├── screens/
│   │   │   │   └── main_content_topic_screen.dart    # View (UI)
│   │   │   ├── main_content_topic_view_model.dart     # ViewModel (lógica)
│   │   │   ├── main_content_topic_model.dart          # Model (dados)
│   │   │   └── main_content_topic_service.dart        # Service (API)
│   │   └── [outra-feature]/
│   └── [outro-modulo]/
├── resources/              # Recursos globais
│   ├── locale_provider.dart
│   └── translation/        # Arquivos de i18n
├── util/                   # Utilitários compartilhados
├── widgets/                # Widgets reutilizáveis
└── main.dart               # Entry point
```

---

### 📂 Organização de Arquivos e Diretórios

- **Arquivos de Produção e Estrutura:** O agente tem permissão total para criar e editar arquivos essenciais na raiz do projeto, como `pubspec.yaml`, `analysis_options.yaml`, `Dockerfile`, `.gitignore`, e arquivos de configuração Flutter/Dart.
- **Código Fonte:** A pasta `lib/` é o core do projeto. O agente deve manipular, criar ou refatorar módulos dentro desta pasta conforme as solicitações de desenvolvimento.
- **Arquivos Temporários e de Rascunho (REGRA CRÍTICA):**
  - **Local Obrigatório:** `x_temp_files/`
  - Os arquivos de **testes** devem seguir o padrão `test/features/[NOME_DA_FEATURE]/[NOME_ARQUIVO]_test.dart`, ou seja, salvar testes na estrutura correta dentro de `test/`, respeitando a organização por features do projeto.
  - Os rascunhos de documentação (`*.md`), arquivos de texto para manipulação de dados, JSONs de exemplo ou logs de debug gerados pelo agente **DEVEM** ser criados exclusivamente dentro de `x_temp_files/`.
  - **Proibição:** Nunca criar arquivos de "suporte ao raciocínio" ou "testes rápidos" na raiz do projeto. Se não for um arquivo de configuração oficial (`.yaml`, `.json`, `.dart` de produção) ou código de produção, ele pertence à `x_temp_files/`.

## 🤖 Comportamento do Agente na Criação de Arquivos

1. **Identificação de Escopo:** Antes de criar um arquivo, o agente deve classificar:
   - *É essencial para o funcionamento do app ou build?* (Ex: `pubspec.yaml`, `main.dart`, configs) → **Raiz ou lib/**.
   - *É um teste unitário/widget?* → **test/features/[feature]/**.
   - *É um rascunho, dump JSON, log de erro ou arquivo auxiliar?* → **x_temp_files/**.
2. **Limpeza Automática:** Ao sugerir arquivos de análise temporária, o agente deve nomeá-los como `x_temp_files/analise_[recurso].md` ou `x_temp_files/debug_[feature].json` por padrão.

---

## 🔄 Compatibilidade Cross-Platform iOS/Android (CRÍTICO)

### ⚠️ Contexto do Ambiente de Desenvolvimento
- **Plataforma Principal de Dev:** macOS com emuladores iOS (mais rápido)
- **Emuladores Disponíveis:** iOS Simulator, Pixel 3a/9 Pro API 29/30/35
- **Fluxo de Trabalho:** Desenvolvimento intensivo em iOS → Testes periódicos em Android
- **Problema Recorrente:** Após longas sessões de dev em iOS, o build Android (`flutter build apk --debug`) frequentemente quebra devido a incompatibilidades de dependências ou configurações gradle

### 🎯 REGRAS OBRIGATÓRIAS para Preservar Build Android

#### 1. Validação Antes de Adicionar Dependências
**SEMPRE** que propor adicionar/atualizar um pacote no `pubspec.yaml`:

✅ **FAZER:**
- Verificar compatibilidade Android do pacote no pub.dev
- Checar se requer configurações específicas em `android/build.gradle.kts` ou `android/app/build.gradle.kts`
- Alertar se a versão do pacote requer:
  - Gradle 8.x+ (verificar compatibilidade com Gradle 8.7 atual)
  - Android SDK/NDK específico
  - Configurações Kotlin DSL específicas
  - Java/Kotlin versions diferentes das atuais (Java 17, Kotlin 1.8.22)
- Verificar se há issues conhecidas com Gradle Kotlin DSL
- Testar mentalmente se o pacote funciona em **ambas** as plataformas

❌ **NUNCA:**
- Adicionar pacotes sem verificar seção "Platforms" no pub.dev
- Propor versões que exijam Dart SDK > 3.8.0 (limite atual do projeto)
- Ignorar avisos de compatibilidade Android em pacotes nativos

#### 2. Monitoramento Proativo de Problemas Gradle

**ALERTA AUTOMÁTICO** quando detectar:
- Plugins com build.gradle (Groovy) em projetos Kotlin DSL
- Versões de plugins Android que não suportam Gradle 8.7
- Conflitos entre `compileSdk`, `targetSdk`, `minSdk` em diferentes módulos
- Uso de APIs descontinuadas do Gradle (ex: `getOrElse`, `orNull` em propriedades simples)

**Exemplo de Alerta Esperado:**
```
⚠️ ATENÇÃO: O pacote 'sqflite_android' v2.4.1 pode causar problemas no build Android:
- Usa build.gradle (Groovy) enquanto o projeto usa Kotlin DSL
- Pode falhar com Gradle 8.7
- Versão 2.4.2+2 corrige, mas requer Dart SDK 3.9.0+ (incompatível)
- Solução: Manter v2.4.1 e adicionar configuração de compatibilidade em android/build.gradle.kts

📝 Recomendação: Testar `flutter build apk --debug` após adicionar este pacote.
```

#### 3. Checklist Pré-Commit para Grandes Features

Quando finalizar uma feature desenvolvida primariamente em iOS:

```bash
# Checklist obrigatório antes de commit
[ ] flutter clean
[ ] flutter pub get
[ ] flutter analyze (sem erros críticos)
[ ] flutter build apk --debug (build Android OK)
[ ] flutter build ios --debug (build iOS OK)
```

**A IA deve sugerir este checklist automaticamente** quando:
- Detectar múltiplas mudanças em `pubspec.yaml`
- Identificar sessão longa de desenvolvimento (> 5 arquivos modificados)
- Antes de comandos `git commit` com mudanças em dependências

#### 4. Configurações Gradle Preventivas

Sempre manter no `android/build.gradle.kts`:

```kotlin
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                compileSdkVersion(35) // Forçar SDK consistente
            }
        }
    }
}
```

#### 5. Documentação de Problemas Conhecidos

Manter atualizado em `x_temp_files/ANDROID_BUILD_ISSUES.md`:
- Pacotes problemáticos e soluções aplicadas
- Conflitos Gradle resolvidos
- Versões de dependências que causaram problemas

#### 6. Sinais de Alerta para Intervenção Imediata

🚨 **PARAR e AVISAR o desenvolvedor** se:
- Versão de pacote requer Dart SDK > 3.8.0
- Pacote não tem suporte oficial para Android
- Plugin nativo requer modificações manuais em código nativo Android
- Gradle plugin version upgrade necessário (> 8.7.0)
- NDK version incompatível detectada

---

## 🔐 Padrão de Nomenclatura para Autenticação (CRÍTICO)

### Contexto DDD e Linguagem Ubíqua

Este projeto utiliza **DDD (Domain-Driven Design)** e segue a **Linguagem Ubíqua** para nomenclatura de features. A palavra **"core"** é reservada EXCLUSIVAMENTE para código compartilhado em `lib/app/core/`.

### Nomenclatura de Features de Autenticação

Para diferenciar claramente os diferentes métodos de autenticação:

**✅ Padrão Obrigatório:**
```
lib/features/
├── auth_credentials/      ← Autenticação própria (API REST do app)
├── auth_google/           ← OAuth Google
├── auth_facebook/         ← OAuth Facebook (futuro)
├── auth_linkedin/         ← OAuth LinkedIn (futuro)
├── auth_apple/            ← Sign in with Apple (futuro)
```

**Convenção de Nomenclatura:**
- **`auth_credentials`**: Autenticação por credenciais (email/senha) via API REST própria do app
- **`auth_<provider>`**: Autenticação externa via OAuth/Social (Google, Facebook, LinkedIn, Apple, etc.)

**Estrutura de Arquivos (exemplo auth_credentials):**
```
lib/features/auth_credentials/
├── auth_credentials_controller.dart
├── auth_credentials_login_view_model.dart
├── auth_credentials_model.dart
├── auth_credentials_service.dart
└── screens/
    ├── auth_credentials_login_screen.dart
    ├── auth_credentials_register_screen.dart
    └── auth_credentials_forgot_pass_screen.dart
```

**❌ NUNCA Usar:**
- `core_auth` (conflita com lib/app/core/)
- `auth` genérico (ambíguo, não indica o método)
- `login` (muito genérico, não expressa o contexto)

### Justificativa

- **Linguagem Ubíqua**: "Autenticação por credenciais" é um termo do domínio, entendível por desenvolvedores e stakeholders
- **Clareza**: Diferencia imediatamente autenticação própria de OAuth/Social
- **Escalabilidade**: Facilita adição de novos providers sem confusão
- **DDD**: Alinha com Bounded Contexts (cada método de auth é um contexto distinto)

---

## Convenções de Código Flutter/Dart

### 1. Screens (Views)
- Localização: `lib/features/[feature]/screens/`
- Usar **Cupertino widgets** (CupertinoPageScaffold, CupertinoNavigationBar, etc.)
- StatefulWidget quando há estado local (ScrollController, TextEditingController)
- Sempre fazer dispose de controllers
- Separar lógica de UI (não colocar regras de negócio aqui)

```dart
class MainContentTopicScreen extends StatefulWidget {
  const MainContentTopicScreen({super.key});

  @override
  State<MainContentTopicScreen> createState() => _MainContentTopicScreenState();
}

class _MainContentTopicScreenState extends State<MainContentTopicScreen> {
  final MainContentTopicViewModel viewModel = injector<MainContentTopicViewModel>();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    viewModel.loadPagedContents();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Título"),
      ),
      child: // ... corpo da tela
    );
  }
}
```

### 2. ViewModels
- Localização: `lib/features/[feature]/`
- Estender `ChangeNotifier` para state management
- Contém lógica de negócio e gerenciamento de estado
- Sempre fazer dispose de recursos (timers, streams, etc.)
- Usar `notifyListeners()` após mudanças de estado

```dart
class MainContentTopicViewModel extends ChangeNotifier {
  final MainContentTopicService _service;
  
  List<MainContentTopicModel> _contents = [];
  bool _isLoading = false;
  String? _error;
  
  List<MainContentTopicModel> get contents => _contents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MainContentTopicViewModel(this._service);

  Future<void> loadPagedContents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _service.fetchContents(page: 1);
      _contents = data;
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Limpar recursos aqui
    super.dispose();
  }
}
```

### 3. Services (Camada de Dados)
- Localização: `lib/features/[feature]/`
- Responsável por chamadas HTTP, cache, etc.
- Usar `http` ou `dio` para requisições
- Tratar exceções e retornar tipos específicos

```dart
class MainContentTopicService {
  final http.Client client;
  static const String baseUrl = 'https://api.example.com';

  MainContentTopicService(this.client);

  Future<List<MainContentTopicModel>> fetchContents({required int page}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/contents?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((item) => MainContentTopicModel.fromJson(item)).toList();
    } else {
      throw Exception('Falha ao carregar conteúdos');
    }
  }
}
```

### 4. Models
- Localização: `lib/features/[feature]/`
- Classes imutáveis (usar `final` nos campos)
- Sempre incluir `fromJson` e `toJson` para serialização
- Usar `copyWith` para clonagem com modificações
- Usar `equatable` para comparação de objetos (opcional mas recomendado)

```dart
class MainContentTopicModel {
  final int id;
  final String title;
  final String description;
  final String contentImageUrl;

  const MainContentTopicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.contentImageUrl,
  });

  factory MainContentTopicModel.fromJson(Map<String, dynamic> json) {
    return MainContentTopicModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      contentImageUrl: json['contentImageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'contentImageUrl': contentImageUrl,
    };
  }

  MainContentTopicModel copyWith({
    int? id,
    String? title,
    String? description,
    String? contentImageUrl,
  }) {
    return MainContentTopicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentImageUrl: contentImageUrl ?? this.contentImageUrl,
    );
  }
}
```

## Tratamento de Exceções
- Usar try-catch em operações assíncronas
- Criar classes de exceção customizadas quando necessário
- Nunca expor stacktraces diretamente ao usuário
- Usar mensagens amigáveis traduzidas via i18n

```dart
try {
  await viewModel.loadContents();
} catch (e) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(AppLocalizations.of(context)?.error ?? 'Erro'),
      content: Text(AppLocalizations.of(context)?.networkError ?? 'Erro de rede'),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

## Logging e Debug
- Usar `debugPrint()` para logs em desenvolvimento
- Adicionar emojis para facilitar identificação: `print('✅ Sucesso')`, `print('❌ Erro')`, `print('📜 Carregando')`
- Usar `kDebugMode` para logs condicionais
- Nunca logar dados sensíveis (tokens, senhas, dados pessoais)

```dart
import 'package:flutter/foundation.dart';

void _onScroll() {
  if (kDebugMode) {
    print('📜 [MainContentTopicScreen] Scroll position: ${_scrollController.position.pixels}');
  }
}
```

## Internacionalização (i18n)
- Arquivos em `lib/resources/translation/`
- Usar `AppLocalizations.of(context)` para tradução
- Sempre fornecer fallback em inglês
- Suportar: pt-BR, en-US, es-ES, fr-FR

```dart
Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
```

---

## ⚠️ OTIMIZAÇÃO DE PERFORMANCE (CRÍTICO)

### 🚨 REGRAS OBRIGATÓRIAS PARA LISTAS

#### 🔴 Problemas Comuns a EVITAR:

1. **AnimatedBuilder Genérico:**
```dart
// ❌ ERRADO - Reconstrói tudo
AnimatedBuilder(
  animation: viewModel,
  builder: (context, child) => _buildBody(),
)

// ✅ CORRETO - Listener específico
ValueListenableBuilder(
  valueListenable: viewModel.contentsNotifier,
  builder: (context, value, child) => _buildBody(),
)
```

2. **Busca sem Debounce:**
```dart
// ❌ ERRADO - Chama API a cada caractere
CupertinoSearchTextField(
  onChanged: (value) => viewModel.searchContents(value),
)

// ✅ CORRETO - Debounce de 500ms
Timer? _debounce;

void _onSearchChanged(String value) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    viewModel.searchContents(value);
  });
}
```

3. **Imagens sem Cache:**
```dart
// ❌ ERRADO - Sem cache otimizado
Image.network(url)

// ✅ CORRETO - Cache em memória e disco
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 160,
  memCacheHeight: 160,
  placeholder: (context, url) => CupertinoActivityIndicator(),
)
```

4. **ListView sem Keys:**
```dart
// ❌ ERRADO - Widgets recriados desnecessariamente
return Column(children: [...])

// ✅ CORRETO - Key única por item
return Column(
  key: ValueKey('item_${content.id}'),
  children: [...],
)
```

### ✅ Checklist de Performance

Antes de finalizar uma tela com lista:
- [ ] Debounce implementado em campos de busca?
- [ ] CachedNetworkImage usado para imagens remotas?
- [ ] Keys únicas em itens de ListView/GridView?
- [ ] Dispose de controllers implementado?
- [ ] ScrollController com listener otimizado?
- [ ] Skeleton/loading states implementados?

---

## 🎯 Qualidade de Código e Linting (CRÍTICO)

### ⚠️ Problema Recorrente
Durante o desenvolvimento, erros de linting se acumulam no painel de PROBLEMAS do VS Code, impactando a qualidade do código e podendo causar bugs sutis em produção.

### 🔍 Validação Obrigatória Antes de Commit

#### 1. Executar Flutter Analyze
```bash
# Sempre executar antes de commit
flutter analyze

# Meta: 0 errors, < 5 warnings
```

#### 2. Tipos de Problemas Comuns e Soluções

##### 🚨 **APIs Deprecated (deprecated_member_use)**
```dart
// ❌ ERRADO - API deprecated
colorScheme.surfaceVariant  // Deprecated no Flutter 3.18+

// ✅ CORRETO - Usar substituto recomendado
colorScheme.surfaceContainerHighest
```

**Regra:** SEMPRE verificar changelog do Flutter ao atualizar versão e substituir APIs deprecated imediatamente.

##### 🔧 **prefer_const_declarations**
```dart
// ❌ ERRADO - Variável final que poderia ser const
final strategies = ContentSortStrategy.values;

// ✅ CORRETO - Usar const para valores imutáveis conhecidos em compile-time
const strategies = ContentSortStrategy.values;
```

**Benefício:** Reduz uso de memória e melhora performance ao reutilizar instâncias constantes.

##### ⚡ **prefer_const_constructors**
```dart
// ❌ ERRADO - Construtor sem const
Bone.text(words: 3, fontSize: 18)
SizedBox(height: 8)
Padding(padding: EdgeInsets.all(20), child: ...)

// ✅ CORRETO - Adicionar const quando possível
const Bone.text(words: 3, fontSize: 18)
const SizedBox(height: 8)
const Padding(padding: EdgeInsets.all(20), child: ...)
```

**Benefício:** Widgets const não são reconstruídos em hot reload, melhorando performance drasticamente.

##### 📦 **unnecessary_import**
```dart
// ❌ ERRADO - Import redundante
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';  // Material já incluído em Cupertino

// ✅ CORRETO - Remover import desnecessário
import 'package:flutter/cupertino.dart';
```

**Regra:** Em apps Cupertino (iOS-style), evitar import de Material a menos que realmente necessário.

##### 🐞 **avoid_print**
```dart
// ❌ ERRADO - print() em código de produção
print('✅ Dados carregados: ${contents.length}');

// ✅ CORRETO - Usar logger ou debugPrint
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  debugPrint('✅ Dados carregados: ${contents.length}');
}

// OU usar package logger
logger.info('Dados carregados: ${contents.length}');
```

**Regra:** NUNCA usar `print()` em código de produção. Usar `debugPrint()` com `kDebugMode` ou package `logger`.

##### 🎨 **prefer_const_literals_to_create_immutables**
```dart
// ❌ ERRADO - Lista não const em widget imutável
@immutable
class MyWidget extends StatelessWidget {
  final List<Widget> children = [
    Text('Item 1'),
    Text('Item 2'),
  ];
}

// ✅ CORRETO - Lista const
@immutable
class MyWidget extends StatelessWidget {
  final List<Widget> children = const [
    Text('Item 1'),
    Text('Item 2'),
  ];
}
```
### 🎯 Exemplo Prático: Refatoração SOLID + DDD

**Problema:** Arquivo com múltiplas responsabilidades (violação SRP)
```dart
// ❌ ERRADO - content_sort_strategy.dart (múltiplas responsabilidades)
enum ContentSortStrategy { titleAsc, titleDesc }
class ContentSortConfig {  // Mapeia para API
  final strategies = ContentSortStrategy.values;  // Método estático
  String get description => "...";  // Descrição para UI
}
```

**Solução:** Separar em arquivos seguindo SOLID + Linguagem Ubíqua
```dart
// ✅ CORRETO - Separação de responsabilidades

// 1. content_sort_option.dart (Domínio - Linguagem Ubíqua)
enum ContentSortOption {
  titleAscending,   // Nome claro do domínio
  titleDescending,
  newestPublished,
}

// 2. content_sort_criteria.dart (Value Object - Parâmetros de API)
class ContentSortCriteria {
  final String field;
  final String order;
  factory ContentSortCriteria.fromOption(ContentSortOption option) { }
}

// 3. content_sort_service.dart (Serviço - Lógica de negócio)
class ContentSortService {
  ContentSortOption getRandomOption() { }
  ContentSortCriteria toCriteria(ContentSortOption option) { }
}
```
### 🤖 Comportamento Esperado da IA

#### Antes de Gerar Código
- [ ] Verificar se não está usando APIs deprecated
- [ ] Adicionar `const` em todos os construtores quando possível
- [ ] Usar `const` em vez de `final` para valores imutáveis conhecidos em compile-time
- [ ] Preferir `debugPrint` com `kDebugMode` em vez de `print`
- [ ] Remover imports desnecessários

#### Após Modificar Código
- [ ] Sugerir `flutter analyze` se múltiplos arquivos foram alterados
- [ ] Alertar sobre APIs deprecated detectadas
- [ ] Sugerir otimizações de const quando relevante

### 📋 Checklist Pré-Commit de Qualidade

```bash
# 1. Formatar código
dart format .

# 2. Análise estática
flutter analyze

# 3. Verificar se há < 5 issues
# Se > 5 issues: corrigir antes de commit

# 4. (Opcional) Executar testes
flutter test
```

### 🎯 Métricas de Qualidade Aceitáveis

| Métrica | Meta | Limite Máximo |
|---------|------|---------------|
| Erros (errors) | 0 | 0 |
| Avisos (warnings) | 0 | 5 |
| Info (hints) | < 10 | 20 |
| Tempo de análise | < 5s | 10s |

### 🚨 Sinais de Alerta

**PARAR desenvolvimento e limpar linting** se:
- ⚠️ > 20 problemas detectados no painel PROBLEMS
- ⚠️ Erros (errors) aparecem no `flutter analyze`
- ⚠️ APIs deprecated sendo usadas em novo código
- ⚠️ Múltiplos arquivos com warnings de const

### 📚 Recursos para Linting

```yaml
# analysis_options.yaml - Configuração de linting do projeto
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Regras críticas sempre ativas
    - prefer_const_constructors
    - prefer_const_declarations
    - avoid_print
    - unnecessary_import
```

**Documentação:**
- [Linting oficial Flutter](https://docs.flutter.dev/testing/code-analysis)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Lints Package](https://pub.dev/packages/flutter_lints)

---

## Testes
- Localização: `test/features/[feature]/`
- Nomenclatura: `[nome_arquivo]_test.dart`
- Usar `flutter_test` package
- Cobertura mínima desejada: 70%

### Tipos de Testes

**Widget Tests:**
```dart
testWidgets('MainContentTopicScreen deve carregar conteúdos', (tester) async {
  final mockViewModel = MockMainContentTopicViewModel();
  when(mockViewModel.contents).thenReturn([]);
  when(mockViewModel.isLoading).thenReturn(false);

  await tester.pumpWidget(
    MaterialApp(
      home: MainContentTopicScreen(),
    ),
  );

  expect(find.byType(CupertinoPageScaffold), findsOneWidget);
});
```

**Unit Tests (ViewModels):**
```dart
test('loadPagedContents deve carregar dados com sucesso', () async {
  final mockService = MockMainContentTopicService();
  final viewModel = MainContentTopicViewModel(mockService);

  when(mockService.fetchContents(page: 1))
      .thenAnswer((_) async => [mockContent]);

  await viewModel.loadPagedContents();

  expect(viewModel.contents.length, 1);
  expect(viewModel.isLoading, false);
  expect(viewModel.error, null);
});
```

### Regras de Testes
✅ **PERMITIDO:**
- Mockar dependências externas (API, database)
- Usar `setUp` e `tearDown` para preparar/limpar testes
- Testes assíncronos com `async/await`

❌ **PROIBIDO:**
- Testes que dependem de internet real
- Hardcoded tokens/credenciais nos testes
- Testes que modificam arquivos do sistema
- Pular testes no CI/CD

## Segurança
- Nunca comitar API keys, tokens ou credenciais
- **NUNCA hardcodar URLs de API no código** - sempre usar variáveis de ambiente via `EnvKeyHelperConfig`
- Usar variáveis de ambiente para segredos (`.env` com `flutter_dotenv`)
- Validar inputs do usuário antes de enviar para API
- Usar HTTPS para todas as requisições

### Exemplo correto de uso de URL de API:

```dart
// ❌ ERRADO - URL hardcoded
static const String baseUrl = 'https://api.aguide-ptbr.com.br/api/v1';

// ✅ CORRETO - Usar variável de ambiente
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';

static String get baseUrl => EnvKeyHelperConfig.mocApi2;
```

## Assets e Recursos
- Imagens em `assets/images/`
- Fontes em `assets/fonts/`
- Sempre declarar em `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont-Regular.ttf
```

## Build e Deploy
- Build Android: `flutter build apk --release`
- Build iOS: `flutter build ipa --release`
- Testar antes de release: `flutter run --release`
- Sempre atualizar versão em `pubspec.yaml` antes de build

## O QUE NÃO FAZER
❌ Criar arquivos temporários na raiz do projeto (usar `x_temp_files/`)
❌ Colocar lógica de negócio em Screens (usar ViewModels)
❌ Usar Material widgets em app Cupertino (manter consistência iOS)
❌ Esquecer `dispose()` de controllers
❌ Ignorar tratamento de exceções em chamadas assíncronas
❌ Logar informações sensíveis (tokens, dados pessoais)
❌ Hardcoded strings traduzíveis (usar i18n)
❌ Image.network sem CachedNetworkImage em listas
❌ onChanged sem debounce para busca
❌ ListView sem keys em itens dinâmicos
❌ AnimatedBuilder genérico em listas grandes
❌ Pular testes no CI/CD
❌ Comitar arquivos `.env` ou credenciais

## Recursos Flutter a Utilizar
✅ Hot Reload: `r` no terminal (desenvolvimento rápido)
✅ Hot Restart: `R` no terminal (reinicia estado)
✅ DevTools: `flutter pub global run devtools` (debugging)
✅ Analyze: `flutter analyze` (linting)
✅ Format: `dart format .` (formatação automática)
✅ Provider/GetIt: Injeção de dependência
✅ Skeletonizer: Loading states elegantes
✅ CachedNetworkImage: Cache de imagens
✅ Cupertino widgets: Design nativo iOS

---

## Comandos Git e Interação com o Usuário

- Sempre que o agente for sugerir comandos Git que possam alterar o estado da branch local ou remota, como `git commit`, `git push`, `git reset`, `git rebase`, `git pull --rebase`, `git push --force` ou similares, ele deve **obrigatoriamente perguntar ao usuário desenvolvedor** se pode prosseguir com a execução desses comandos.
- O agente deve alertar o usuário sobre o potencial risco de "bagunçar" a branch atual, explicando que esses comandos podem modificar o histórico ou o conteúdo da branch local e remota.
- Somente após a confirmação explícita do usuário, o agente deve sugerir ou executar comandos Git que alterem a branch local ou remota.
- Para comandos Git que não alterem o estado da branch (como `git status`, `git log`, `git diff`), o agente pode sugerir ou executar sem necessidade de confirmação.

### Adição de Arquivos ao Stage (git add)

- **Em hipótese alguma** o agente deve sugerir comandos de adição em lote como `git add .`, `git add -A`, ou `git add --all`.
- Todos os arquivos devem ser adicionados individualmente usando `git add <caminho-do-arquivo>` após serem explicitamente listados e revisados com o usuário.
- Isso evita a inclusão acidental de arquivos temporários, logs, credenciais ou outros artefatos indesejados no commit.

Exemplo de comportamento esperado:

Usuário: "Adicione minhas alterações e faça commit."

Agente: "Vou adicionar os seguintes arquivos individualmente:
- `lib/features/main_contents/topic/screens/main_content_topic_screen.dart`
- `lib/features/user/screens/user_list_screen.dart`

Confirma a adição desses arquivos ao stage?"

Usuário: "Sim."

Agente:
``bash
git add lib/features/main_contents/topic/screens/main_content_topic_screen.dart
git add lib/features/user/screens/user_list_screen.dart
``

Agora vou fazer commit das suas alterações. Isso irá modificar o histórico da branch local. Deseja continuar?

Usuário: "Sim."

Agente:
``bash
git commit -m "feat(user): implementa nova funcionalidade X"
``
---

**Importante:** Ao gerar código, sempre verificar se está seguindo estas diretrizes. Para otimizações de performance, consultar o arquivo `ANALISE_PERFORMANCE_LISTA.md` na raiz do projeto.

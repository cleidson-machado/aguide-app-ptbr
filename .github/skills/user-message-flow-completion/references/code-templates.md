# Code Templates for user_message_flow

Ready-to-use code snippets following project architecture patterns.

---

## 1. Add Repository Method (Interface + Implementation)

### Step 1: Interface
**File:** `lib/features/user_message_flow/user_message_flow_repository_interface.dart`

```dart
abstract class UserMessageFlowRepositoryInterface {
  // Existing methods...
  
  /// [Brief description of what method does]
  /// 
  /// Parameters:
  /// - [param1]: Description
  /// 
  /// Returns: Description of return type
  /// 
  /// Throws:
  /// - [UserMessageFlowException] if [condition]
  Future<ReturnType> methodName({
    required String param1,
    int? optionalParam,
  });
}
```

### Step 2: Implementation
**File:** `lib/features/user_message_flow/user_message_flow_repository.dart`

```dart
// Private helper for endpoint (DRY principle)
String _methodNameEndpoint(String param1) => 'endpoint/path/$param1';

@override
Future<ReturnType> methodName({
  required String param1,
  int? optionalParam,
}) async {
  try {
    // Input validation (if needed)
    if (param1.isEmpty) {
      throw UserMessageFlowException('param1 cannot be empty');
    }
    
    // Build endpoint
    final endpoint = _methodNameEndpoint(param1);
    
    // Make HTTP call
    final response = await _dio.get(endpoint);
    
    // Handle empty response
    if (response.statusCode == 204 || response.data == null) {
      return []; // or null, or throw, depending on contract
    }
    
    // Parse response
    return ReturnType.fromApiMap(response.data);
    
  } on DioException catch (e) {
    // Map HTTP errors
    if (e.response?.statusCode == 401) {
      throw UserMessageFlowException('Sessão expirada. Faça login novamente.');
    } else if (e.response?.statusCode == 404) {
      throw UserMessageFlowException('Recurso não encontrado.');
    }
    throw UserMessageFlowException('Erro ao processar solicitação: ${e.message}');
  }
}
```

---

## 2. Add ViewModel Method

**File:** `lib/features/user_message_flow/[feature]_view_model.dart`

```dart
class FeatureViewModel extends ChangeNotifier {
  final RepositoryInterface _repository;
  
  // State properties
  bool _isLoading = false;
  String? _error;
  List<Model> _items = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Model> get items => _items;
  
  /// [Brief description of what method does]
  Future<void> methodName({required String param}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _repository.methodName(param: param);
      _items = data;
    } on UserMessageFlowException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro inesperado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Error mapping helper
  String _mapError(dynamic error) {
    if (error is UserMessageFlowException) {
      return error.message;
    }
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 401:
          return 'Sessão expirada. Faça login novamente.';
        case 403:
          return 'Você não tem permissão para esta ação.';
        case 404:
          return 'Recurso não encontrado.';
        case 500:
        case 503:
          return 'Erro no servidor. Tente novamente mais tarde.';
        default:
          return error.response?.data['message'] ?? 'Erro ao processar solicitação.';
      }
    }
    return ErrorMessages.defaultMsnFailedToLoadData;
  }
}
```

---

## 3. Register Dependencies in Injector

**File:** `lib/app/core/config/injector.dart`

```dart
void setupInjections() {
  // ... existing code ...
  
  // ========== For User Message Flow ==========
  
  // Repository (Singleton - shared instance)
  injector.registerLazySingleton<RepositoryInterface>(
    () => RepositoryImplementation(dio: injector<Dio>()),
  );
  
  // ViewModel (Factory - new instance per request)
  injector.registerFactory<FeatureViewModel>(
    () => FeatureViewModel(repository: injector<RepositoryInterface>()),
  );
}
```

---

## 4. Create Model with fromApiMap

**File:** `lib/features/user_message_flow/models/[model_name]_model.dart`

```dart
class ModelName {
  final String id;
  final String title;
  final DateTime createdAt;
  final bool isActive;
  
  const ModelName({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.isActive,
  });
  
  /// Parse backend API response to model
  factory ModelName.fromApiMap(Map<String, dynamic> map) {
    return ModelName(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] as bool? ?? false,
    );
  }
  
  /// Parse list of items
  static List<ModelName> fromApiList(List<dynamic> list) {
    return list.map((item) => ModelName.fromApiMap(item)).toList();
  }
  
  /// Convert to JSON for POST/PUT requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
```

---

## 5. Screen with ViewModel Integration

**File:** `lib/features/user_message_flow/screens/[screen_name]_screen.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';

/// [Brief description of screen purpose]
/// 
/// ⚠️ IMPORTANT: [Is this a TAB or NAVIGATED screen?]
class FeatureScreen extends StatefulWidget {
  final String requiredParam;
  
  const FeatureScreen({
    super.key,
    required this.requiredParam,
  });

  @override
  State<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends State<FeatureScreen> {
  late FeatureViewModel _viewModel;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _viewModel = injector<FeatureViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    
    // Initial load
    _viewModel.loadData(param: widget.requiredParam);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      if (kDebugMode) {
        debugPrint(
          '📟 [FeatureScreen] state loading=${_viewModel.isLoading} '
          'items=${_viewModel.items.length} error=${_viewModel.error}',
        );
      }
      setState(() {});
    }
  }

  Future<void> _handleRefresh() async {
    if (kDebugMode) {
      debugPrint('🔄 [FeatureScreen] Pull-to-refresh acionado');
    }
    await _viewModel.refreshData(param: widget.requiredParam);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        middle: const Text('Screen Title'),
      ),
      child: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    // Error state (priority 1)
    if (_viewModel.error != null && _viewModel.items.isEmpty) {
      return _buildErrorState(_viewModel.error!);
    }

    // Loading state (priority 2)
    if (_viewModel.isLoading && _viewModel.items.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    // Empty state (priority 3)
    if (_viewModel.items.isEmpty) {
      return _buildEmptyState();
    }

    // Content state (priority 4)
    return _buildContentList(_viewModel.items);
  }

  Widget _buildContentList(List<Model> items) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pull-to-refresh
        CupertinoSliverRefreshControl(onRefresh: _handleRefresh),

        // List
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return ItemWidget(
                  item: item,
                  onTap: () => _handleItemTap(item),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 80,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum item encontrado',
            style: TextStyle(
              fontSize: 18,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 60,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar dados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: () => _viewModel.loadData(param: widget.requiredParam),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemTap(Model item) {
    if (kDebugMode) {
      debugPrint('🔍 [FeatureScreen] Item selecionado: ${item.title}');
    }
    
    // Navigate to detail screen
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => DetailScreen(item: item),
      ),
    );
  }
}
```

---

## 6. Infinite Scroll Pattern

**Add to ViewModel:**

```dart
class FeatureViewModel extends ChangeNotifier {
  bool _hasNextPage = false;
  int _currentPage = 0;
  
  bool get hasNextPage => _hasNextPage;
  int get currentPage => _currentPage;
  
  Future<void> loadNextPage({required String conversationId}) async {
    if (!_hasNextPage || _isLoading) return; // Guard clause
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final nextPage = await _repository.getPagedData(
        id: conversationId,
        page: _currentPage + 1,
        size: 20,
      );
      
      // Append to existing list
      _items.addAll(nextPage.items);
      _hasNextPage = nextPage.hasNextPage;
      _currentPage = nextPage.currentPage;
    } catch (e) {
      _error = _mapError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Add to Screen:**

```dart
@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  // Load more when reaching bottom
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 200) {
    if (_viewModel.hasNextPage && !_viewModel.isLoading) {
      _viewModel.loadNextPage(conversationId: widget.conversationId);
    }
  }
  
  // OR load more when reaching top (for chat messages)
  if (_scrollController.position.pixels == 0) {
    if (_viewModel.hasNextPage && !_viewModel.isLoading) {
      _viewModel.loadNextPage(conversationId: widget.conversationId);
    }
  }
}
```

---

## 7. Pull-to-Refresh Pattern

**In ViewModel:**
```dart
/// Refresh data without showing loading indicator
Future<void> refreshData({required String param}) async {
  _error = null;
  // Note: NO _isLoading = true here
  notifyListeners();
  
  try {
    final data = await _repository.getData(param: param);
    _items = data;
    _error = null;
  } catch (e) {
    _error = _mapError(e);
  } finally {
    notifyListeners();
  }
}
```

**In Screen:**
```dart
Future<void> _handleRefresh() async {
  await _viewModel.refreshData(param: widget.param);
}

// In CustomScrollView
CupertinoSliverRefreshControl(onRefresh: _handleRefresh),
```

---

## 8. DRY Helper Method Pattern

**Before (Duplicated):**
```dart
Future<Model> method1() async {
  final endpoint = '/messages/conversation/$conversationId';
  // ...
}

Future<Model> method2() async {
  final endpoint = '/messages/conversation/$conversationId';
  // ...
}
```

**After (DRY):**
```dart
// Private helper at top of class
String _conversationMessagesEndpoint(String conversationId) {
  return 'messages/conversation/$conversationId';
}

Future<Model> method1() async {
  final endpoint = _conversationMessagesEndpoint(conversationId);
  // ...
}

Future<Model> method2() async {
  final endpoint = _conversationMessagesEndpoint(conversationId);
  // ...
}
```

---

## 9. Optimistic UI Update Pattern

**For sending message:**

```dart
Future<void> sendMessage(String content) async {
  _isSending = true;
  notifyListeners();
  
  // Create temporary message with local ID
  final tempMessage = UserChatMessageModel(
    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
    text: content,
    conversationId: _conversationId,
    senderId: AuthTokenManager.currentUserId,
    sentAt: DateTime.now(),
    isSentByMe: true,
    isPending: true, // Custom flag
  );
  
  // Optimistically add to list
  _messages.add(tempMessage);
  notifyListeners();
  
  try {
    // Send to backend
    final sentMessage = await _repository.sendMessage(
      conversationId: _conversationId,
      content: content,
    );
    
    // Replace temp message with real one
    final index = _messages.indexWhere((m) => m.id == tempMessage.id);
    if (index != -1) {
      _messages[index] = sentMessage;
    }
  } catch (e) {
    // Rollback: Remove temp message
    _messages.removeWhere((m) => m.id == tempMessage.id);
    _error = _mapError(e);
  } finally {
    _isSending = false;
    notifyListeners();
  }
}
```

---

## 10. Navigation Patterns

**TAB Screen (NO back button, NO Navigator.pop):**
```dart
// Access parent tab controller
final homeState = context.findAncestorStateOfType<HomeContentTabScreenState>();
homeState?.resetToFirstTab();
```

**NAVIGATED Screen (HAS back button):**
```dart
// Simple push
Navigator.of(context).push(
  CupertinoPageRoute(
    builder: (context) => TargetScreen(param: value),
  ),
);

// Pop back
Navigator.of(context).pop();

// Pop with result
Navigator.of(context).pop(resultValue);

// Replace route
Navigator.of(context).pushReplacement(
  CupertinoPageRoute(
    builder: (context) => TargetScreen(),
  ),
);
```

---

## 11. Flutter Analyze Before Commit

**Always run:**
```bash
flutter clean
flutter pub get
flutter analyze

# Target: 0 errors, < 5 warnings
```

**Common fixes:**
```dart
// prefer_const_constructors
const SizedBox(height: 8)  // Add const

// prefer_const_declarations
const strategies = ContentSortStrategy.values;  // Change final to const

// avoid_print
if (kDebugMode) {
  debugPrint('Log message');
}
```

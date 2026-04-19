---
name: user-message-flow-completion
description: 'Complete Flutter user_message_flow feature with Quarkus backend integration. Use for messaging, chat, conversations, endpoints, pagination, real-time updates, read receipts, DRY refactoring. Expert in Flutter/Dart frontend + Java Quarkus backend + PostgreSQL. References local knowledge docs for API contracts.'
argument-hint: 'Specify task: implement pagination, add read receipts, integrate endpoint, refactor DRY'
---

# User Message Flow Completion

**Domain:** Messaging/Chat System (WhatsApp-style)  
**Stack:** Flutter/Dart (frontend) + Java Quarkus (backend) + PostgreSQL  
**Feature Scope:** `lib/features/user_message_flow/`  
**Current Status:** ~70% Complete (3 of 17 endpoints implemented)

---

## 🎯 Purpose

Finalize the implementation of the `user_message_flow` feature in this Flutter project, ensuring correct integration with the already-implemented Quarkus backend. This skill provides:

- ✅ **API Contract Reference** - Official backend endpoint documentation
- ✅ **Gap Analysis** - What's missing vs what backend provides
- ✅ **Implementation Patterns** - MVVM, Repository Pattern, DRY principles
- ✅ **Step-by-Step Guides** - For each missing feature
- ✅ **Quality Assurance** - Validation, error handling, testing

---

## 📚 Mandatory Reference Sources

**ALWAYS START HERE** - Load these documents from local knowledge base:

1. **[API Documentation](../../../.local_knowledge/add-user-message-c/USERMESSAGE_API_DOCUMENTATION.md)**
   - 17 backend endpoints (9 conversation + 8 message)
   - Request/response contracts
   - Error codes and validation rules
   - Authentication requirements

2. **[Frontend-Backend Analysis](../../../.local_knowledge/add-user-message-c/FRONTEND_BACKEND_ANALYSIS_REPORT.md)**
   - Gap analysis matrix (what's missing)
   - Current implementation status
   - DRY violations to fix
   - Code quality issues

3. **[Refactoring History](../../../.local_knowledge/add-user-message-c/REFATORACAO_USERS_MESSAGE_BUCKET_CONCLUIDA.md)**
   - Recent changes to user list screen
   - Patterns for similar refactorings
   - Lessons learned

**⚠️ CRITICAL RULE:** Never assume endpoint behavior - always verify with these documents first.

---

## 🚦 When to Use This Skill

Invoke this skill when the user requests:

- ✅ "Complete user_message_flow feature"
- ✅ "Implement message pagination"
- ✅ "Add read receipts"
- ✅ "Integrate [specific endpoint]"
- ✅ "Fix DRY violations in messaging"
- ✅ "Add real-time updates to chat"
- ✅ "Implement archive/pin conversations"
- ✅ "Support image/video messages"
- ✅ "Create new conversation UI"
- ✅ "Add infinite scroll to chat"

**Do NOT use** for:
- ❌ Backend implementation (Quarkus code)
- ❌ Database schema changes
- ❌ Non-messaging features
- ❌ General Flutter questions (use default agent)

---

## 📋 Quick Feature Status

| Feature | Status | Priority | Endpoint Available |
|---------|--------|----------|-------------------|
| List conversations | ✅ Done | - | GET /conversations |
| Send text message | ✅ Done | - | POST /messages |
| Load messages (page 0) | ✅ Done | - | GET /messages/conversation/{id} |
| **Message pagination** | ❌ Missing | **CRITICAL** | ✅ Backend ready |
| **Mark as read** | ❌ Missing | **CRITICAL** | PUT /messages/{id}/read |
| **Create direct conversation** | ❌ Missing | HIGH | POST /conversations/direct |
| **Unread count badge** | ❌ Missing | HIGH | GET /conversations/unread-count |
| Real-time updates | ❌ Missing | HIGH | No backend WebSocket |
| Create group | ❌ Missing | MEDIUM | POST /conversations/group |
| Archive/pin | ❌ Missing | LOW | PUT /conversations/{id}/archive |
| Edit/delete message | ❌ Missing | MEDIUM | PUT/DELETE /messages/{id} |
| Image/video messages | ❌ Missing | MEDIUM | POST /messages (type param) |
| Search messages | ❌ Missing | LOW | GET /messages/.../search |

---

## 🔧 Implementation Workflow

### Step 1: Load Context
```
1. Read .local_knowledge/add-user-message-c/*.md files
2. Identify the specific feature to implement
3. Locate endpoint documentation in API docs
4. Check gap analysis for current status
```

### Step 2: Plan Implementation

**For New Repository Method:**
```dart
// 1. Add method to interface
// lib/features/user_message_flow/user_message_flow_repository_interface.dart
Future<ReturnType> methodName({required params});

// 2. Implement in concrete class
// lib/features/user_message_flow/user_message_flow_repository.dart
@override
Future<ReturnType> methodName({required params}) async {
  // Use helper for endpoint (DRY principle)
  final endpoint = _buildEndpoint();
  
  // Make HTTP call
  final response = await _dio.get(endpoint);
  
  // Map response to model
  return ModelClass.fromApiMap(response.data);
}
```

**For New ViewModel Method:**
```dart
// lib/features/user_message_flow/[feature]_view_model.dart
class FeatureViewModel extends ChangeNotifier {
  Future<void> newFeature() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _repository.methodName();
      // Update state
    } catch (e) {
      _error = _mapError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Step 3: Follow Architecture Patterns

**MVVM + Repository Pattern:**
```
Screen (View)
  ↓ observes
ViewModel (Business Logic)
  ↓ calls
Repository Implementation
  ↓ implements
Repository Interface
  ↓ calls
Backend API
```

**Key Principles:**
- ✅ Views never call repositories directly
- ✅ ViewModels extend `ChangeNotifier`
- ✅ Always use interfaces (dependency inversion)
- ✅ Register dependencies in `injector.dart`
- ✅ Follow DRY - create helpers for duplicated code

### Step 4: Implement with Validation

**Required Validations:**
```dart
// Input validation
if (content.trim().isEmpty) {
  throw UserMessageFlowException('Message cannot be empty');
}

// Range validation (pagination)
if (page < 0) {
  throw UserMessageFlowException('Page must be >= 0');
}
if (size < 1 || size > 100) {
  throw UserMessageFlowException('Size must be 1-100');
}

// Authentication check
final token = await AuthTokenManager.getToken();
if (token == null) {
  throw UserMessageFlowException('Session expired');
}
```

**Error Mapping Pattern:**
```dart
String _mapError(dynamic error) {
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
        return error.response?.data['message'] ?? 'Erro desconhecido';
    }
  }
  return ErrorMessages.defaultMsnFailedToLoadData;
}
```

### Step 5: Register Dependencies

**Always update `lib/app/core/config/injector.dart`:**
```dart
// ViewModels (Factory - new instance per request)
injector.registerFactory<NewViewModel>(
  () => NewViewModel(repository: injector<RepositoryInterface>()),
);

// Repositories (Singleton - shared instance)
injector.registerLazySingleton<RepositoryInterface>(
  () => RepositoryImplementation(dio: injector<Dio>()),
);
```

### Step 6: Test Integration

**Manual Testing Checklist:**
```
[ ] flutter clean && flutter pub get
[ ] flutter analyze (0 errors expected)
[ ] Test happy path (success case)
[ ] Test error cases (401, 404, 500)
[ ] Test validation (empty inputs, invalid ranges)
[ ] Test loading states (spinner shows/hides)
[ ] Test edge cases (empty list, null values)
[ ] Pull-to-refresh works
[ ] Navigation back works (if NAVIGATED screen)
```

---

## 🎯 Common Implementation Tasks

### Task 1: Add Message Pagination (CRITICAL)

**Problem:** `UserChatMessageViewModel` has `hasNextPage` and `currentPage` state, but no method to load next page. Users can only see first 20 messages.

**Solution:**
```dart
// In user_chat_message_view_model.dart
Future<void> loadNextPage(String conversationId) async {
  if (!hasNextPage || isLoading) return; // Guard clause
  
  _isLoading = true;
  notifyListeners();
  
  try {
    final nextPage = await _repository.getMessagesByConversation(
      conversationId: conversationId,
      page: currentPage + 1,
      size: 20,
    );
    
    // Prepend older messages (reversed chronological)
    _messages.insertAll(0, nextPage.messages);
    _hasNextPage = nextPage.hasNextPage;
    _currentPage = nextPage.currentPage;
  } catch (e) {
    _error = _mapError(e);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**UI Integration (user_chat_message_view_screen.dart):**
```dart
// Add scroll listener
@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  if (_scrollController.position.pixels == 0) { // At top
    if (_viewModel.hasNextPage && !_viewModel.isLoading) {
      _viewModel.loadNextPage(widget.contact.id);
    }
  }
}
```

### Task 2: Implement Read Receipts (CRITICAL)

**Problem:** Opening a conversation doesn't mark messages as read. Unread badges never clear.

**Solution:**

**Step 1 - Add repository method:**
```dart
// user_message_flow_repository_interface.dart
Future<void> markMessageAsRead(String messageId);

// user_message_flow_repository.dart
@override
Future<void> markMessageAsRead(String messageId) async {
  final endpoint = 'messages/$messageId/read';
  await _dio.put(endpoint);
  // 204 No Content expected
}
```

**Step 2 - Update ViewModel:**
```dart
// user_chat_message_view_model.dart
Future<void> markAllAsRead(String conversationId) async {
  try {
    // Mark unread messages as read
    for (final message in _messages) {
      if (!message.isRead && !message.isSentByMe) {
        await _repository.markMessageAsRead(message.id);
        message.isRead = true; // Update local state
      }
    }
    notifyListeners();
  } catch (e) {
    debugPrint('Failed to mark as read: $e');
    // Don't show error to user (non-critical)
  }
}
```

**Step 3 - Call on conversation open:**
```dart
// user_chat_message_view_screen.dart
@override
void initState() {
  super.initState();
  _viewModel.loadInitialMessages(widget.contact.id);
  _viewModel.markAllAsRead(widget.contact.id); // Auto-mark as read
}
```

### Task 3: Add Unread Count Badge

**Problem:** No app-wide unread message counter for notifications.

**Solution:**

**Step 1 - Add repository method:**
```dart
// user_message_flow_repository_interface.dart
Future<int> getUnreadCount();

// user_message_flow_repository.dart
@override
Future<int> getUnreadCount() async {
  final response = await _dio.get('conversations/unread-count');
  return response.data['unreadCount'] as int;
}
```

**Step 2 - Create polling service:**
```dart
// lib/features/user_message_flow/unread_count_notifier.dart
class UnreadCountNotifier extends ChangeNotifier {
  final UserMessageFlowRepositoryInterface _repository;
  int _unreadCount = 0;
  Timer? _pollTimer;
  
  int get unreadCount => _unreadCount;
  
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: 30), (_) => _fetchCount());
    _fetchCount(); // Initial load
  }
  
  Future<void> _fetchCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch unread count: $e');
    }
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
```

**Step 3 - Display in UI:**
```dart
// In app navigation bar
ListenableBuilder(
  listenable: unreadCountNotifier,
  builder: (context, child) {
    final count = unreadCountNotifier.unreadCount;
    return CupertinoTabView(
      builder: (context) => MessagesScreen(),
      // Badge with count
      trailing: count > 0 
          ? Badge(label: Text('$count'), child: Icon(...))
          : Icon(...),
    );
  },
);
```

### Task 4: Create Direct Conversation UI

**Problem:** Users can't start new conversations. Only existing conversations are shown.

**Solution:**

**Implementation already done** - See REFATORACAO_USERS_MESSAGE_BUCKET_CONCLUIDA.md for details.

Summary:
- `UsersMessageBucketScreen` refactored to show user list
- Tapping user calls `createDirectConversation()` endpoint
- Auto-navigates to chat screen on success
- Shows loading modal during creation
- Handles errors gracefully

### Task 5: DRY Refactoring - Duplicate Initials Logic

**Problem:** `_getInitials()` method duplicated in 3 files (DRY violation).

**Solution:**

**Create extension in feature:**
```dart
// lib/features/user_message_flow/utils/string_extensions.dart
extension StringInitials on String {
  String getInitials() {
    final parts = trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, min(2, parts[0].length)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  
  Color getAvatarColor() {
    final hash = hashCode.abs();
    const colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemRed,
      CupertinoColors.systemTeal,
      CupertinoColors.systemYellow,
      CupertinoColors.systemPink,
      CupertinoColors.systemIndigo,
    ];
    return colors[hash % colors.length];
  }
}
```

**Replace duplicates:**
```dart
// Before
String _getInitials(String name) { /* 5 lines */ }
final initials = _getInitials(contact.contactName);

// After
final initials = contact.contactName.getInitials();
```

---

## ⚠️ Critical Guidelines

### 1. Endpoint Verification
**NEVER assume endpoint exists** - always check API documentation first.

❌ **Wrong:**
```dart
Future<List<User>> getAllUsersWithDetails() async {
  return await _dio.get('/users/details'); // Endpoint may not exist!
}
```

✅ **Correct:**
```dart
// Check API docs → endpoint doesn't exist
// Use existing endpoints instead
Future<List<User>> getAllUsersWithDetails() async {
  final users = await _dio.get('/users');
  // Enrich locally or with separate calls
}
```

### 2. Repository Interface First
**ALWAYS** define interface before implementation (Dependency Inversion Principle).

```dart
// Step 1: Interface
abstract class RepositoryInterface {
  Future<Model> method();
}

// Step 2: Implementation
class Repository implements RepositoryInterface {
  @override
  Future<Model> method() { /* ... */ }
}

// Step 3: Inject interface (not implementation)
injector.registerLazySingleton<RepositoryInterface>(
  () => Repository(),
);
```

### 3. DRY Principle
**ALWAYS** create helper methods for duplicated code.

❌ **Wrong:**
```dart
final endpoint = '/messages/$conversationId'; // Duplicated in 3 methods
```

✅ **Correct:**
```dart
String _messagesEndpoint(String conversationId) => 'messages/$conversationId';
```

### 4. Error Handling
**ALWAYS** provide user-friendly, translated error messages.

```dart
String _mapError(DioException e) {
  switch (e.response?.statusCode) {
    case 401:
      return 'Sessão expirada. Faça login novamente.';
    case 403:
      return 'Você não tem permissão para esta ação.';
    case 404:
      return 'Recurso não encontrado.';
    default:
      return 'Erro ao processar solicitação.';
  }
}
```

### 5. Screen Type Awareness
**NEVER** use `Navigator.pop()` in TAB screens - causes black screen.

✅ **TAB Screen (no NavigationBar back button):**
```dart
// Access parent tab controller
final homeState = context.findAncestorStateOfType<HomeContentTabScreenState>();
homeState?.resetToFirstTab();
```

✅ **NAVIGATED Screen (has back button):**
```dart
// Safe to use pop
Navigator.of(context).pop();
```

---

## 🧪 Testing Guidelines

### API Testing Checklist
```
[ ] Endpoint exists in backend (verify in API docs)
[ ] HTTP method correct (GET/POST/PUT/DELETE)
[ ] Request body matches backend contract
[ ] Response parsing handles all fields
[ ] Error codes mapped correctly (401, 403, 404, 500)
[ ] Authentication token sent in header
[ ] Pagination parameters validated (page >= 0, 1 <= size <= 100)
```

### UI Testing Checklist
```
[ ] Loading state shows spinner
[ ] Success state displays data
[ ] Empty state shows placeholder message
[ ] Error state shows retry button
[ ] Pull-to-refresh works
[ ] Infinite scroll triggers at top/bottom
[ ] Back button works (if NAVIGATED screen)
[ ] Validation messages show for invalid input
```

---

## 📚 Related Project Files

**Core Architecture:**
- `.github/copilot-instructions.md` - Project-wide guidelines (MVVM, DRY, DDD)
- `lib/app/core/config/injector.dart` - Dependency injection registry
- `lib/app/core/repositories/` - Generic repository interfaces

**Feature Location:**
- `lib/features/user_message_flow/` - All messaging code
- `lib/features/user/` - User models and list (referenced by messages)

**Documentation:**
- `.local_knowledge/add-user-message-c/USERMESSAGE_API_DOCUMENTATION.md`
- `.local_knowledge/add-user-message-c/FRONTEND_BACKEND_ANALYSIS_REPORT.md`
- `.local_knowledge/add-user-message-c/REFATORACAO_USERS_MESSAGE_BUCKET_CONCLUIDA.md`

---

## 🎓 Summary

This skill provides:

1. **Context-aware implementation** - Reads local docs for API contracts
2. **Step-by-step guides** - For each missing feature
3. **Quality assurance** - Follows MVVM, DRY, SOLID, DDD
4. **Error prevention** - Validates endpoints exist before implementing
5. **Architectural consistency** - Matches existing patterns

**Use this skill to:**
- Complete any missing endpoint integration
- Refactor DRY violations
- Add pagination, read receipts, real-time updates
- Maintain code quality throughout implementation

**Remember:** Always start by reading the 3 reference documents in `.local_knowledge/add-user-message-c/` before implementing any feature.

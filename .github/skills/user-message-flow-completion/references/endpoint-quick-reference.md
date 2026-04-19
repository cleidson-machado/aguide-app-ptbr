# API Endpoints Quick Reference

**Base URL:** `EnvKeyHelperConfig.apiBaseUrl` (environment variable)  
**Authentication:** JWT via `Authorization: Bearer <token>` header  
**All endpoints require authentication**

---

## Conversation Endpoints (9)

| # | Endpoint | Method | Purpose | Implemented |
|---|----------|--------|---------|-------------|
| 1 | `/conversations/direct` | POST | Create/get 1-on-1 conversation | ✅ YES |
| 2 | `/conversations/group` | POST | Create group conversation | ❌ NO |
| 3 | `/conversations` | GET | List user's conversations | ✅ YES |
| 4 | `/conversations/{id}` | GET | Get conversation details | ❌ NO |
| 5 | `/conversations/{id}/archive` | PUT | Toggle archive status | ❌ NO |
| 6 | `/conversations/{id}/pin` | PUT | Toggle pin status | ❌ NO |
| 7 | `/conversations/{id}/participants` | POST | Add user to group | ❌ NO |
| 8 | `/conversations/{id}/participants/{userId}` | DELETE | Remove user from group | ❌ NO |
| 9 | `/conversations/unread-count` | GET | Get total unread count | ❌ NO |

---

## Message Endpoints (8)

| # | Endpoint | Method | Purpose | Implemented |
|---|----------|--------|---------|-------------|
| 10 | `/messages` | POST | Send message | ✅ YES (TEXT only) |
| 11 | `/messages/conversation/{id}?page={p}&size={s}` | GET | List messages (paginated) | ✅ YES (page 0 only) |
| 12 | `/messages/{id}` | GET | Get single message | ❌ NO |
| 13 | `/messages/{id}/read` | PUT | Mark message as read | ❌ NO |
| 14 | `/messages/{id}` | PUT | Edit message content | ❌ NO |
| 15 | `/messages/{id}` | DELETE | Soft delete message | ❌ NO |
| 16 | `/messages/conversation/{id}/search?query={q}` | GET | Search messages | ❌ NO |
| 17 | `/messages/{id}/replies` | GET | Get thread replies | ❌ NO |

---

## Priority Implementation Order

### 🔴 CRITICAL (Core UX Blockers)
1. **Message Pagination** - Endpoint 11 (already exists, just need ViewModel method)
2. **Mark as Read** - Endpoint 13 (clear unread badges)
3. **Unread Count** - Endpoint 9 (app badge notifications)

### 🟠 HIGH (Major Features)
4. **Create Direct Conversation** - Endpoint 1 (✅ Already implemented)
5. **Real-time Updates** - Polling mechanism (no WebSocket backend)
6. **Create Group** - Endpoint 2

### 🟡 MEDIUM (Enhanced Features)
7. **Archive/Pin** - Endpoints 5 & 6
8. **Edit/Delete Message** - Endpoints 14 & 15
9. **Image/Video Messages** - Endpoint 10 (messageType param)
10. **Add/Remove Participants** - Endpoints 7 & 8

### 🟢 LOW (Nice to Have)
11. **Search Messages** - Endpoint 16
12. **Thread Replies** - Endpoint 17
13. **Get Single Message** - Endpoint 12

---

## Request/Response Patterns

### GET Requests (No Body)
```dart
final response = await _dio.get(endpoint);
return ModelClass.fromApiMap(response.data);
```

### POST Requests (With Body)
```dart
final body = {
  'field1': value1,
  'field2': value2,
};
final response = await _dio.post(endpoint, data: body);
return ModelClass.fromApiMap(response.data);
```

### PUT Requests (Toggle Actions)
```dart
await _dio.put(endpoint); // Empty body, returns 204 No Content
```

### DELETE Requests
```dart
await _dio.delete(endpoint); // Returns 204 No Content
```

---

## Common HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Parse response data |
| 201 | Created | Parse newly created resource |
| 204 | No Content | Success, no body to parse |
| 400 | Bad Request | Validation error, show backend message |
| 401 | Unauthorized | Token expired, redirect to login |
| 403 | Forbidden | No permission for action |
| 404 | Not Found | Resource doesn't exist |
| 500 | Internal Server Error | Backend error, show generic message |
| 503 | Service Unavailable | Backend down, retry later |

---

## Error Mapping Template

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
      case 400:
        return error.response?.data['message'] ?? 'Dados inválidos.';
      default:
        return 'Erro desconhecido ao processar solicitação.';
    }
  }
  return ErrorMessages.defaultMsnFailedToLoadData;
}
```

---

## Pagination Best Practices

**Backend Contract:**
- `page` parameter: 0-based index (0, 1, 2, ...)
- `size` parameter: 1-100 (default 20)
- Response includes: `totalElements`, `totalPages`, `currentPage`

**Frontend Implementation:**
```dart
Future<UserChatMessagePageModel> getMessagesByConversation({
  required String conversationId,
  required int page,
  int size = 20,
}) async {
  // Validation
  if (page < 0) {
    throw UserMessageFlowException('Page must be >= 0');
  }
  if (size < 1 || size > 100) {
    throw UserMessageFlowException('Size must be 1-100');
  }
  
  final endpoint = 'messages/conversation/$conversationId?page=$page&size=$size';
  final response = await _dio.get(endpoint);
  
  return UserChatMessagePageModel.fromApiMap(
    response.data,
    currentUserId: AuthTokenManager.currentUserId,
  );
}
```

---

## Authentication Pattern

**All requests automatically include JWT token via Dio interceptor:**

```dart
// lib/app/core/auth/auth_token_manager.dart
final token = await AuthTokenManager.getToken();

// Dio interceptor adds header automatically
// Authorization: Bearer <token>

// No need to manually add header in repository methods
```

**Check for expired token:**
```dart
if (token == null) {
  throw UserMessageFlowException('Sessão expirada. Faça login novamente.');
}
```

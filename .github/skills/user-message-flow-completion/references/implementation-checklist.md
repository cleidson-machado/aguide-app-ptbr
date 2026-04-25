# Implementation Checklist & Testing Guide

Systematic approach to implementing missing features with quality assurance.

---

## 🎯 General Implementation Checklist

Use this for ANY new feature implementation:

### Phase 1: Planning & Context
- [ ] Read API documentation for relevant endpoint(s)
- [ ] Check Frontend-Backend Analysis for current status
- [ ] Identify existing models, repositories, ViewModels
- [ ] Verify endpoint exists in backend (NEVER assume)
- [ ] Plan which files need changes (list them)
- [ ] Check for existing similar implementations to follow

### Phase 2: Model Layer
- [ ] Create/update model class with all backend fields
- [ ] Add `fromApiMap()` factory constructor
- [ ] Add `toJson()` method (if needed for POST/PUT)
- [ ] Handle nullable fields correctly
- [ ] Add `static fromApiList()` for list parsing (if needed)
- [ ] Test parsing with sample JSON data

### Phase 3: Repository Layer
- [ ] Define method in `*_repository_interface.dart`
- [ ] Add JSDoc comments (description, params, returns, throws)
- [ ] Implement in `*_repository.dart`
- [ ] Create private helper for endpoint (DRY principle)
- [ ] Add input validation (non-empty strings, valid ranges)
- [ ] Map all possible HTTP error codes (401, 403, 404, 500)
- [ ] Handle empty/null responses (204 No Content)
- [ ] Test with Postman/curl before integrating

### Phase 4: ViewModel Layer
- [ ] Add state properties (_isLoading, _error, _data)
- [ ] Create public getters for state
- [ ] Implement business logic method
- [ ] Add try-catch with proper error mapping
- [ ] Call `notifyListeners()` after state changes
- [ ] Add debug logs with emoji prefixes (📜, ✅, ❌)
- [ ] Test error paths (what happens if API fails?)

### Phase 5: UI Layer
- [ ] Create/update screen widget
- [ ] Add ViewModel to widget state (via injector)
- [ ] Implement `initState()` (load data, add listeners)
- [ ] Implement `dispose()` (remove listeners, dispose controllers)
- [ ] Build UI with 4 states: loading, error, empty, content
- [ ] Add pull-to-refresh (if list screen)
- [ ] Add error retry button
- [ ] Test all UI states manually

### Phase 6: Dependency Injection
- [ ] Register repository in `injector.dart` (if new)
- [ ] Register ViewModel in `injector.dart` (if new)
- [ ] Verify injection order (repositories before ViewModels)
- [ ] Test that `injector<T>()` resolves correctly

### Phase 7: Quality Assurance
- [ ] Run `flutter analyze` (target: 0 errors)
- [ ] Fix any linting warnings (const, DRY, etc.)
- [ ] Test happy path (success scenario)
- [ ] Test error paths (401, 404, 500)
- [ ] Test edge cases (empty list, null values)
- [ ] Test loading states (spinner shows/hides)
- [ ] Test navigation (back button, route params)
- [ ] Add debug logs for key actions
- [ ] Document any breaking changes

### Phase 8: Git Commit
- [ ] Review all changed files
- [ ] Add files individually (NO `git add .`)
- [ ] Write descriptive commit message
- [ ] Push to feature branch (not main)

---

## 🧪 Testing Scenarios by Feature

### Feature: Message Pagination

**Test Scenarios:**
```
✅ Load page 0 → Shows first 20 messages
✅ Scroll to top → Loads page 1 (next 20 messages)
✅ Scroll to top again → Loads page 2
✅ Reach last page → hasNextPage = false, no more loads
❌ Invalid page (-1) → Error: "Page must be >= 0"
❌ Invalid size (0) → Error: "Size must be 1-100"
❌ Invalid size (101) → Error: "Size must be 1-100"
❌ API error 401 → Error: "Sessão expirada"
❌ API error 500 → Error: "Erro no servidor"
```

**Manual Test Script:**
```dart
// 1. Open conversation with 50+ messages
// 2. Observe scroll controller at top (pixels == 0)
// 3. Verify page 1 loads automatically
// 4. Check debug logs for "Loading page 1"
// 5. Verify messages inserted at index 0 (prepended)
// 6. Verify no duplicate messages
```

### Feature: Read Receipts

**Test Scenarios:**
```
✅ Open conversation → All unread messages marked as read
✅ Unread badge clears after marking
✅ GET /conversations shows unreadCount = 0 after
❌ API error 500 → Fails silently (no user-facing error)
✅ Multiple unread messages → All marked in sequence
✅ Already read messages → No API call made
```

**Manual Test Script:**
```dart
// 1. Send message to another account
// 2. Switch accounts, open conversation
// 3. Observe unread badge (should be 1)
// 4. Open conversation
// 5. Verify badge disappears within 1 second
// 6. Check network logs for PUT /messages/{id}/read calls
// 7. Close and reopen conversation
// 8. Verify badge still shows 0
```

### Feature: Unread Count Badge

**Test Scenarios:**
```
✅ Initial load → Shows correct total unread count
✅ Receive new message → Count increments
✅ Mark conversation as read → Count decrements
✅ Polling (30s) → Updates count automatically
✅ Zero unread → Badge hidden
❌ API error 401 → Stops polling, shows last known count
```

**Manual Test Script:**
```dart
// 1. Start app with 5 unread messages
// 2. Observe badge shows "5"
// 3. Send message from another account
// 4. Wait 30 seconds (next poll)
// 5. Verify badge shows "6"
// 6. Open conversation and mark as read
// 7. Verify badge decrements to appropriate count
```

### Feature: Create Direct Conversation

**Test Scenarios:**
```
✅ Select user → Creates 1-on-1 conversation
✅ User already has conversation → Returns existing (no duplicate)
✅ Success → Navigates to chat screen
❌ User ID doesn't exist → Error: "Usuário não encontrado"
❌ Trying to create with self → Error: "Não é possível criar conversa consigo mesmo"
❌ API error 401 → Error: "Sessão expirada"
✅ Shows loading modal during creation
```

**Manual Test Script:**
```dart
// 1. Go to users list screen
// 2. Tap on user "João Silva"
// 3. Observe loading modal appears
// 4. Verify API call: POST /conversations/direct {otherUserId: "..."}
// 5. Verify navigation to chat screen
// 6. Send a message successfully
// 7. Go back to users list
// 8. Tap same user again
// 9. Verify same conversation ID returned (no duplicate)
```

### Feature: Archive/Pin Conversation

**Test Scenarios:**
```
✅ Swipe conversation → Shows archive/pin actions
✅ Archive → Conversation hidden from inbox
✅ Show archived → Conversation appears in archived list
✅ Unarchive → Conversation back in inbox
✅ Pin → Conversation at top of inbox
✅ Unpin → Conversation moves to chronological position
❌ API error 403 → Error: "Você não tem permissão"
```

**Manual Test Script:**
```dart
// 1. Long-press conversation in inbox
// 2. Tap "Pin" action
// 3. Verify conversation moves to top
// 4. Verify pin icon appears
// 5. Refresh inbox (pull-to-refresh)
// 6. Verify conversation still pinned
// 7. Unpin conversation
// 8. Verify returns to chronological order
```

### Feature: Edit Message

**Test Scenarios:**
```
✅ Long-press own message → Shows "Edit" option
✅ Edit message → Updates content in UI
✅ Edited message shows "Edited" badge
✅ Other people see edited version
❌ Long-press others' message → NO "Edit" option
❌ API error 403 → Error: "Você não pode editar esta mensagem"
✅ Edit timeout (5 min) → "Não é mais possível editar"
```

**Manual Test Script:**
```dart
// 1. Send message "Hello"
// 2. Long-press on message
// 3. Tap "Edit" from menu
// 4. Change to "Hello World"
// 5. Submit edit
// 6. Verify content updates in UI
// 7. Verify "Edited" badge appears
// 8. Check other user's screen (should see edited version)
```

### Feature: Delete Message

**Test Scenarios:**
```
✅ Long-press own message → Shows "Delete" option
✅ Confirm delete → Message removed from UI
✅ Backend soft-deletes (content = "Message deleted")
❌ Long-press others' message → NO "Delete" option
❌ API error 403 → Error: "Você não pode deletar esta mensagem"
✅ Deleted message shows placeholder in threads
```

**Manual Test Script:**
```dart
// 1. Send message "Test"
// 2. Long-press on message
// 3. Tap "Delete" from menu
// 4. Confirm deletion in dialog
// 5. Verify message removed from UI
// 6. Refresh conversation (pull-to-refresh)
// 7. Verify message still gone (soft-deleted on backend)
```

### Feature: Image/Video Messages

**Test Scenarios:**
```
✅ Tap attach button → Shows image picker
✅ Select image → Uploads to storage
✅ Upload complete → Sends message with URL
✅ Message displays image thumbnail
✅ Tap image → Opens full-screen view
❌ Upload fails → Error: "Falha ao enviar imagem"
✅ Shows upload progress (0-100%)
```

**Manual Test Script:**
```dart
// 1. Open conversation
// 2. Tap "+" button (attach)
// 3. Select "Image" option
// 4. Choose photo from gallery
// 5. Observe upload progress indicator
// 6. Verify image appears as thumbnail in chat
// 7. Tap thumbnail → Opens full-screen viewer
// 8. Pinch to zoom works
// 9. Close viewer → Returns to chat
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Pagination Not Working

**Symptoms:**
- Messages don't load when scrolling up
- `hasNextPage = true` but nothing happens

**Debug Steps:**
```dart
1. Add debug log in scroll listener:
   debugPrint('Scroll position: ${_scrollController.position.pixels}');
   
2. Verify listener attached in initState:
   _scrollController.addListener(_onScroll);
   
3. Check guard clause:
   if (!_viewModel.hasNextPage || _viewModel.isLoading) return;
   
4. Verify API call in network logs (Charles/Proxyman)
```

**Solution:**
```dart
void _onScroll() {
  // For chat messages: load older when at top
  if (_scrollController.position.pixels == 0) {
    if (kDebugMode) {
      debugPrint('📜 At top, hasNext=${_viewModel.hasNextPage}');
    }
    if (_viewModel.hasNextPage && !_viewModel.isLoading) {
      _viewModel.loadNextPage(conversationId: widget.conversationId);
    }
  }
}
```

### Issue 2: Read Receipts Not Clearing Badge

**Symptoms:**
- Opened conversation but badge still shows unread
- `markMessageAsRead()` called but no effect

**Debug Steps:**
```dart
1. Check if method is called in initState:
   _viewModel.markAllAsRead(widget.conversationId);
   
2. Verify API endpoint in repository:
   await _dio.put('messages/$messageId/read');
   
3. Check network logs for 204 responses
   
4. Verify backend actually clears unread flag
```

**Solution:**
```dart
// In initState
@override
void initState() {
  super.initState();
  // Load messages FIRST
  _viewModel.loadInitialMessages(widget.conversationId);
  
  // THEN mark as read (after messages loaded)
  Future.delayed(Duration(milliseconds: 500), () {
    _viewModel.markAllAsRead(widget.conversationId);
  });
}
```

### Issue 3: Duplicate Conversations Created

**Symptoms:**
- Tapping user creates new conversation each time
- Should return existing conversation

**Debug Steps:**
```dart
1. Check backend response logs
2. Verify backend endpoint deduplicates
3. Check conversation ID returned matches existing
```

**Solution:**
Backend should handle deduplication automatically. If not, add check:

```dart
Future<UserMessageContactModel> createDirectConversation({
  required String otherUserId,
}) async {
  // First check if conversation exists
  final existing = await getConversations(includeArchived: true);
  final match = existing.firstWhere(
    (c) => c.type == 'DIRECT' && c.participantIds.contains(otherUserId),
    orElse: () => null,
  );
  
  if (match != null) {
    return match; // Return existing
  }
  
  // Create new
  final response = await _dio.post('conversations/direct', data: {
    'otherUserId': otherUserId,
  });
  return UserMessageContactModel.fromApiMap(response.data);
}
```

### Issue 4: Navigator.pop() Causes Black Screen

**Symptoms:**
- Tapping back button shows black screen
- Screen was opened in TAB, not via navigation

**Solution:**
```dart
// Identify if screen is TAB or NAVIGATED
final canPop = Navigator.of(context).canPop();
debugPrint('Can pop: $canPop'); // false = TAB

// If TAB, use ancestor access
final homeState = context.findAncestorStateOfType<HomeContentTabScreenState>();
homeState?.resetToFirstTab();

// If NAVIGATED, safe to pop
Navigator.of(context).pop();
```

### Issue 5: Optimistic UI Doesn't Rollback on Error

**Symptoms:**
- Sent message stays in UI even if API fails
- No error shown to user

**Solution:**
```dart
Future<void> sendMessage(String content) async {
  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final tempMessage = UserChatMessageModel(
    id: tempId,
    text: content,
    isSentByMe: true,
    isPending: true, // Add this flag to model
  );
  
  _messages.add(tempMessage);
  notifyListeners();
  
  try {
    final sent = await _repository.sendMessage(content: content);
    
    // Replace temp with real
    final index = _messages.indexWhere((m) => m.id == tempId);
    if (index != -1) {
      _messages[index] = sent;
    }
  } catch (e) {
    // ROLLBACK: Remove temp message
    _messages.removeWhere((m) => m.id == tempId);
    _error = _mapError(e);
  } finally {
    notifyListeners();
  }
}
```

---

## 📊 Performance Testing

### Test: Large Conversation (1000+ messages)

**Metrics to Monitor:**
- Initial load time (page 0): < 2 seconds
- Scroll FPS: 60 fps minimum
- Memory usage: < 200 MB for 1000 messages
- Pagination delay: < 1 second per page

**Tools:**
```bash
# DevTools Performance tab
flutter run --profile
# Open DevTools → Performance
# Record scroll actions
# Analyze frame render times
```

### Test: Rapid Message Sending

**Scenario:**
1. Send 10 messages in quick succession
2. Verify no duplicate messages
3. Verify correct order
4. Verify all sent successfully

**Expected Behavior:**
- Optimistic UI shows all 10 immediately
- Each replaces with server response
- No race conditions or duplicates

---

## 🎓 Pre-Commit Final Checklist

Before committing ANY feature:

```bash
# 1. Clean and rebuild
flutter clean
flutter pub get

# 2. Analyze code
flutter analyze
# Target: 0 errors, < 5 warnings

# 3. Format code
dart format lib/

# 4. Test on both platforms (if cross-platform)
flutter build apk --debug  # Android
flutter build ios --debug  # iOS

# 5. Review changes
git diff

# 6. Add files individually
git add lib/features/user_message_flow/new_file.dart
# NO git add . or git add -A

# 7. Commit with descriptive message
git commit -m "feat(user_message_flow): implement message pagination

- Add loadNextPage() method to ViewModel
- Integrate infinite scroll in chat screen
- Add page validation (0-100 range)
- Handle edge case: last page (hasNextPage=false)
"
```

---

## 📝 Documentation Updates

After implementing feature, update these files:

1. **Feature README (create if missing):**
   ```markdown
   # lib/features/user_message_flow/README.md
   
   - [x] List conversations
   - [x] Send text messages
   - [x] Load messages (pagination)
   - [x] Mark as read
   - [ ] Create group conversation (TODO)
   ```

2. **x_temp_files/FEATURE_STATUS.md:**
   ```markdown
   ## User Message Flow - Status Update [Date]
   
   ### Completed
   - ✅ Message pagination (page 0-N)
   - ✅ Read receipts (PUT /messages/{id}/read)
   
   ### In Progress
   - 🔄 Unread count badge
   
   ### Pending
   - ❌ Archive/pin conversations
   ```

3. **Git Commit Message Template:**
   ```
   feat(scope): brief description
   
   - Bullet point 1
   - Bullet point 2
   
   Closes #issue-number
   ```

---

## 🚀 Next Steps After This Checklist

1. Choose a feature from priority list (CRITICAL → HIGH → MEDIUM → LOW)
2. Follow Implementation Checklist step-by-step
3. Test thoroughly using scenarios above
4. Commit changes with descriptive message
5. Move to next feature

**Recommended Implementation Order:**
1. Message Pagination (CRITICAL) - State exists, just need method
2. Mark as Read (CRITICAL) - Endpoint exists, need integration
3. Unread Count Badge (HIGH) - Endpoint exists, need polling
4. Real-time Updates (HIGH) - No backend WebSocket, use polling
5. Archive/Pin (MEDIUM) - Endpoint exists, need UI
6. Edit/Delete Message (MEDIUM) - Endpoint exists, need long-press menu
7. Image/Video Messages (MEDIUM) - Endpoint exists, need file upload
8. Search Messages (LOW) - Endpoint exists, need search UI

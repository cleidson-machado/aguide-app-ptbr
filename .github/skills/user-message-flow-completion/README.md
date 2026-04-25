# User Message Flow Completion Skill

**Status:** ~70% Complete → Target: 100%  
**Backend:** Java Quarkus (17 endpoints available)  
**Frontend:** Flutter/Dart (3 endpoints integrated)  
**Gap:** 14 missing integrations + real-time updates

---

## 📁 Skill Structure

```
user-message-flow-completion/
├── SKILL.md                        # Main workflow & procedures
└── references/
    ├── endpoint-quick-reference.md  # Endpoint status & HTTP patterns
    ├── code-templates.md            # Ready-to-use code snippets
    └── implementation-checklist.md  # Testing & QA guidelines
```

---

## 🎯 What This Skill Does

Provides **complete implementation guidance** for finalizing the `user_message_flow` feature:

✅ **API Contract Reference** - Official backend endpoint documentation  
✅ **Gap Analysis** - What's missing vs what backend provides  
✅ **Step-by-Step Guides** - For each missing feature (pagination, read receipts, etc.)  
✅ **Code Templates** - Repository, ViewModel, Screen patterns  
✅ **Testing Scenarios** - Manual test scripts & expected behavior  
✅ **Quality Assurance** - Validation, error handling, performance

---

## 📚 Mandatory Reference Sources

**Load BEFORE implementing any feature:**

1. `.local_knowledge/add-user-message-c/USERMESSAGE_API_DOCUMENTATION.md`
   - 17 backend endpoints (9 conversation + 8 message)
   - Request/response contracts

2. `.local_knowledge/add-user-message-c/FRONTEND_BACKEND_ANALYSIS_REPORT.md`
   - Gap analysis matrix
   - DRY violations to fix

3. `.local_knowledge/add-user-message-c/REFATORACAO_USERS_MESSAGE_BUCKET_CONCLUIDA.md`
   - Recent refactoring patterns

---

## 🚦 When to Invoke

Use this skill for:
- ✅ "Complete user_message_flow feature"
- ✅ "Implement message pagination"
- ✅ "Add read receipts"
- ✅ "Integrate [specific endpoint]"
- ✅ "Fix DRY violations in messaging"

Do NOT use for:
- ❌ Backend implementation (Quarkus code)
- ❌ Non-messaging features

---

## 🎓 Quick Start

**1. Identify Feature to Implement**

Check `references/endpoint-quick-reference.md` for priority:
- 🔴 CRITICAL: Message pagination, mark as read, unread count
- 🟠 HIGH: Real-time updates, create group
- 🟡 MEDIUM: Archive/pin, edit/delete, media messages
- 🟢 LOW: Search, thread replies

**2. Follow Implementation Checklist**

See `references/implementation-checklist.md`:
- Phase 1: Planning & Context
- Phase 2: Model Layer
- Phase 3: Repository Layer
- Phase 4: ViewModel Layer
- Phase 5: UI Layer
- Phase 6: Dependency Injection
- Phase 7: Quality Assurance
- Phase 8: Git Commit

**3. Use Code Templates**

Copy from `references/code-templates.md`:
- Repository method (interface + implementation)
- ViewModel method with error handling
- Screen with MVVM integration
- Infinite scroll pattern
- Pull-to-refresh pattern

**4. Test Thoroughly**

Use scenarios from `references/implementation-checklist.md`:
- Happy path (success case)
- Error paths (401, 404, 500)
- Edge cases (empty list, null values)
- Performance (1000+ messages, rapid sending)

---

## 🔧 Architecture Patterns

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
- ✅ DRY - Create helpers for duplicated code
- ✅ SOLID - Depend on interfaces, not implementations
- ✅ DDD - Feature independence (don't modify core features)
- ✅ Error Handling - User-friendly, translated messages
- ✅ Performance - Pagination, caching, optimistic UI

---

## 📊 Current Status Snapshot

| Category | Done | Missing | Priority |
|----------|------|---------|----------|
| Conversation Management | 1/9 | 8 | MEDIUM |
| Message Operations | 2/8 | 6 | CRITICAL |
| Real-time Features | 0/4 | 4 | HIGH |
| UI/UX Patterns | 2/8 | 6 | MEDIUM |

**Total Progress:** 5 of 29 features implemented (~17%)

---

## 🎯 Immediate Next Actions

**Recommended Implementation Order:**

1. **Message Pagination** (2 hours)
   - State already exists in ViewModel
   - Just need `loadNextPage()` method
   - High impact (users can't see old messages)

2. **Mark as Read** (1 hour)
   - Endpoint exists: `PUT /messages/{id}/read`
   - Clear unread badges
   - Fix user frustration

3. **Unread Count Badge** (2 hours)
   - Endpoint exists: `GET /conversations/unread-count`
   - Add polling service (30s interval)
   - Display in app navigation

4. **Real-time Updates** (4 hours)
   - No WebSocket backend → Use polling
   - Poll conversations every 10s when app active
   - Auto-refresh message list on new messages

5. **Archive/Pin** (3 hours)
   - Endpoints exist: `PUT /conversations/{id}/archive|pin`
   - Add swipe actions in conversation list
   - Update UI instantly (optimistic)

---

## 📝 Success Criteria

Feature is complete when:
- ✅ Repository method added (interface + implementation)
- ✅ ViewModel method with error handling
- ✅ UI screen integrated
- ✅ Dependencies registered in injector
- ✅ `flutter analyze` shows 0 errors
- ✅ All test scenarios pass (happy path + errors)
- ✅ Debug logs added for key actions
- ✅ Git commit with descriptive message

---

## 🚀 Related Documentation

- Project Instructions: `.github/copilot-instructions.md`
- Dependency Injection: `lib/app/core/config/injector.dart`
- Feature Location: `lib/features/user_message_flow/`
- Backend API Docs: `.local_knowledge/add-user-message-c/USERMESSAGE_API_DOCUMENTATION.md`

---

## 💡 Tips for Success

1. **Always start by reading the 3 reference documents**
2. **Never assume endpoint exists** - verify in API docs
3. **Follow existing patterns** - Check similar implementations
4. **Test early and often** - Don't wait until finish
5. **Use debug logs** - Prefix with emojis (📜, ✅, ❌)
6. **Commit frequently** - Small, focused commits
7. **Ask for help** - If stuck, reference the skill docs

---

**Version:** 1.0  
**Last Updated:** April 18, 2026  
**Maintainer:** Flutter Development Team

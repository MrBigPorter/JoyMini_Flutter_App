# AI Chat Fixes — Root Cause Analysis & Resolution

## 2026-07-17: Duplicate Messages + Typewriter + Layout

### Bug 1: Duplicate Messages (User & AI) on Conversation Re-entry

**Root Cause:** Two problems compounded:

1. **SyncStep didn't save `seqId`** from server response (`pipeline_steps.dart`)
   - `sendText()` → `Api.sendMessage()` returns `{id, seqId, ...}` 
   - `SyncStep.patchFields()` only wrote `status/content/meta` — **skipped `seqId`**
   - Result: local message always had `seqId=null` in DB

2. **`saveMessages()` dedup only matched by `seqId`** (`local_database_service.dart`)
   - API sync returns same message with `seqId=22`
   - Dedup: find records with `seqId=22` → local has `seqId=null` → **MISS**
   - API version saved as new record → **duplicate**

**Fix:**
- `SyncStep` now writes `serverMsg.seqId` to local DB via `patchFields`
- `saveMessages()` now cleans up ALL `seqId=null` residuals (not just AI)
  after dedup, for any message type — catches orphans from SyncStep/ai_done

### Bug 2: Sent Messages on Wrong Side (isMe=false)

**Root Cause:** `ChatViewModel._saveApiMessages()` called `fromApiModel(m, conversationId)` without `currentUserId`.

```dart
// Before
.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId))
// After
.map((m) => ChatUiModelMapper.fromApiModel(m, conversationId, currentUserId))
```

Without the userId, `isMe` relied solely on the server's `isSelf` field. When
the server didn't set it, synced messages showed on the left (receiver side).

### Bug 3: Typewriter Effect Missing + Layout Instability

**Root Cause:** `currentAiToken` was accumulated in `ChatListState` but never
rendered. The only UI feedback during streaming was `_buildAiStatusText` —
a spinner + step text outside the `Expanded` message list, causing layout jumps.

**Fix:**
- Moved AI streaming content **inside** `ScrollablePositionedList` (index 0)
- Added `_buildStreamingBubble()` in `chat_page_widgets.dart`:
  - Shows `currentAiToken` as a live text bubble
  - Blinking cursor via `_BlinkingCursor` (FadeTransition animation)
  - `aiStatusText` as step indicator above the bubble
- This also stabilized layout since the streaming widget is inside
  `Expanded`, not in the outer `Column`

### Files Modified

| File | Change |
|---|---|
| `lib/ui/chat/pipeline/pipeline_steps.dart` | SyncStep saves `serverMsg.seqId` |
| `lib/ui/chat/services/database/local_database_service.dart` | Orphan cleanup for all types; dedup logging |
| `lib/ui/chat/providers/chat_view_model.dart` | Pass `currentUserId` to `fromApiModel` |
| `lib/ui/chat/chat_room/chat_page.dart` | Remove standalone status bar; add streaming bubble to list |
| `lib/ui/chat/chat_room/chat_page_widgets.dart` | `_buildStreamingBubble` widget |

### Files Cleaned Up

| File | Reason |
|---|---|
| `lib/core/services/ai/sse_client*.dart` (6 files) | Old SSE approach, replaced by Socket.IO |
| `lib/core/store/ai_chat/*.dart` (2 files) | Old SSE state management, replaced by ChatViewModel |
| `docs/architecture/ai_sse_streaming_architecture.md` | Obsolete SSE architecture doc |

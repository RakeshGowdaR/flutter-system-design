# Design a Chat App (Interview Style)

## Requirements

**Functional:**
- One-on-one messaging
- Group chats (up to 100 members)
- Send text, images, and files
- Online/offline status indicators
- Read receipts
- Message history (paginated)

**Non-Functional:**
- Messages delivered in real-time (<500ms)
- Works offline (queue messages, sync when back)
- Message order must be preserved
- Support 1M concurrent users

---

## High-Level Architecture

```
┌─────────────┐         ┌──────────────────────────────────────┐
│             │  WSS    │            Backend                    │
│   Flutter   │◄──────►│  WebSocket Gateway                   │
│    App      │         │       ↕                               │
│             │  HTTPS  │  Chat Service ──→ Message Queue       │
│             │◄──────►│       ↕              ↕                │
└─────────────┘         │  User Service   Notification Svc     │
                        │       ↕                               │
                        │  PostgreSQL + Redis + S3              │
                        └──────────────────────────────────────┘

Flutter App Internal Architecture:

┌────────────────────────────────────────────┐
│           Presentation Layer               │
│  ChatListScreen → ChatScreen → MessageBubble│
│  ChatListCubit    ChatCubit                │
├────────────────────────────────────────────┤
│            Domain Layer                    │
│  ChatService, MessageService               │
├────────────────────────────────────────────┤
│             Data Layer                     │
│  ChatRepository                            │
│    ├── WebSocketDataSource (real-time)      │
│    ├── ApiDataSource (REST for history)     │
│    └── LocalDataSource (Drift/SQLite)       │
└────────────────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Real-Time: WebSocket vs Polling

**WebSocket** — persistent connection, server pushes messages instantly.

```dart
class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessage>.broadcast();
  
  Stream<ChatMessage> get messageStream => _messageController.stream;
  
  Future<void> connect(String token) async {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://chat.example.com/ws?token=$token'),
    );
    
    _channel!.stream.listen(
      (data) {
        final message = ChatMessage.fromJson(jsonDecode(data));
        _messageController.add(message);
      },
      onDone: () => _reconnect(token),
      onError: (_) => _reconnect(token),
    );
  }
  
  Future<void> _reconnect(String token) async {
    await Future.delayed(const Duration(seconds: 2));
    await connect(token);  // Simple reconnect — add exponential backoff for production
  }
  
  void sendMessage(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }
  
  void dispose() {
    _channel?.sink.close();
    _messageController.close();
  }
}
```

### 2. Local Storage for Offline + Fast Loads

```dart
// Messages stored locally using Drift (SQLite)
class LocalChatDataSource {
  final AppDatabase _db;
  
  /// Watch messages for a chat — reactive stream
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return (_db.select(_db.messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }
  
  /// Save messages (from API or WebSocket)
  Future<void> saveMessages(List<ChatMessage> messages) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.messages,
        messages.map((m) => m.toCompanion()).toList(),
      );
    });
  }
}
```

### 3. Message Flow

**Sending a message:**

```
User types message and taps send
       ↓
1. Generate local ID (UUID)
2. Save to local DB with status: SENDING
3. UI shows message immediately (optimistic)
       ↓
4. Send via WebSocket (or REST if WS disconnected)
       ↓
5. Server assigns server ID and timestamp
6. Server broadcasts to all chat members via WebSocket
       ↓
7. Update local message: status: SENT, add server ID
       ↓
8. Other members receive via WebSocket → save to local DB → UI updates
```

```dart
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepo;
  final WebSocketService _ws;
  StreamSubscription? _messageSub;
  
  void enterChat(String chatId) {
    // Load from local DB first (instant)
    _chatRepo.watchMessages(chatId).listen((messages) {
      emit(ChatState.loaded(messages: messages, chatId: chatId));
    });
    
    // Fetch missing messages from API
    _chatRepo.syncMessages(chatId);
    
    // Listen for new messages via WebSocket
    _messageSub = _ws.messageStream
        .where((msg) => msg.chatId == chatId)
        .listen((msg) => _chatRepo.saveMessage(msg));
  }
  
  Future<void> sendMessage(String chatId, String text) async {
    final message = ChatMessage(
      localId: uuid.v4(),
      chatId: chatId,
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    // Save locally (UI updates via stream)
    await _chatRepo.saveMessage(message);
    
    // Send to server
    final result = await _chatRepo.sendMessage(message);
    result.when(
      success: (serverMsg) => _chatRepo.updateMessageStatus(
        message.localId, MessageStatus.sent, serverMsg.serverId,
      ),
      failure: (_, __) => _chatRepo.updateMessageStatus(
        message.localId, MessageStatus.failed, null,
      ),
    );
  }
}
```

### 4. Pagination for Message History

```dart
class ChatRepository {
  Future<void> loadOlderMessages(String chatId, {required String beforeMessageId}) async {
    final response = await _api.get(
      '/chats/$chatId/messages',
      queryParameters: {
        'before': beforeMessageId,
        'limit': 50,
      },
    );
    
    final messages = (response.data['messages'] as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
    
    await _localDb.saveMessages(messages);
    // UI auto-updates via watchMessages stream
  }
}
```

### 5. Read Receipts

```
Alice sends message to Bob
       ↓
Bob's app receives message → mark as DELIVERED → notify server
       ↓
Bob opens the chat → mark as READ → notify server
       ↓
Server notifies Alice → update message status to READ
       ↓
Alice sees blue checkmarks ✓✓
```

```dart
// Track last read position per chat
class ReadReceiptService {
  Future<void> markAsRead(String chatId, String lastMessageId) async {
    // Debounce — don't send for every message scrolled past
    _debouncer.run(() async {
      await _api.post('/chats/$chatId/read', data: {
        'last_read_message_id': lastMessageId,
      });
    });
  }
}
```

---

## Data Model

```
ChatMessage {
  localId: String        // UUID generated on device
  serverId: String?      // Assigned by server after sync
  chatId: String
  senderId: String
  text: String?
  mediaUrl: String?
  mediaType: String?     // 'image', 'file', 'video'
  timestamp: DateTime
  status: MessageStatus  // sending, sent, delivered, read, failed
}

Chat {
  id: String
  name: String?          // null for 1-on-1
  type: ChatType         // direct, group
  members: List<String>
  lastMessage: ChatMessage?
  unreadCount: int
  updatedAt: DateTime
}
```

---

## Trade-offs Discussed

| Decision | Choice | Why |
|----------|--------|-----|
| Real-time transport | WebSocket | Lower latency than polling, server-initiated push |
| Local storage | SQLite (Drift) | Structured queries, reactive streams, handles 100K+ messages |
| Message ordering | Server timestamp | Client clocks can't be trusted |
| ID generation | Local UUID + Server ID | Immediate UI feedback, server is authority |
| Offline writes | Sync queue | Messages feel instant, sync when online |
| Image upload | Pre-signed S3 URL | Don't send binary through WebSocket |

---

## What the Interviewer Wants to Hear

1. **Offline-first thinking** — Local DB is the source of truth, not the API
2. **Optimistic updates** — User sees their message immediately, sync happens in background
3. **Real-time architecture** — WebSocket for push, REST for history
4. **Pagination** — You can't load 10K messages at once
5. **Conflict handling** — What if a message is sent while offline and the chat was deleted?
6. **Scalability** — Connection pooling, message fan-out for groups, CDN for media

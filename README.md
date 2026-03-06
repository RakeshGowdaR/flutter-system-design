# 📐 Flutter System Design

How to design and architect Flutter apps that scale — from a single screen to millions of users.

This isn't about backend system design. This is about the **real architectural decisions** Flutter developers face when building production apps: how data flows, how state is managed across 50+ screens, how to handle offline mode, how to structure navigation in a complex app, and how to keep everything testable and maintainable.

> **"Any app that grows beyond 10 screens without architecture will eventually collapse under its own weight."**

---

## Who This Is For

- Flutter developers building apps with real complexity (not todo apps)
- Mobile engineers preparing for Flutter system design interviews
- Teams deciding on architecture before starting a large project
- Developers who've hit scaling walls and need to refactor

---

## Table of Contents

### Part 1: Architecture Foundations

| # | Chapter | The Question It Answers |
|---|---------|------------------------|
| 1 | [App Architecture Overview](chapters/01-app-architecture.md) | How do I structure a large Flutter app? |
| 2 | [Data Flow & State Management](chapters/02-data-flow.md) | Where does state live and how does it move? |
| 3 | [Navigation Architecture](chapters/03-navigation.md) | How do I handle routing in a 50+ screen app? |
| 4 | [Dependency Injection](chapters/04-dependency-injection.md) | How do I wire everything together without spaghetti? |

### Part 2: Real-World Challenges

| # | Chapter | The Question It Answers |
|---|---------|------------------------|
| 5 | [Offline-First Architecture](chapters/05-offline-first.md) | How do I make my app work without internet? |
| 6 | [Pagination & Infinite Scroll](chapters/06-pagination.md) | How do I load and display thousands of items efficiently? |
| 7 | [Authentication Flow](chapters/07-auth-flow.md) | How do I handle login, token refresh, and session expiry? |
| 8 | [Push Notifications](chapters/08-push-notifications.md) | How do I architect notifications end-to-end? |
| 9 | [Deep Linking & Dynamic Links](chapters/09-deep-linking.md) | How do I handle links that open specific screens? |
| 10 | [Image Loading & Caching](chapters/10-image-caching.md) | How do I display 1000s of images without running out of memory? |
| 11 | [Background Processing](chapters/11-background-processing.md) | How do I run tasks when the app is in the background? |
| 12 | [Analytics & Logging](chapters/12-analytics.md) | How do I track what users do without slowing the app? |
| 13 | [App Performance](chapters/13-performance.md) | How do I find and fix jank, memory leaks, and slow screens? |
| 14 | [Multi-Module / Package Architecture](chapters/14-multi-module.md) | How do I split a huge app into independent modules? |

### Part 3: Design Problems (Interview Style)

| Problem | Difficulty |
|---------|-----------|
| [Design a Chat App](chapters/15-design-chat-app.md) | Medium |
| [Design an E-Commerce App](chapters/16-design-ecommerce.md) | Medium |
| [Design a Social Media Feed](chapters/17-design-social-feed.md) | Hard |
| [Design a Video Streaming App](chapters/18-design-video-app.md) | Hard |

### Quick References

| Cheatsheet | Description |
|------------|-------------|
| [Architecture Decision Checklist](cheatsheets/architecture-checklist.md) | Questions to ask before you start building |
| [State Management Decision Tree](cheatsheets/state-management-decision.md) | Which state management to use and when |
| [Package Recommendations](cheatsheets/recommended-packages.md) | Tried-and-tested packages for common needs |

### Code Examples

```
examples/
├── offline_first/
│   ├── sync_manager.dart            # Sync queue with retry logic
│   ├── local_database.dart          # Drift (SQLite) setup
│   └── connectivity_monitor.dart    # Network state listener
├── pagination/
│   ├── paginated_list_cubit.dart    # Generic paginated state management
│   └── infinite_scroll_list.dart    # Reusable infinite scroll widget
├── deep_linking/
│   └── route_parser.dart            # Deep link → screen mapping
├── push_notifications/
│   └── notification_handler.dart    # FCM setup and routing
└── analytics/
    ├── analytics_service.dart       # Analytics abstraction layer
    └── event_bus.dart               # Lightweight event tracking
```

---

## The Big Picture

Every Flutter app at scale has these layers:

```
┌─────────────────────────────────────────────┐
│                    UI Layer                  │
│         Screens, Widgets, Animations        │
├─────────────────────────────────────────────┤
│               State Management              │
│       Cubit / Bloc / Riverpod / etc.        │
├─────────────────────────────────────────────┤
│                Domain Layer                 │
│        Services, Use Cases, Logic           │
├─────────────────────────────────────────────┤
│                 Data Layer                  │
│  Repositories, API Client, Local Storage    │
├─────────────────────────────────────────────┤
│                  Platform                   │
│   Plugins, Native Channels, Permissions     │
└─────────────────────────────────────────────┘
```

Each chapter in this repo focuses on a specific cross-cutting concern and shows how it fits into this architecture.

---

## How to Use This Repo

**Building a new app?** → Read Part 1 (Architecture Foundations) first, then pick relevant chapters from Part 2.

**Preparing for interviews?** → Study Part 3 (Design Problems). Practice drawing the diagrams and explaining your trade-offs.

**Solving a specific problem?** → Jump directly to the relevant chapter. Each one is self-contained.

---

## Contributing

Real-world experience makes this repo better. If you've architected a Flutter app at scale, your insights are welcome.

- Share a pattern that worked (or one that didn't)
- Add a design problem with your solution
- Improve existing chapters with edge cases you've encountered

---

## License

MIT

---

**Repo description:** System design and architecture for Flutter apps at scale — offline-first, pagination, auth flows, navigation, and interview-style design problems with real Dart code.

**Topics:** `flutter`, `system-design`, `mobile-architecture`, `dart`, `clean-architecture`, `offline-first`, `interview-preparation`, `mobile-development`

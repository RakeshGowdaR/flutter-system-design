# State Management Decision Tree

A practical guide to choosing the right approach for each situation.

---

## The Quick Answer

```
"Which state management should I use?"

Is your team already using one?
  └── Yes → Keep using it. Migration cost > theoretical benefits.
  └── No → Read below.
```

## Decision Tree

```
What kind of state are you managing?
│
├── Animation, focus, hover, scroll position
│   └── Use: StatefulWidget / AnimationController
│   └── Why: Ephemeral state doesn't need global management
│
├── Form input, toggle, tab selection (single screen)
│   └── Use: StatefulWidget or useState (flutter_hooks)
│   └── Why: Simple, local, no need to share
│
├── Feature state (list of items, detail page, CRUD)
│   ├── Team prefers explicit events and states?
│   │   └── Use: Bloc (event-driven)
│   ├── Want simpler syntax, fewer files?
│   │   └── Use: Cubit (method-driven)
│   └── Want compile-time safety and auto-disposal?
│       └── Use: Riverpod (provider-driven)
│
├── App-wide state (auth, theme, locale, connectivity)
│   ├── Using Bloc/Cubit for features?
│   │   └── Use: Bloc/Cubit at app level with BlocProvider
│   ├── Using Riverpod?
│   │   └── Use: StateNotifierProvider or AsyncNotifierProvider
│   └── Simple app?
│       └── Use: ChangeNotifier + Provider
│
└── Real-time data (chat, live updates, WebSocket)
    └── Use: StreamProvider (Riverpod) or StreamSubscription in Cubit
    └── Why: Streams naturally model continuous data
```

## Comparison Table

| Criteria | Provider | Bloc/Cubit | Riverpod |
|----------|----------|------------|----------|
| Learning curve | Low | Medium | Medium-High |
| Boilerplate | Low | Medium (Bloc), Low (Cubit) | Low |
| Testability | Good | Excellent | Excellent |
| DevTools | Basic | Excellent (Bloc Observer) | Good |
| Compile-time safety | No | No | Yes |
| Auto-dispose | Manual | Manual | Built-in |
| Scalability | Medium | High | High |
| Team adoption | Very common | Very common | Growing |
| Flutter dependency | Yes | No (pure Dart) | No (pure Dart) |

## When to Use What — Concrete Examples

### Provider / ChangeNotifier
```
✅ Good for: Small apps, prototypes, simple shared state
✅ Example: Theme switcher, locale selector, simple auth
❌ Avoid for: Complex state with many transitions, large teams
```

### Cubit (Recommended Default)
```
✅ Good for: Most features — clean, testable, simple
✅ Example: Login flow, product listing, profile editing
❌ Avoid for: Complex event processing with debounce/throttle
```

### Bloc
```
✅ Good for: Complex state machines, event replay, advanced transformations
✅ Example: Search with debounce, multi-step forms, complex filters
❌ Avoid for: Simple CRUD features (Cubit is simpler)
```

### Riverpod
```
✅ Good for: Dependency injection + state management in one
✅ Example: Apps with complex dependency graphs, auto-disposing resources
❌ Avoid for: Teams unfamiliar with it (steep initial learning)
```

## The Honest Truth

The architecture around state management matters more than the choice itself:

```
Bad Bloc code  <  Good Provider code
Good Cubit code  =  Good Riverpod code

What matters:
  ✅ Separating UI from logic
  ✅ Having a clear data flow direction
  ✅ Making state testable
  ✅ Single source of truth for each piece of state

What doesn't matter as much:
  ❌ Bloc vs Cubit vs Riverpod vs Provider
  ❌ Which one has more GitHub stars
  ❌ What the latest blog post recommends
```

Pick one, learn it well, use it consistently.

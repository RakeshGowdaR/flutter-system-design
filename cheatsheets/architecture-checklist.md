# Architecture Decision Checklist

Questions to ask (and answer) before writing code on a Flutter project.

---

## Before You Start

### Scope & Scale
- [ ] How many screens will this app have? (5? 50? 200?)
- [ ] How many developers will work on it? (1? 5? 20?)
- [ ] What's the expected user base? (1K? 100K? 1M+?)
- [ ] Does the app need to work offline?
- [ ] What's the target: MVP in 4 weeks, or production app maintained for years?

### Platform & Constraints
- [ ] iOS + Android? Web? Desktop?
- [ ] Minimum OS versions? (Affects available APIs)
- [ ] Any accessibility requirements?
- [ ] Localization needed? How many languages?

---

## Architecture Decisions

### State Management
- [ ] Which solution? (Bloc/Cubit, Riverpod, Provider, GetX)
- [ ] Team familiar with it? (Don't pick Riverpod if everyone knows Bloc)
- [ ] Where does each type of state live?
  - App state (auth, theme): ___
  - Feature state (product list): ___
  - Screen state (form input): ___
  - Ephemeral state (animation): ___

### Data Layer
- [ ] REST or GraphQL? (REST unless you have a strong reason for GraphQL)
- [ ] Need local database? (Drift, Hive, Isar, or just SharedPreferences?)
- [ ] Caching strategy? (Cache-first? Network-first? TTL?)
- [ ] Offline sync needed? (Queue-based? Conflict resolution?)

### Navigation
- [ ] GoRouter, auto_route, or Navigator 2.0 directly?
- [ ] Deep linking required?
- [ ] Auth-guarded routes?
- [ ] Nested navigation? (Tab bars with independent stacks)

### Dependency Injection
- [ ] GetIt, Riverpod, Provider, or manual?
- [ ] How are dependencies scoped? (App-wide? Per-feature? Per-screen?)

---

## Feature Checklist

For each major feature, answer:

- [ ] Where does the data come from? (API, local DB, both?)
- [ ] What happens when the API is down?
- [ ] What happens on slow connections?
- [ ] Does this feature need real-time updates?
- [ ] What errors can occur? How does the user recover?
- [ ] Is pagination needed?
- [ ] Does this interact with other features' state?
- [ ] How will this be tested? (Unit, widget, integration?)

---

## Production Readiness

- [ ] Error reporting set up? (Crashlytics, Sentry)
- [ ] Analytics tracking? (Firebase, Mixpanel, custom)
- [ ] Environment config? (Dev, staging, production)
- [ ] CI/CD pipeline? (Build, test, deploy)
- [ ] App size acceptable? (<30MB ideal, <100MB max)
- [ ] Performance profiled? (60fps on mid-range devices)
- [ ] Security: tokens in secure storage, not SharedPreferences
- [ ] Security: certificate pinning for sensitive APIs?
- [ ] Accessibility: screen reader support, sufficient contrast

---

## Red Flags That Mean "Refactor Soon"

| Symptom | Likely Cause |
|---------|-------------|
| Changing one feature breaks another | Features are coupled — missing abstraction layer |
| 500+ line widget files | UI and logic mixed — extract Cubit/ViewModel |
| Same API call in 3 places | Missing repository layer |
| "I'm afraid to touch this code" | Missing tests, unclear architecture |
| Build times over 2 minutes | Too many dependencies, consider modularization |
| App size over 100MB | Unused assets, unoptimized images, too many packages |

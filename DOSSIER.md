# Tagify Dossier

**High-Level Objective**

Tagify solves the problem that Spotify's playlist-only organization is one-dimensional — it lets users tag songs with multiple labels and query across them using AND/OR/NOT boolean logic, so they can find exactly the right music for any moment without manually curating dozens of playlists.

---

## System Summary

Tagify is a Flutter mobile/web app (Dart 3.0+, Flutter 3.16+) built on a service-oriented Provider architecture. The tech stack is SQLite (via sqflite/FFI) for local persistence on mobile, an in-memory store for web, the Spotify Web API for all music data and sync, and Provider with ChangeNotifier for reactive state management. The primary user flow is: authenticate via Spotify OAuth PKCE → import your liked songs and playlists → create tags and apply them to songs (each tag is backed by a real Spotify playlist prefixed `#tag:`) → build boolean queries across tags and playlists → export matching results back to Spotify as a queue, playlist, or new tag. The app is deployed to GitHub Pages via a GitHub Actions CI/CD pipeline for the web target.

---

## System Design

### Architecture

The app follows a **service layer pattern** where six services are wired via `MultiProvider` with dependency injection:

```
AuthService (standalone, ChangeNotifier)
  └→ SpotifyService (ProxyProvider, depends on AuthService for tokens)
       ├→ ImportService (ChangeNotifierProxyProvider2, depends on Spotify + DB)
       ├→ TagService (ChangeNotifierProxyProvider2, depends on Spotify + DB)
       └→ ExportService (ChangeNotifierProxyProvider2, depends on Spotify + DB)
DatabaseService (standalone Provider)
```

Each service owns a distinct domain. Screens are consumers that react to service state via `Consumer<T>` widgets. No service talks directly to another service's internal state — they compose through the Provider tree.

### Key Decisions

**Tags as Spotify playlists.** Rather than building a separate backend, tags are stored as Spotify playlists named `#tag:tagname`. This means zero infrastructure cost, zero user accounts to manage, and tags follow the user across devices. The tradeoff is a 95-character tag name limit (Spotify's 100-char playlist name limit minus the 5-char prefix) and reliance on Spotify API rate limits for all mutations.

**Dual-platform database layer.** `DatabaseService` checks `kIsWeb` at the top of every method and delegates to `WebDatabaseService` (in-memory maps with Dart set operations) on web. Mobile uses SQLite with proper schema, indexes, foreign keys, and cascading deletes. This lets the same codebase target both platforms, but web data is ephemeral — it vanishes on page refresh.

**Optimistic UI with rollback.** Single-song tag operations update the local DB first, notify listeners so the UI updates instantly, then sync to Spotify. On Spotify API failure, the local change is rolled back and the error surfaces. This gives snappy UX while maintaining eventual consistency.

**Query engine.** The AND/OR/NOT query maps to SQL: AND uses `HAVING COUNT(DISTINCT tag_id) = N` to require all tags, OR uses `tag_id IN (...)` for any match, NOT uses `NOT IN (subquery)` for exclusion. The web version mirrors this with Dart `Set.intersection`, `Set.union`, and `Set.difference`. All conditions are combined with SQL `AND`, meaning a song must satisfy every specified section simultaneously.

**IndexedStack navigation.** All four main screens stay mounted in memory. This preserves scroll position and state when switching tabs but means all screens are always consuming memory.

### Database Schema (v2)

Three tables: `songs` (9 columns, unique on `spotify_id`), `tags` (7 columns, CHECK constraint on type), `song_tags` (composite primary key, foreign keys with CASCADE). Five indexes cover the common query paths.

---

## Current State

### Fully Implemented and Working (Phases 1–5)

- **Authentication**: Spotify OAuth 2.0 PKCE with SHA256 code challenge, secure token storage, automatic token refresh on 401, web same-tab redirect support
- **Library import**: Paginated fetch of liked songs and playlists (50/batch, 100ms rate-limit delay), progress tracking, cancellation, deduplication by Spotify ID
- **Tag management**: Full CRUD — create (syncs to Spotify playlist), rename, delete. Case-insensitive duplicate detection, 95-char limit validation. Separates user tags from imported playlists (read-only)
- **Song tagging**: Add/remove tags on individual songs with optimistic UI and rollback. Batch tagging via long-press multi-select with progress dialog. Spotify sync in batches of 100
- **Query builder**: Three-section UI (AND/OR/NOT) with real-time query execution, tag picker with search and song counts, results with album art
- **Export**: Three modes — add to Spotify queue (sequential with rate limiting), create Spotify playlist (batch add in 100s), create Tagify tag (local DB + Spotify sync). All cancellable with progress tracking
- **Web deployment**: GitHub Actions CI/CD to GitHub Pages on push to `main`
- **Test suite**: 53 unit tests across ImportService (8), TagService (30), ExportService (14), plus mock infrastructure. Manual mocks, no external mocking framework

### Partially Implemented

- **Dark mode**: Theme definitions exist for both light and dark with Material 3, and `ThemeMode.system` is set, but there's no user toggle — it just follows the OS setting
- **Settings screen**: Displays user profile and song count but version is hardcoded to "1.0.0" and there are no configurable settings beyond import and logout

### Known Bugs and Limitations

- **Batch rollback inconsistency**: Single-song tag operations roll back local DB on Spotify failure; batch operations do not. This can cause local-Spotify divergence after partial batch failures
- **Web storage is ephemeral**: In-memory DB resets on every page refresh. No IndexedDB or other persistent web storage
- **Query semantics ambiguity**: The PRD describes the combination as `(AND tags) OR (OR tags) MINUS (NOT tags)`, but the SQL implementation combines AND and OR sections with SQL `AND`, meaning a song must satisfy both — these are different semantics when both sections have tags
- **Only first artist captured**: `Song.fromSpotifyTrack` takes only `artists[0]`, so collaborator information is lost
- **No token expiry preemption**: Token refresh only happens reactively on 401, not proactively before expiry
- **Tag loading is sequential**: Library screen loads tags for every song one at a time after songs load — slow for large libraries
- **Dead code**: `DatabaseFactory` (225 lines, never imported), `SongTag` model (never imported), most of `Helpers` (9 of 11 methods unused), most of `AppConstants` (URL constants, prefix, folder name all unused, plus `databaseVersion` is stale at 1 vs actual 2)
- **No-op code**: `Tag.displayName` getter has a ternary that returns the same value in both branches; `Helpers.debounce` doesn't actually cancel previous calls
- **Import not resumable**: If cancelled or failed midway, a re-import re-fetches everything from Spotify (deduplication prevents DB duplicates, but it's wasteful on API calls)

### Current Blockers

- None that prevent the core flow from working. The app is functional end-to-end for its implemented phases

---

## Planned Developments

**Phase 6: Polish & Testing** (designed, not yet built)

- **Sync system**: Bidirectional sync between local DB and Spotify with conflict resolution, sync status UI, manual sync trigger, offline queue for mutations
- **Error handling**: Comprehensive error handling throughout (currently basic try/catch), user-facing error messages, retry logic
- **UI polish**: Loading state animations, skeleton screens, search within Tags screen, pull-to-refresh improvements
- **Onboarding**: First-time user flow explaining the tagging concept and walking through initial import
- **Performance**: Lazy loading for large lists, pagination for query results, batch tag loading instead of sequential
- **Accessibility**: Screen reader support, semantic labels, high-contrast mode
- **Testing**: Widget tests (currently zero), integration tests, model serialization tests, query engine tests, DatabaseService direct tests

---

## Engineering Narrative

### What was the hardest technical problem encountered and how was it addressed?

> **[QUESTION FOR YOU]**: The code alone shows several non-trivial problems that were solved — the PKCE OAuth flow with SHA256 challenge generation, the dual-platform database abstraction, the optimistic-UI-with-rollback pattern, and the boolean query engine with SQL/set-operation parity. Which of these (or something else entirely) was the one that actually gave you the most trouble, and what was the debugging/iteration process like? The dossier will be strongest with a specific story here — the dead end you hit, the thing you misunderstood about the Spotify API, the race condition you didn't expect, etc.

From the code, the most architecturally ambitious problem appears to be **making tags live in two places at once** — the local SQLite database for fast querying and Spotify playlists for cross-device persistence. This creates a distributed state problem: every mutation must succeed in both systems, and failures in either need graceful handling. The optimistic-update-with-rollback pattern for individual operations is a sound solution. The fact that batch operations intentionally skip rollback (with a debug comment acknowledging it) suggests this tradeoff was consciously made — correctness for single operations, speed for batch operations, with the expectation that a future sync system will reconcile.

### What would you do differently if starting over?

> **[QUESTION FOR YOU]**: What would *you* say here? From the code, I can identify several candidates, but I don't know which ones you'd actually prioritize. Some observations that might prompt your answer:

- **The `kIsWeb` branching in DatabaseService**: Every method has a platform check at the top. A cleaner approach would be a shared interface (`abstract class DatabasePort`) with separate SQLite and web implementations, selected once at startup via dependency injection. This would eliminate ~50 conditional branches and make the web implementation independently testable.
- **Constants and helpers were pre-built but unused**: `AppConstants` and `Helpers` contain a lot of speculative code (email validation, number formatting, a broken debounce). Starting with only what's needed and adding later would have kept the codebase leaner.
- **DatabaseFactory vs DatabaseService overlap**: Two parallel abstractions for the same concern. The factory approach was abandoned but never deleted — a classic refactoring artifact.
- **No abstract service interfaces**: Services are concrete classes, making them harder to mock (the test mocks reimplement the full API surface). Abstract interfaces would simplify testing.

### What does building this demonstrate about you as an engineer?

This project demonstrates several things:

1. **End-to-end product thinking**: This isn't a tutorial project — it solves a real user problem with a considered UX flow (import → tag → query → export). The choice to store tags as Spotify playlists shows pragmatic architecture: zero-infrastructure, zero-cost, portable across devices, at the expense of some API complexity.

2. **Third-party API integration at depth**: The Spotify integration isn't a thin wrapper — it handles PKCE OAuth, paginated fetching, batch mutations respecting API limits (100 tracks per call, 100ms rate-limit delays), automatic token refresh, and graceful degradation when the API fails. Rate limiting, pagination, and batch size management are real-world concerns that many portfolio projects skip.

3. **Thoughtful state management**: The optimistic-UI-with-rollback pattern, the ChangeNotifier proxy provider chain, the dual-platform database layer — these show awareness of state management complexity beyond "call setState."

4. **Shipping discipline**: Five phases completed with a working CI/CD pipeline, a deployed web version, and 53 unit tests with a manual mock framework. The test suite covers service logic systematically (happy paths, error cases, cancellation, progress tracking, edge cases like empty lists and duplicate detection).

5. **Ability to manage scope**: The PRD explicitly scopes out in-app playback, metadata queries, smart playlists, social features, and desktop versions. The roadmap is phased. The dead code (unused helpers, abandoned factory pattern) shows iteration happened — approaches were tried and discarded rather than gold-plated.

> **[QUESTION FOR YOU]**: Are there specific engineering skills you want to highlight for the roles you're targeting? (e.g., system design, mobile development, API integration, state management, testing strategy). I can sharpen this section toward those.

---

## Demo-ability

**Estimate: 2–4 days to demo-ready.**

The core flow already works end-to-end: login → import → tag songs → build a query → see results → export. That's a compelling 3-minute demo as-is. What would make it impressive in an interview:

**Day 1 — Quick wins (high visual impact, low effort):**
- Add a brief onboarding overlay or coach marks explaining the concept (30 min)
- Add loading skeletons/shimmer effects to the library and query screens (1–2 hours)
- Clean up dead code (`DatabaseFactory`, unused helpers/constants) so the codebase is tight if they read it (30 min)

**Day 2 — Demo reliability:**
- Fix the batch rollback inconsistency so you can confidently explain your sync strategy (1–2 hours)
- Add the Tags screen search filter — it's the one missing feature someone would naturally try during a demo (1 hour)
- Pre-populate a Spotify account with diverse tagged songs so the demo has good data (1 hour)

**Day 3–4 — If aiming for "exceptional":**
- Add 5–10 widget tests to show testing discipline extends beyond services (2–3 hours)
- Add query engine unit tests — this is the most interesting piece of logic and having it tested shows rigor (2 hours)
- Write a brief architecture diagram (Mermaid or similar) to include in a presentation slide

**What to prepare regardless:**
- A Spotify account pre-loaded with ~100+ liked songs across different genres for a visually rich demo
- A scripted walkthrough: "I listen to a lot of music. Spotify has playlists, but I can't ask 'show me songs that are both chill AND jazz but NOT vocal.' Tagify adds that layer." → Import → Tag a few songs → Query → Export to queue → Play
- Be ready to talk about the tag-as-playlist storage decision, the optimistic UI pattern, and the query engine SQL — these are the most interview-worthy technical details

**Risk:** The web version resets on refresh, so demo on mobile (or don't refresh). If demoing on web, do the import and tagging right before the interview and don't close the tab.

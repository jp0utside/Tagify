# Tagify: Product Requirements Document

**Version:** 1.0  
**Last Updated:** October 21, 2025  
**Status:** MVP Development Planning

---

## Overview

**What:** A mobile app that adds a powerful tagging system to Spotify, enabling multi-dimensional organization and complex queries across your music library.

**Why:** I have over 1,000 songs in my Spotify library, and the playlist system is frustratingly rigid. I constantly find myself wanting to curate my music experience using several factors like artist, release date, and mood, but there's no way to do this without creating dozens of hyper-specific playlists or manually building queues every time. Playlists force me to either choose broad categories (like "upbeat") or focus in on hyper-specific situations (like "high energy final-stretch running music").

**The Solution:** Tag songs with multiple labels varying in complexity, from simple tags (like "workout," "high-energy," "90s," "grunge", etc.) to complex attribute tags (like "genre: jazz", "era added: high school", "release decade: 1970") and then query across those tags using boolean logic (AND, OR, NOT, etc.). This gives users the abilty to organize and query their library however they want, rather than just relying on either playlists or searching surface-level attributes like artist and album.

**Platform:** Native mobile app (iOS & Android) built with Flutter

---

## My Use Cases (Why This Solves Real Problems)

### Use Case 1: Multi-Dimensional Discovery
**Current Problem:** I want to find songs that are BOTH "chill" AND "instrumental" but NOT "classical." With playlists, I'd need to:
- Manually scan through either my "chill" or "instrumental" playlists, adding songs that fit the criteria to queue
- Or do the same thing but add all songs to a new playlist
- Or give up and just shuffle one of my existing playlists, hoping I get a lucky draw

**With Tagify:** 
- Tag songs once: a song gets "chill," "instrumental," "not classical" tags
- Query: `chill AND instrumental NOT classical`
- Instant results: 23 songs
- Save query as playlist or add to queue

### Use Case 2: Native playlist integration
**Current Problem:** I have 50+ hyper-specific playlists that I've created, but I'd like to shuffle a combination of them.

**With Tagify:**
- Import all your existing playlists from spotify, preserving the work you've already done
- Query all the playlists you want to include in the shuffle, (like "90s" AND "00s" AND "Grunge").
- Play freely without having to switch between or listen to repeats

### Use Case 3: Efficient Organization Over Time
**Current Problem:** Organizing music feels like an all-or-nothing project. Either spend hours building playlists upfront, or just like, shuffle, and forget.

**With Tagify:**
- Tag songs opportunistically (while listening, when bored, gradually over time)
- Each tag adds value immediately (can query with just a few tagged songs)
- No pressure to tag everything at once
- System gets more valuable as more songs are tagged

### Use Case 4: Accomodating shifting tastes
**Current Problem:** I have many large playlists I've created containing an artist I used to love, but I no longer want to hear music from them anymore.

**With Tagify:**
- Query those playlists while excluding that artist (`car music NOT artist:Taylor Swift`)
- Or use batching to query that artist and remove all instances of that tag

---

## Product Principles

1. **Start simple, stay fast** - Core features work perfectly before adding complexity
2. **Respect the user's time** - No forced upfront organization; value grows incrementally
3. **Spotify does playback, we do organization** - Don't rebuild what Spotify does well
4. **Your data stays yours** - Clear path to export/own your organizational work and preserve your library

---

## MVP Scope

### What's In (Must Have for First Version)

**Core Features:**
1. ✅ Spotify authentication (OAuth)
2. ✅ Import user's liked songs and existing playlists (read-only)
3. ✅ Create, rename, and delete tags (stored as playlists in "Tagify Tags" folder)
4. ✅ Add/remove tags on individual songs
5. ✅ Query builder with AND/OR/NOT logic (works with both tags and imported playlists)
6. ✅ Export query results:
   - Add to Spotify queue
   - Save as new tag (creates Spotify playlist in special folder)
   - Save as regular playlist
7. ✅ Sync tags to/from Spotify (bi-directional)
8. ✅ Local database for instant queries

**Platform:**
- Mobile-first (iOS and Android via Flutter)
- Native app experience
- Optimized for phone screen sizes

**Technical Approach:**
- Flutter for native mobile app
- Spotify Web API for all integration (no native SDK)
- SQLite for local storage/caching
- Tags stored as Spotify playlists in "Tagify Tags" folder
- Existing playlists imported as read-only entities for querying

### What's Out (Post-MVP)

**Explicitly NOT in first version:**
- ❌ Spotify metadata queries (BPM, energy, year, genre) - Future enhancement
- ❌ In-app playback - Users play in Spotify (deep linking)
- ❌ Custom attribute tags (ratings, numeric fields, categorical fields) - Too complex, would require separate database
- ❌ Smart playlists, tagging rules (auto-updating tags with new songs, live tags which rely on queries) - Nice-to-have later
- ❌ Collaborative tagging / social features - Not needed for personal use
- ❌ Desktop/web versions - Mobile-first, may add later
- ❌ Advanced query syntax (parentheses, nested logic) - Keep it simple
- ❌ Tag analytics / insights - Focus on core utility first

---

## Tags vs Playlists: Key Distinction

**Tags (Modifiable):**
- Created and managed by Tagify app
- Stored as playlists in "Tagify Tags" folder in Spotify
- Can be created, renamed, and deleted through the app
- Songs can be added/removed from tags
- Used for organization and querying
- Format: `#tag:tagname` in Spotify

**Playlists (Read-Only):**
- Existing playlists from user's Spotify account
- Imported as read-only entities for querying
- Cannot be modified through Tagify app
- Preserve user's existing organizational work
- Available for querying alongside tags
- Remain in their original locations in Spotify

**Query Integration:**
Both tags and playlists can be used in queries, but they serve different purposes:
- Tags: For flexible, multi-dimensional organization
- Playlists: For leveraging existing organizational work

---

## Technical Architecture

### MVP Architecture (Spotify as Source of Truth)

**Why This Approach:**
For MVP speed, I'm using Spotify playlists as my database for tags. Each tag becomes a playlist in a special "Tagify Tags" folder, while existing playlists are imported as read-only entities. This means:
- ✅ No separate backend to build/maintain
- ✅ Users' data lives in their Spotify account (no lock-in)
- ✅ Can ship faster and validate the concept
- ✅ Preserves existing playlist work while adding tagging functionality
- ✅ Clear separation between tags (modifiable) and playlists (read-only)

**Trade-offs:**
- ⚠️ Limited by Spotify's playlist constraints (10k songs per playlist, ~11k playlists per user)
- ⚠️ Sync complexity (need to keep local cache and Spotify in sync)
- ⚠️ Can't easily store metadata beyond tags (e.g., numeric ratings)

**Why It's Worth It:**
Speed to market matters more than perfect architecture for MVP. I can migrate to independent storage later if validation succeeds.

### System Components

**Mobile App (Flutter):**
- UI/UX layer
- Query execution engine (local)
- Spotify API client
- Sync orchestration

**Local Database (SQLite):**
- Tables: `songs`, `collections` (with type column for tags/playlists), `song_collections` (junction table)
- Purpose: Fast querying without API calls
- Cache of Spotify data, not source of truth

**Spotify (Backend Storage):**
- Tag playlists (in "Tagify Tags" folder, with prefix "#tag:")
- User's liked songs
- User's regular playlists
- Source of truth for all data

**Data Flow:**
```
User authenticates → Import playlists and liked songs from Spotify → Store in local SQLite DB
User creates tag → Update local SQLite → Create playlist in "Tagify Tags" folder
User tags song → Update local SQLite → API call to add song to tag playlist
User queries → Execute against local SQLite (instant results, includes both tags and playlists)
App launch → Fetch updates from Spotify → Sync local database (tags and playlists)
```

### Sync Strategy

**Rule:** Spotify is always the source of truth. When conflicts occur, Spotify wins.

**When Sync Happens:**
1. **On app launch** - Pull latest from Spotify
2. **After user actions** - Push changes to Spotify immediately
3. **Periodic background** - Every 15 minutes while app is open (detect external changes)
4. **Manual trigger** - User can force sync anytime

**What Gets Synced:**
- Tag playlists (create/rename/delete)
- Song additions/removals from tags
- Detection of external changes (user edited tag playlists directly in Spotify)
- Import of new/existing regular playlists (read-only sync)

**Conflict Resolution:**
If local cache differs from Spotify (e.g., user deleted a tag playlist in Spotify), local cache is updated to match Spotify. For regular playlists, external changes are detected and imported on sync. User is notified of significant changes.

---

## Feature Specifications

### 1. Authentication

**User Flow:**
1. Launch app → "Connect with Spotify" screen
2. Tap button → Spotify OAuth flow (web view)
3. User grants permissions → Redirected back to app
4. App stores access token → Proceeds to import

**Spotify Permissions Needed:**
- `user-library-read` - Read liked songs
- `playlist-read-private` - Read playlists
- `playlist-modify-private` - Create/edit tag playlists
- `playlist-modify-public` - Optional (if user wants public tags)
- `user-modify-playback-state` - Add to queue

**Technical Notes:**
- Use Authorization Code Flow with PKCE (secure for mobile)
- Store tokens in secure storage (Flutter Secure Storage)
- Implement automatic token refresh

---

### 2. Library Import

**User Flow:**
1. After auth → "Importing your library..." screen
2. Progress indicator: "Imported 234 / 1,000 songs..."
3. Import completes → Summary: "Imported 1,000 songs from 25 playlists"
4. Lands on main screen

**What Gets Imported:**
- All liked songs (via `/me/tracks`)
- All user playlists (via `/me/playlists`)
- Song metadata: ID, title, artist, album, duration, URI
- Stored in local SQLite for fast access

**Technical Considerations:**
- Batch API requests (respect 180 req/min rate limit)
- Show accurate progress (don't fake it)
- Handle large libraries (5k+ songs)
- Resumable if app crashes mid-import

**Edge Cases:**
- User has 0 liked songs → Show empty state, encourage exploring spotify for new music
- API error during import → Retry logic, show error message
- Import interrupted → Resume from last successful batch

---

### 3. Tag Management

**Create Tag:**
- From tags screen, tap "+" button → Text input: "Tag name"
- Creates tag locally + creates playlist in Spotify "Tagify Tags" folder
- Playlist name format: `#tag:tagname`
- Playlist description: "Created by Tagify - [timestamp]"

**View Tags:**
- Bottom nav "Tags" tab shows all tags with song counts
- Example: "workout (47)", "chill (123)", "indie (89)"
- Tap tag → View all songs with that tag

**Rename Tag:**
- From tags screen, press dots symbol to the right of desired tag → select "Rename" option
- Updates tag name locally and renames Spotify playlist
- Validation: no duplicate names, max 95 characters

**Delete Tag:**
- Press dots symbol on tag → select "Delete" option
- Confirmation dialog: "This will remove the tag and delete the Spotify playlist. The songs won't be deleted."
- Removes tag from local database + deletes Spotify playlist

**Tag Naming Rules:**
- Max 95 characters (Spotify limit - tag prefix)
- No duplicates (case-insensitive check)
- Support spaces and special characters

---

### 4. Tagging Songs

**Tag Assignment Flow:**
1. From library view → Tap song
2. Song detail screen shows current tags (chips)
3. Tap "Add Tag" → Tag selector with search and autocomplete
4. Select existing tag OR create new tag
5. Tag applied → Song appears in tag's Spotify playlist

**Batch Tagging**
1. From library view → Select edit
2. Library view shifts to select mode
3. Select songs to include
4. Select actions → Add to Tag
5. Select desired tag to apply to all selected songs

**Multiple Tags:**
- Songs can have unlimited tags
- Each tag = song appears in that playlist
- Tag chips shown on song rows for quick visibility

**Remove Tag:**
- Song detail → Tap X on tag chip
- Confirmation (optional) → Tag removed
- Song removed from corresponding Spotify playlist

**UI Patterns:**
- Tag selector with autocomplete (suggests existing tags as you type)
- Tag chips color-coded for visual distinction
- "Create new tag" option in selector if no matches

**Technical Notes:**
- Optimistic UI update (show tag immediately)
- Background API call: `POST /playlists/{playlist_id}/tracks`
- If API fails, rollback UI change and show error
- Batch operations when adding same tag to multiple songs
- Existing playlists are imported as read-only entities for querying
- Playlists cannot be modified by the app (no adding/removing songs)
- Only tags can be modified and assigned to songs

---

### 5. Query Builder

**Query Interface (Simplified for MVP):**
```
┌─────────────────────────────────────┐
│ Include songs with ALL of these:   │
│ [workout] [high-energy] [+]         │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ OR include songs with ANY of these: │
│ [indie] [rock] [+]                  │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ But NOT songs with:                 │
│ [sad] [slow] [+]                    │
└─────────────────────────────────────┘

Results: 42 songs
[Show Results]
```

**How It Works:**
- Three sections: AND, OR, NOT
- Each section has tag chips (can add multiple)
- Query executes locally against SQLite (instant)
- Results update as you modify query

**Query Logic:**
- **AND section:** Song must have ALL these tags
- **OR section:** Song must have AT LEAST ONE of these tags
- **NOT section:** Song must NOT have any of these tags
- Sections combine: `(AND tags) OR (OR tags) MINUS (NOT tags)`

**Example Queries:**
- "Workout songs that are energetic but not aggressive"
  - AND: `workout, high-energy`
  - NOT: `aggressive, intense`
- "Chill music for focus (instrumental or ambient, not classical)"
  - AND: `chill, focus`
  - OR: `instrumental, ambient`
  - NOT: `classical`

**Query Execution:**
- Runs against local SQLite (no API call)
- Algorithm: Set operations (intersection, union, difference)
- Target: <500ms for 10,000 song library
- Show result count before displaying list

**Empty Results:**
- Message: "No songs match your query. Try different tags or tag more songs."
- Suggestions: Remove NOT tags, broaden OR section

---

### 6. Export & Playback

**Export Options (from query results):**

**1. Add to Queue**
- Button: "Add to Queue"
- Adds all result songs to Spotify queue via API
- Progress indicator: "Adding 42 songs... (15/42)"
- Completion: "Added to Spotify queue. Open Spotify to play."
- Technical: `POST /me/player/queue` (one song at a time, rate limited)

**2. Save as Tag**
- Button: "Save as New Tag"
- Prompts: "Tag name?"
- Creates new tag + Spotify playlist
- All result songs get this new tag
- Use case: "I run this query often, let me save it"

**3. Save as Playlist**
- Button: "Save as Playlist"
- Prompts: "Playlist name?"
- Creates regular Spotify playlist (NOT in Tagify Tags folder)
- Songs added to playlist, and playlist is added to tagify
- Use case: "This is a listening collection, not for organizing"

**Playback Approach:**
- **No in-app playback** - Tagify is for organization, Spotify is for playing
- After adding to queue, user switches to Spotify app (standard mobile behavior)
- Deep linking option: "Open in Spotify" button (launches Spotify app)

**Why No In-App Playback:**
- Spotify already has perfect playback experience
- Native SDK integration is complex and maintenance-heavy
- Keeps Tagify focused on its core value: discovery and organization
- Users are comfortable switching apps for playback

---

### 7. Main UI/Navigation

**Screen Structure:**

**Home Screen (Library View):**
- Search bar at top
- List of all imported songs (scrollable)
- Each song row shows:
  - Album art thumbnail
  - Title + Artist
  - Tag chips (first 3, "+2 more" if >3)
- Tap song → Song detail screen
- Bottom nav: Library | Query | Tags | Settings

**Tags Screen:**
- List of all tags with song counts
- Example: 
  ```
  workout (47 songs)
  chill (123 songs)
  indie (89 songs)
  ```
- Tap tag → View all songs with that tag
- "+" FAB to create new tag

**Query Screen:**
- Query builder interface (as described above)
- Results section below query builder
- Export buttons when results exist

**Song Detail Screen:**
- Large album art
- Song title, runtime, artist, album
- Current tags (chips)
- "Add Tag" button
- "Open in Spotify" button (deep link)

**Settings Screen:**
- Spotify account info (display name, email)
- Sync status: "Last synced: 2 minutes ago"
- "Sync Now" button
- "Disconnect Account" button
- About: version, documentation, feedback

**Navigation Pattern:**
- Bottom navigation bar (iOS: tab bar, Android: bottom nav)
- Standard mobile navigation patterns
- Back gestures work as expected

---

## Technical Constraints & Risks

### Spotify API Constraints

**Rate Limits:**
- 180 requests per minute per user
- Impact: Large imports and exports need batching
- Mitigation: Request queue, progress indicators, efficient batching

**Playlist Limits:**
- 10,000 songs per playlist (tag)
- ~11,000 playlists per user total
- Impact: Heavy taggers could hit limits, but would require serious use
- Mitigation: Warn users approaching limits, suggest tag consolidation

**API Response Time:**
- 200-500ms average per request
- Impact: User actions have noticeable latency
- Mitigation: Optimistic UI updates, local caching for speed

### Key Risks

**Risk 1: Spotify Changes API or ToS**
- Probability: Low-Medium
- Impact: High (could break app)
- Mitigation: Stay updated on API changes, have export functionality, join developer community

**Risk 2: Sync Reliability**
- Probability: Medium (network issues, API failures)
- Impact: Medium (user frustration, data inconsistency)
- Mitigation: Robust error handling, retry logic, clear sync status, Spotify as source of truth

**Risk 3: Performance with Large Libraries**
- Probability: Low (if users have 10k+ songs)
- Impact: High (slow queries, janky UI)
- Mitigation: Optimize SQLite queries, use indexes, pagination for song lists, performance testing, proper noticing of limitations up-front

**Risk 4: Product-Market Fit**
- Probability: Low (solutions have been already attempted)
- Impact: Medium (low public usage)
- Mitigation: Start with personal use, validate it solves MY problem first, then share with friends

---

## MVP vs. Long-Term Vision

### MVP Reality (What I'm Building First)

**Architecture:**
- Spotify playlists as storage (fast, simple, no backend)
- Mobile-only (Flutter iOS/Android)
- Web API only (no native SDK complexity)
- Simple query logic (AND/OR/NOT)

**Philosophy:**
- Validate the concept quickly
- Prove tagging + querying solves the problem
- Get something working in 4-6 weeks
- Accept technical limitations for speed

### Long-Term Vision (Where This Could Go)

**Independent Database:**
- Own storage layer (not dependent on Spotify playlists)
- Store richer metadata (ratings, custom attributes, notes)
- Support larger tag systems (no playlist limit constraints)
- Offer other export options, creating persistent data storage outside of spotify (additional feature)

**Advanced Features:**
- Spotify metadata queries (BPM, energy, year, genre)
- Custom user attributes (5-star ratings, numeric scales)
- Smart playlists (auto-updating based on queries)
- LLM integration for predictive tagging and natural language queries ("upbeat songs I haven't heard in a while")

**Platform Expansion:**
- Desktop app (larger screen, keyboard shortcuts)
- Web version (access from any device)
- Cross-platform library management

**Social/Collaborative:**
- Share tag systems with friends
- Community tag exploration
- Collaborative tagging

**Multi-Service:**
- Apple Music support
- YouTube Music support
- Universal music library management

### Why Separate MVP from Vision

**For Development:**
- Focus on core value proposition first
- Don't get distracted by "nice-to-haves"
- Get standard functionality working reliably
- Validate with real usage and re-evaluate needs before expanding
- Architecture can evolve as needs clarify

---

## Development Plan

### Phase 1: Core Infrastructure (Week 1)

**Goals:**
- Spotify OAuth working
- Can fetch and display user's library
- Local SQLite database set up
- Basic navigation structure

**Deliverables:**
- User can log in with Spotify
- Library screen shows all songs
- Data persists locally

### Phase 2: Tagging System (Week 1-2)

**Goals:**
- Create/delete tags (locally + Spotify)
- Add/remove tags on songs
- Tag sync to Spotify working
- View songs by tag

**Deliverables:**
- User can create tags
- User can tag songs
- Tags appear as playlists in Spotify
- Tag list shows song counts

### Phase 3: Query Builder (Week 2-3)

**Goals:**
- Query UI with AND/OR/NOT
- Query execution against local DB
- Results display
- Performance optimization

**Deliverables:**
- User can build queries
- Results display instantly
- Query logic works correctly
- Handles large result sets

### Phase 4: Export & Polish (Week 4-5)

**Goals:**
- Add to queue functionality
- Save as tag/playlist
- Batch handling of song tagging/removing
- Deep linking to Spotify
- Error handling polish
- Loading states

**Deliverables:**
- All export options work
- Smooth user experience
- Clear error messages
- Professional polish

### Phase 5: Testing & Refinement (Week 5-6)

**Goals:**
- Test with real usage patterns
- Fix bugs and edge cases
- Optimize performance
- Prepare for TestFlight/internal testing

**Deliverables:**
- Stable app ready for personal use
- No critical bugs
- Acceptable performance
- Ready to share with friends

---

## Open Questions & Decisions

### Product Decisions Still Needed

**Q1: Should I support batch tagging in MVP?**
- Pro: More efficient for organizing
- Con: More complex UI, delays MVP
- Current decision: Yes, could prove trivially useful

**Q2: What happens if user manually deletes tag playlists in Spotify?**
- Option A: Recreate on next sync (confusing)
- Option B: Detect and remove tag from Tagify (my preference)
- Current decision: Option B, notify user of changes, make clear in instructions Spotify is single source of truth

**Q3: Should tags be private or public playlists?**
- Current decision: Private by default, user can manually change in Spotify if desired

**Q4: How much of the library should I import?**
- Current decision: Liked songs + all playlists (comprehensive)
- Alternative: Liked songs only (simpler, but inconsistent)

### Technical Decisions Still Needed

**Q5: SQLite schema optimization?**
- Need to test query performance with 10k+ songs
- May need indexes on junction table
- Decide during development based on profiling

**Q6: How to handle offline mode?**
- MVP: Require internet connection (simpler)
- Future: Allow queries offline, queue syncs for when online

**Q7: Error handling strategy?**
- Show user-friendly errors with retry options
- Log detailed errors for debugging
- Need to decide: Sentry or similar for error tracking?

---

## Appendix

### Flutter Learning Resources

**Official Resources:**
- Flutter.dev tutorials and codelabs
- Dart language tour
- Flutter widget catalog

**Key Packages I'll Need:**
- `http` - Spotify API calls
- `sqflite` - Local database
- `flutter_secure_storage` - Token storage
- `url_launcher` - Deep linking to Spotify
- `provider` or `riverpod` - State management

### Spotify API Endpoints Used

**Authentication:**
- Authorization Code Flow with PKCE

**Library Management:**
- `GET /me/tracks` - Get liked songs
- `GET /me/playlists` - Get playlists
- `GET /playlists/{id}/tracks` - Get playlist tracks

**Playlist Operations:**
- `POST /users/{id}/playlists` - Create playlist
- `PUT /playlists/{id}` - Update playlist (rename)
- `DELETE /playlists/{id}/followers` - Delete playlist
- `POST /playlists/{id}/tracks` - Add songs
- `DELETE /playlists/{id}/tracks` - Remove songs

**Playback:**
- `POST /me/player/queue` - Add to queue

---

*This PRD is a living document and will be updated as development progresses and learnings emerge.*

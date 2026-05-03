# Baraj İzmir — Project Context

## What This App Does

Real-time dam water level tracker for İzmir, Turkey. Fetches data from the İzmir Metropolitan Municipality Open API (`https://openapi.izmir.bel.tr/api/izsu/barajdurum`) and displays fill rates, water volumes, and water levels for all İzmir barrages.

**Target audience:** İzmir residents who want to monitor the city's water supply status.

## Architecture

**Language/Framework:** Swift + SwiftUI, iOS 17+ target  
**Pattern:** MVVM with Actor-based service layer  
**State management:** `@Published` + `@MainActor` ViewModel, no third-party state library  

### Targets

| Target | Purpose |
|--------|---------|
| `Barajizmir` | Main app |
| `BarajizmirWidget` | Home screen widget (WidgetKit) |
| `BarajizmirIntents` | Siri App Shortcuts (App Intents) |

### Key Files

```
Barajizmir/
├── Models/Barrage.swift                   — Core data model (Codable, Hashable, maps Turkish API fields)
│                                            Includes enlem/boylam → CLLocationCoordinate2D computed property
├── Models/NotificationThreshold.swift     — Codable model: barrageId, barajAdi, threshold, isEnabled
├── Services/BarrageService.swift          — Actor-based data fetcher + cache (App Group)
│                                            fetchFreshFromAPI() returns nil on failure (no throw)
├── Services/MotionManager.swift           — CoreMotion: gravity tilt + shake detection
├── Services/ReviewManager.swift           — StoreKit2 review prompt logic
├── Services/NotificationManager.swift     — Threshold CRUD (UserDefaults), checkThresholds(), sendNotification()
│                                            notifiedIds tracking prevents duplicate alerts
├── Services/BackgroundRefreshManager.swift — BGAppRefreshTask: registers handler, schedules ~1hr refresh
│                                             on fire: fetchFreshFromAPI → checkThresholds → reschedule
├── ViewModels/BarrageViewModel.swift      — Cache-first init (UserDefaults instant load), fetchFreshFromAPI
│                                            calls WidgetCenter.reloadAllTimelines() + checkThresholds() on success
├── Views/HomeView.swift                   — Root view: full-screen MapKit map + persistent bottom sheet
│                                            Sheet detents: [.height(240), .medium] on list, adds .large on detail
│                                            Camera constrained to İzmir bounds via onMapCameraChange
├── Views/BarragePinView.swift             — Custom map annotation: colored circle pin + triangle pointer
│                                            Colors: <30% red, 30-60% orange, 60-80% yellow, ≥80% green
├── Views/BarrageListView.swift            — Bottom sheet content: sorted list + pull-to-refresh
│                                            Takes viewModel + onSelect callback (no NavigationStack inside)
├── Views/BarrageDetailView.swift          — Detail: water wave → staleness warning → data table → chart → notification
├── Views/BarrageHistoryChartView.swift    — Swift Charts: area+line chart, 1H/1A/6A picker, drag annotation
│                                            Default range: .week. Calls SupabaseService.fetchHistory (cached 1h)
├── Views/BarrageNotificationSection.swift — Toggle + threshold slider (10-90%), permission handling,
│                                            contextual description (warns if already below threshold)
├── Views/BarrageProfileCard.swift         — Static dam profile card (unused in views — ready for future placement)
├── Views/AboutView.swift                  — App info, data attribution, Siri guide
├── Views/WaterWave.swift                  — Custom animatable Shape (sine wave + gravity tilt)
├── Views/WaterBubbles.swift               — Bubble particle system (shake-triggered burst)
├── Models/ChartRange.swift                — Sendable enum: .week/.month/.sixMonth, xLabel/stride helpers
│                                            granularity + stepDays removed (no longer needed after RPC→table switch)
├── Models/BarrageStaticProfile.swift      — Static profile data per dam (buildYear, damType, watershed, purpose)
│                                            Keyed by lowercased partial name. find(for:) does substring match.
├── Shared/SharedDataManager.swift         — App Group bridge (app ↔ widget data sharing)
│                                            loadCachedBarrages() inferred @MainActor — call via await MainActor.run{}
│                                            from async non-MainActor contexts (BarrageQuery, WidgetTimeline)
└── Extensions/NumberFormatter+Extensions.swift — Turkish locale number/date formatting

BarajizmirWidget/
├── BarrageWidget.swift                    — AppIntentConfiguration, systemSmall only
├── BarrageWidgetTimeline.swift            — Timeline provider, 24h refresh, Supabase direct fetch
│                                            getEntry() takes pre-fetched cachedResult param (no double fetch)
│                                            .stale state: shows last-known data with yellow ! badge
└── BarrageWidgetView.swift                — Widget UI (5 states: loaded/loading/error/noSelection/stale)

BarajizmirIntents/
├── BarrageFillRateIntent.swift            — Siri intent: reads top 6 dams aloud (no app open)
├── BarrageSelectionIntent.swift           — Widget config intent + BarrageEntity + BarrageQuery
└── BarajizmirAppShortcuts.swift           — 41 Siri voice phrases (Turkish)
```

### Data Flow

```
GitHub Actions (saatlik cron)
  → İzmir API (openapi.izmir.bel.tr)
  → Supabase (barrage_snapshots tablosu)

iOS App / BGAppRefreshTask
  → SupabaseService.fetchLatest()  (latest_barrage_snapshots view)
  → BarrageService.cache()  (App Group UserDefaults)
  → BarrageViewModel (@MainActor) → SwiftUI Views
  → WidgetCenter.reloadAllTimelines()
  → NotificationManager.checkThresholds()

BarrageWidgetTimeline → App Group cache → Widget
BarrageFillRateIntent → App Group cache → Siri response
```

### Caching Strategy

- **Barrage list:** `UserDefaults` via App Group `group.onatcakir.Barajizmir`. `BarrageViewModel.init()` loads synchronously → instant display, then fetches fresh in background.
- **Widget:** refreshes every 24h; fetches Supabase directly (no longer depends on app opening)
- **History chart:** in-memory cache inside `SupabaseService` actor, keyed `"{barrageId}_{range}"`, TTL 1 hour. Second visit to same baraj+range hits cache, no network call.
- **Siri intent:** uses App Group cache, fetches fresh if >12 hours old

## Native iOS Features In Use

| Feature | Where |
|---------|-------|
| CoreMotion (gravity + shake) | `MotionManager`, `BarrageDetailView`, `WaterWave` |
| WidgetKit + AppIntentConfiguration | `BarajizmirWidget` target |
| App Intents + Siri Shortcuts | `BarajizmirIntents` target |
| StoreKit2 review prompt | `ReviewManager` |
| UIActivityViewController share sheet | `BarrageDetailView` |
| App Groups (cross-target data) | `BarrageService`, `SharedDataManager` |
| MapKit (SwiftUI Map API) | `HomeView`, `BarragePinView` |
| UserNotifications (local) | `NotificationManager`, `BarrageNotificationSection` |
| BGAppRefreshTask | `BackgroundRefreshManager` |
| Swift Charts | `BarrageHistoryChartView` — area+line, drag annotation, 1H/1A/6A |

## Notification System

User picks a fill-rate threshold per dam in `BarrageDetailView` → `BarrageNotificationSection`.

**Threshold storage:** `UserDefaults` (standard, not App Group) under key `notification_thresholds` as `[Int: NotificationThreshold]` JSON.

**Trigger logic** (`NotificationManager.checkThresholds`):
- Fires when `dolulukOrani <= threshold` AND barrage not already in `notified_barrage_ids`
- Resets notified state when fill rate rises back above threshold (so next drop triggers again)

**Background delivery** (`BackgroundRefreshManager`):
- BGAppRefreshTask identifier: `onatcakir.Barajizmir.refresh`
- Scheduled with `earliestBeginDate` of 1 hour; iOS fires it based on usage patterns
- **Xcode setup required:** Signing & Capabilities → Background Modes → Background fetch ✓
- **Info.plist required:** `BGTaskSchedulerPermittedIdentifiers` Array → Item 0 (String): `onatcakir.Barajizmir.refresh`

## Home Screen Layout

`HomeView` is the root view:
- Full-screen `Map` behind everything (`.ignoresSafeArea()`)
- Persistent bottom sheet via `.sheet(isPresented: .constant(true))`
- Sheet uses **iOS 26 default Liquid Glass** background — do NOT add `.presentationBackground(.regularMaterial)`, it kills the effect
- Sheet has `NavigationStack` inside; `BarrageDetailView` pushed via `navigationDestination`
- **Sheet detents:** `[.height(240), .medium]` on list — user cannot drag to full screen
- **On navigate to detail:** `.large` detent added programmatically, sheet expands to full
- **On navigate back:** detents revert to `[.height(240), .medium]`, sheet collapses to `.medium`
- Camera constrained to İzmir bounds (`minLat: 37.9`, `maxLat: 39.4`, `minLon: 26.2`, `maxLon: 28.5`)
- Coordinates come from API (`Enlem`/`Boylam` fields) — no static lookup needed
- **List rows:** `.contentShape(Rectangle())` on `BarrageRowView` — required so tapping whitespace also navigates

## App Store Status

**2x Rejected under Guideline 4.2 / 4.2.2 (Minimum Functionality)**

Apple's position: the app is a content aggregator with limited native functionality. Despite the widget, Siri integration, and CoreMotion animations, reviewers concluded the experience is not sufficiently "app-like."

### Root Cause

The app's core loop was: **open → see a list → tap for detail → close.** Nothing for the user to *do*.

### Features Added to Address Rejection

- ✅ **MapKit view** — Full-screen map with color-coded pins, camera constrained to İzmir
- ✅ **Threshold notifications** — User sets per-dam alert threshold, background delivery via BGAppRefreshTask

## Barrage Data Model

```swift
struct Barrage: Codable, Identifiable, Hashable {
    let id: Int
    let barajAdi: String           // Dam name
    let dolulukOrani: Double       // Fill rate %
    let hacim: Double?             // Max capacity (m³)
    let mevcutSuDurumu: Double?    // Current volume (m³)
    let suSeviyesi: Double?        // Water level (m)
    let maksimumSuYuksekligi: Double?
    let minimumSuYuksekligi: Double?
    let guncellemeTarihi: String?  // ISO date string
    let enlem: String?             // CodingKey: "Enlem"
    let boylam: String?            // CodingKey: "Boylam"
    // computed: var coordinate: CLLocationCoordinate2D?
}
```

## Color Coding

| Fill Rate | Color | Used in |
|-----------|-------|---------|
| < 30% | Red | App, Widget, Map pins |
| 30–60% | Orange | App, Widget, Map pins |
| 60–80% | Yellow/Gold | App, Widget, Map pins |
| ≥ 80% | Green | App, Widget, Map pins |

Note: Main app notification slider uses slightly different thresholds (30/60) vs widget (30/60/80). Should be unified into a shared constant.

## Localization

- App is Turkish-only
- Number formatting: dots as thousands separator (`1.234.567`)
- Date formatting: `d MMMM yyyy` Turkish locale
- API field names are Turkish (CodingKeys handle mapping)

## Swift 6 / SWIFT_APPROACHABLE_CONCURRENCY Notes

Project has `SWIFT_APPROACHABLE_CONCURRENCY = YES`. Key patterns to maintain:

- **`SharedDataManager.loadCachedBarrages()`** — inferred `@MainActor`. Call via `await MainActor.run { SharedDataManager.loadCachedBarrages() }` from any async non-MainActor context (BarrageQuery, WidgetTimeline).
- **`MotionManager`** CMDeviceMotion handler — wrap body in `MainActor.assumeIsolated { }` since closure runs on `.main` queue but compiler can't prove it statically.
- **`BackgroundRefreshManager`** — marked `@unchecked Sendable`; use `[weak self]` in BGTaskScheduler register closure.
- **`SupabaseService.BarrageSnapshot`** — use `func makeBarrage()` not `var barrage: Barrage` to avoid `@MainActor` inference on computed properties returning `Barrage`.

## Known Issues / TODOs

- `ContentView.swift` is unused — can be removed
- Widget supports only `systemSmall`; `.systemMedium` and lock screen families not implemented
- Color thresholds differ between notification slider and widget — should be centralized

## Known Bugs

### Bug 1 — Widget reverts to "Baraj Seçin" when a barrage disappears from API
**Status:** Fixed — Added `.stale` WidgetState + per-barrage last-known cache (keyed `last_known_barrage_{id}` in App Group UserDefaults). Shows stale data with yellow `!` badge instead of reverting to `.noSelection`.

### Bug 2 — Widget shows stale data after app pull-to-refresh
**Status:** Fixed — `WidgetCenter.shared.reloadAllTimelines()` called in `BarrageViewModel.fetchFreshFromAPI()` after every successful fetch.

---

## Roadmap

### Immediate — Bug Fixes
- [x] **Bug 2 fix:** `WidgetCenter.reloadAllTimelines()` in `BarrageViewModel` after successful fetch
- [x] **Bug 1 fix:** Widget graceful degradation — show last known data with "eski veri" label

### Short Term — App Store Rejection Fix (Guideline 4.2 / 4.2.2)
- [x] **MapKit view** — Full-screen map with color-coded pins, İzmir camera bounds
- [x] **Threshold notifications** — Per-dam alert threshold + BGAppRefreshTask background delivery
- [ ] **Dam profile pages** — Static content per dam: location, construction year, watershed, historical capacity context

### Medium Term — Depth & Differentiation
- [x] **Backend (Supabase)** — GitHub Actions günlük cron → barrage_snapshots tablosu. iOS app artık direkt Supabase'den besleniyor.
- [x] **Swift Charts historical trend** — Hafta/ay/6ay doluluk grafiği. Direkt tablo sorgusu (RPC yok). 1h cache. Default 1 Hafta.
- [ ] **Medium widget + lock screen widget** — `.systemMedium`, `accessoryRectangular`, `accessoryCircular`

### Later — Polish
- [ ] **Favorites** — Pin dams to top of list, `UserDefaults` persistence
- [ ] **Unify color thresholds** — Centralize into a shared constant across app + widget
- [ ] **Remove `ContentView.swift`** — Unused file
- [ ] **Comparison view** — Side-by-side fill rate for multiple dams

## Development Notes

- Xcode project; no SPM external dependencies
- Build runs on iOS 17+ (App Intents API requirement)
- App Group identifier: `group.onatcakir.Barajizmir`
- BGTask identifier: `onatcakir.Barajizmir.refresh`
- Privacy policy hosted on GitHub Pages

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
├── Models/Barrage.swift                 — Core data model (Codable, maps Turkish API fields)
├── Services/BarrageService.swift        — Actor-based data fetcher + cache (App Group)
├── Services/MotionManager.swift         — CoreMotion: gravity tilt + shake detection
├── Services/ReviewManager.swift         — StoreKit2 review prompt logic
├── ViewModels/BarrageViewModel.swift    — Main state holder
├── Views/BarrageListView.swift          — Home screen: sorted list + pull-to-refresh
├── Views/BarrageDetailView.swift        — Detail: water wave animation + data table + share
├── Views/AboutView.swift                — App info, data attribution, Siri guide
├── Views/WaterWave.swift                — Custom animatable Shape (sine wave + gravity tilt)
├── Views/WaterBubbles.swift             — Bubble particle system (shake-triggered burst)
├── Shared/SharedDataManager.swift       — App Group bridge (app ↔ widget data sharing)
└── Extensions/NumberFormatter+Extensions.swift — Turkish locale number/date formatting

BarajizmirWidget/
├── BarrageWidget.swift                  — AppIntentConfiguration, systemSmall only
├── BarrageWidgetTimeline.swift          — Timeline provider, 12-hour refresh, cache fallback
└── BarrageWidgetView.swift              — Widget UI (4 states: loaded/loading/error/noSelection)

BarajizmirIntents/
├── BarrageFillRateIntent.swift          — Siri intent: reads top 6 dams aloud (no app open)
├── BarrageSelectionIntent.swift         — Widget config intent + BarrageEntity + BarrageQuery
└── BarajizmirAppShortcuts.swift         — 41 Siri voice phrases (Turkish)
```

### Data Flow

```
API (izmir.bel.tr) → BarrageService (actor) → UserDefaults (App Group cache)
                                             ↓
                              BarrageViewModel (@MainActor) → SwiftUI Views
                                             ↓
                              BarrageWidgetTimeline → Widget
                              BarrageFillRateIntent → Siri response
```

### Caching Strategy

- Stored in `UserDefaults` via App Group `group.onatcakir.Barajizmir`
- Widget refreshes every 12 hours; falls back to cache on network failure
- Siri intent also uses this cache, fetches fresh if >12 hours old

## Native iOS Features In Use

| Feature | Where |
|---------|-------|
| CoreMotion (gravity + shake) | `MotionManager`, `BarrageDetailView`, `WaterWave` |
| WidgetKit + AppIntentConfiguration | `BarajizmirWidget` target |
| App Intents + Siri Shortcuts | `BarajizmirIntents` target |
| StoreKit2 review prompt | `ReviewManager` |
| UIActivityViewController share sheet | `BarrageDetailView` |
| App Groups (cross-target data) | `BarrageService`, `SharedDataManager` |
| Swift Charts | ❌ Not yet implemented |
| MapKit | ❌ Not yet implemented |
| UserNotifications | ❌ Not yet implemented |

## App Store Status

**2x Rejected under Guideline 4.2 / 4.2.2 (Minimum Functionality)**

Apple's position: the app is a content aggregator with limited native functionality. Despite the widget, Siri integration, and CoreMotion animations, reviewers concluded the experience is not sufficiently "app-like."

### Root Cause

The app's core loop is: **open → see a list → tap for detail → close.** There is nothing for the user to *do*. Apple's 4.2 standard requires apps to offer compelling capabilities or enable users to do something they couldn't do before.

### Planned Features to Address Rejection

See the "Roadmap" section below.

## Barrage Data Model

```swift
struct Barrage: Codable, Identifiable {
    let id: Int
    let barajAdi: String           // Dam name
    let dolulukOrani: Double       // Fill rate %
    let hacim: Double?             // Max capacity (m³)
    let mevcutSuDurumu: Double?    // Current volume (m³)
    let suSeviyesi: Double?        // Water level (m)
    let maksimumSuYuksekligi: Double?
    let minimumSuYuksekligi: Double?
    let guncellemeTarihi: String?  // ISO date string
}
```

## Color Coding (Consistent Across App + Widget)

| Fill Rate | Color |
|-----------|-------|
| < 30% | Red |
| 30–60% | Orange |
| 60–80% | Yellow |
| ≥ 80% | Green |

Note: Main app uses slightly different thresholds (40%/70%) vs widget (30%/60%/80%). Should be unified.

## Localization

- App is Turkish-only
- Number formatting: dots as thousands separator (`1.234.567`)
- Date formatting: `d MMMM yyyy` Turkish locale
- API field names are Turkish (CodingKeys handle mapping)

## Known Issues / TODOs

- `ContentView.swift` is unused (just delegates to `BarrageListView`) — can be removed
- Widget supports only `systemSmall`; `.systemMedium` and lock screen families not implemented
- Color thresholds differ between app and widget (should be centralized)
- No historical tracking — app has no persistent store beyond the cache

## Known Bugs

### Bug 1 — Widget reverts to "Baraj Seçin" when a barrage disappears from API
**Root cause:** `BarrageWidgetTimeline` calls `SharedDataManager.getBarrage(byId:)` → returns `nil` because the barrage ID is no longer in cache → widget falls into `.noSelection` state.  
**Fix:** When selected barrage is missing from latest fetch, keep last known `Barrage` data in widget entry and show it with a staleness indicator. Never drop to `.noSelection` unless the user has never selected a barrage.  
**Status:** Fixed — Added `.stale` WidgetState + per-barrage last-known cache (keyed `last_known_barrage_{id}` in App Group UserDefaults). `getEntry(for:)` saves on hit, falls back to last-known on miss, shows stale data with yellow `!` badge in widget view.

### Bug 2 — Widget shows stale data after app pull-to-refresh
**Root cause:** Widget timeline refreshes on its own 12-hour cycle. App refresh (`BarrageViewModel.loadBarrages`) updates the shared cache but never signals WidgetKit to reload.  
**Fix:** Call `WidgetCenter.reloadAllTimelines()` inside `BarrageViewModel` after a successful data fetch.  
**Status:** Fixed — `import WidgetKit` + `WidgetCenter.shared.reloadAllTimelines()` added to `BarrageViewModel.loadBarrages()` after successful fetch.

---

## Roadmap

### Immediate — Bug Fixes
- [x] **Bug 2 fix:** `WidgetCenter.reloadAllTimelines()` in `BarrageViewModel` after successful fetch
- [x] **Bug 1 fix:** Widget graceful degradation — show last known data with "eski veri" label instead of reverting to `.noSelection`

### Short Term — App Store Rejection Fix (Guideline 4.2 / 4.2.2)
Apple rejected twice: app seen as a content aggregator with no native actions. Need features where the user *does* something, not just views data.

- [ ] **Threshold notifications** — User picks a dam and a fill-rate threshold → `UserNotifications` alert when crossed. Strongest argument against 4.2 rejection (native action, personalization).
- [ ] **MapKit view** — Barajlar harita üzerinde renkli pinlerle. Tap → detail. Spatial experience, not replicable as a web page.
- [ ] **Dam profile pages** — Static content per dam: location, construction year, watershed, historical capacity context. Counters the "only aggregated internet content" charge (4.2.2).

### Medium Term — Depth & Differentiation
- [ ] **Backend (Supabase)** — Hourly snapshot of API data. Builds a proprietary historical dataset over time that web has no equivalent of.
- [ ] **Swift Charts historical trend** — Week/month fill rate trend per dam, powered by backend snapshots. Transforms app from snapshot viewer to analytics tool.
- [ ] **Medium widget + lock screen widget** — Expand `BarrageWidget` to `.systemMedium` and `WidgetFamily.accessoryRectangular` / `accessoryCircular` lock screen families.

### Later — Polish
- [ ] **Favorites** — Pin dams to top of list. `UserDefaults` persistence.
- [ ] **Unify color thresholds** — App uses 40%/70%, widget uses 30%/60%/80%. Centralize into a shared constant.
- [ ] **Remove `ContentView.swift`** — Unused file, just wraps `BarrageListView`.
- [ ] **Comparison view** — Side-by-side fill rate for multiple dams.

## Development Notes

- Xcode project; no SPM external dependencies
- Build runs on iOS 17+ (App Intents API requirement)
- App Group identifier: `group.onatcakir.Barajizmir`
- Privacy policy hosted on GitHub Pages

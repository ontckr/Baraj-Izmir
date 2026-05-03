import WidgetKit
import SwiftUI

struct BarrageWidgetEntry: TimelineEntry {
    let date: Date
    let barrage: Barrage?
    let lastUpdate: Date?
    let state: WidgetState
    
    enum WidgetState {
        case loaded
        case loading
        case error
        case noSelection
        case stale
    }
}

struct BarrageWidgetTimeline: AppIntentTimelineProvider {
    typealias Entry = BarrageWidgetEntry
    typealias Intent = BarrageSelectionIntent
    
    func placeholder(in context: Context) -> BarrageWidgetEntry {
        BarrageWidgetEntry(
            date: Date(),
            barrage: Barrage(
                id: 1,
                barajAdi: "Örnek Baraj",
                dolulukOrani: 75.5,
                hacim: nil,
                mevcutSuDurumu: nil,
                suSeviyesi: nil,
                maksimumSuYuksekligi: nil,
                minimumSuYuksekligi: nil,
                guncellemeTarihi: nil,
                enlem: nil,
                boylam: nil
            ),
            lastUpdate: Date(),
            state: .loaded
        )
    }
    
    func snapshot(for configuration: BarrageSelectionIntent, in context: Context) async -> BarrageWidgetEntry {
        let barrageId = configuration.barrage?.id
        return getEntry(for: barrageId)
    }
    
    func timeline(for configuration: BarrageSelectionIntent, in context: Context) async -> Timeline<BarrageWidgetEntry> {
        let barrageId = configuration.barrage?.id
        
        let cachedResult = SharedDataManager.loadCachedBarrages()
        let shouldFetchFromAPI: Bool
        
        if let lastUpdate = cachedResult?.lastUpdate {
            let dataAge = Date().timeIntervalSince(lastUpdate)
            shouldFetchFromAPI = dataAge > 43200
        } else {
            shouldFetchFromAPI = true
        }
        
        if shouldFetchFromAPI {
            await fetchAndCacheBarrages()
        }
        
        let entry = getEntry(for: barrageId)
        
        let nextUpdate = Date().addingTimeInterval(43200)
        
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private let appGroupIdentifier = "group.onatcakir.Barajizmir"

    private func lastKnownKey(for barrageId: Int) -> String {
        "last_known_barrage_\(barrageId)"
    }

    private func saveLastKnown(_ barrage: Barrage) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let encoded = try? JSONEncoder().encode(barrage) else { return }
        defaults.set(encoded, forKey: lastKnownKey(for: barrage.id))
    }

    private func loadLastKnown(for barrageId: Int) -> Barrage? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: lastKnownKey(for: barrageId)),
              let barrage = try? JSONDecoder().decode(Barrage.self, from: data) else { return nil }
        return barrage
    }

    private func fetchAndCacheBarrages() async {
        let apiURL = URL(string: "https://openapi.izmir.bel.tr/api/izsu/barajdurum")!
        let appGroupIdentifier = "group.onatcakir.Barajizmir"
        let cacheKey = "cached_barrages"
        let lastUpdateKey = "last_update_date"
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let barrages = try JSONDecoder().decode([Barrage].self, from: data)
            
            if let encoded = try? JSONEncoder().encode(barrages) {
                sharedDefaults.set(encoded, forKey: cacheKey)
                sharedDefaults.set(Date(), forKey: lastUpdateKey)
            }
        } catch {
            print("Widget: API fetch failed, using cached data")
        }
    }
    
    private func getEntry(for barrageId: String?) -> BarrageWidgetEntry {
        guard let result = SharedDataManager.loadCachedBarrages() else {
            return BarrageWidgetEntry(date: Date(), barrage: nil, lastUpdate: nil, state: .error)
        }

        guard let barrageIdString = barrageId,
              let barrageIdInt = Int(barrageIdString) else {
            return BarrageWidgetEntry(date: Date(), barrage: nil, lastUpdate: result.lastUpdate, state: .noSelection)
        }

        if let barrage = result.barrages.first(where: { $0.id == barrageIdInt }) {
            saveLastKnown(barrage)
            return BarrageWidgetEntry(date: Date(), barrage: barrage, lastUpdate: result.lastUpdate, state: .loaded)
        }

        if let lastKnown = loadLastKnown(for: barrageIdInt) {
            return BarrageWidgetEntry(date: Date(), barrage: lastKnown, lastUpdate: result.lastUpdate, state: .stale)
        }

        return BarrageWidgetEntry(date: Date(), barrage: nil, lastUpdate: result.lastUpdate, state: .error)
    }
}

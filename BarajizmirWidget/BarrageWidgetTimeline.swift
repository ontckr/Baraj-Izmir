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
        let cached = await MainActor.run { SharedDataManager.loadCachedBarrages() }
        return getEntry(for: barrageId, cachedResult: cached)
    }

    func timeline(for configuration: BarrageSelectionIntent, in context: Context) async -> Timeline<BarrageWidgetEntry> {
        let barrageId = configuration.barrage?.id

        let cachedResult = await MainActor.run { SharedDataManager.loadCachedBarrages() }

        if let lastUpdate = cachedResult?.lastUpdate {
            if Date().timeIntervalSince(lastUpdate) > 86400 {
                await fetchAndCacheBarrages()
            }
        } else {
            await fetchAndCacheBarrages()
        }

        let refreshedCache = await MainActor.run { SharedDataManager.loadCachedBarrages() }
        let entry = getEntry(for: barrageId, cachedResult: refreshedCache)
        let nextUpdate = Date().addingTimeInterval(86400)

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
        let supabaseURL = "https://tckwpqxptjfnffjvtfqb.supabase.co"
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRja3dwcXhwdGpmbmZmanZ0ZnFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MzI4MTEsImV4cCI6MjA5MzQwODgxMX0.4W1DQdxIag8zMpHqXpxqLOaRoimpzpOULJg_r1IOtXw"

        guard let url = URL(string: "\(supabaseURL)/rest/v1/latest_barrage_snapshots?select=*"),
              let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshots = try decoder.decode([WidgetBarrageSnapshot].self, from: data)
            let barrages = snapshots.map(\.barrage)

            if let encoded = try? JSONEncoder().encode(barrages) {
                sharedDefaults.set(encoded, forKey: "cached_barrages")
                sharedDefaults.set(Date(), forKey: "last_update_date")
            }
        } catch {
            // Cache'teki veriyi kullanmaya devam et
        }
    }

    private struct WidgetBarrageSnapshot: Decodable {
        let barrageId: Int
        let barajAdi: String
        let dolulukOrani: Double
        let hacim: Double?
        let mevcutSuDurumu: Double?
        let suSeviyesi: Double?
        let maksimumSuYuksekligi: Double?
        let minimumSuYuksekligi: Double?
        let guncellemeTarihi: String?
        let enlem: String?
        let boylam: String?

        enum CodingKeys: String, CodingKey {
            case barrageId            = "barrage_id"
            case barajAdi             = "baraj_adi"
            case dolulukOrani         = "doluluk_orani"
            case hacim
            case mevcutSuDurumu       = "mevcut_su_durumu"
            case suSeviyesi           = "su_seviyesi"
            case maksimumSuYuksekligi = "maksimum_su_yuksekligi"
            case minimumSuYuksekligi  = "minimum_su_yuksekligi"
            case guncellemeTarihi     = "guncelleme_tarihi"
            case enlem
            case boylam
        }

        var barrage: Barrage {
            Barrage(
                id: barrageId,
                barajAdi: barajAdi,
                dolulukOrani: dolulukOrani,
                hacim: hacim,
                mevcutSuDurumu: mevcutSuDurumu,
                suSeviyesi: suSeviyesi,
                maksimumSuYuksekligi: maksimumSuYuksekligi,
                minimumSuYuksekligi: minimumSuYuksekligi,
                guncellemeTarihi: guncellemeTarihi,
                enlem: enlem,
                boylam: boylam
            )
        }
    }
    
    private func getEntry(
        for barrageId: String?,
        cachedResult: (barrages: [Barrage], lastUpdate: Date)?
    ) -> BarrageWidgetEntry {
        guard let result = cachedResult else {
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

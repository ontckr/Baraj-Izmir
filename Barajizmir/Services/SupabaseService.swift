import Foundation

actor SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    // Supabase → Settings → API
    private let projectURL = "https://tckwpqxptjfnffjvtfqb.supabase.co"
    private let anonKey    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRja3dwcXhwdGpmbmZmanZ0ZnFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MzI4MTEsImV4cCI6MjA5MzQwODgxMX0.4W1DQdxIag8zMpHqXpxqLOaRoimpzpOULJg_r1IOtXw"

    private var headers: [String: String] {
        [
            "apikey": anonKey,
            "Authorization": "Bearer \(anonKey)",
            "Content-Type": "application/json"
        ]
    }

    // MARK: - Güncel durum (latest_barrage_snapshots view)

    func fetchLatest() async -> (barrages: [Barrage], lastUpdate: Date)? {
        guard let url = URL(string: "\(projectURL)/rest/v1/latest_barrage_snapshots?select=*") else { return nil }

        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshots = try decoder.decode([BarrageSnapshot].self, from: data)
            let barrages = snapshots.map { $0.makeBarrage() }
            let now = Date()
            await BarrageService.shared.cache(barrages, date: now)
            return (barrages, now)
        } catch {
            return nil
        }
    }

    // MARK: - Geçmiş veri (Swift Charts için) — direkt tablo sorgusu

    func fetchHistory(barrageId: Int, range: ChartRange) async -> [BarrageHistoryPoint] {
        let startDate = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        let dateString = ISO8601DateFormatter().string(from: startDate)
        let query = "barrage_id=eq.\(barrageId)&captured_at=gte.\(dateString)&order=captured_at.asc&select=doluluk_orani,captured_at"

        guard let url = URL(string: "\(projectURL)/rest/v1/barrage_snapshots?\(query)") else { return [] }

        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode([BarrageHistoryPoint].self, from: data)) ?? []
        } catch {
            return []
        }
    }
}

// MARK: - Response Models

private struct BarrageSnapshot: Decodable {
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
    let capturedAt: Date

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
        case capturedAt           = "captured_at"
    }

    func makeBarrage() -> Barrage {
        var b = Barrage(
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
        b.capturedAt = capturedAt
        return b
    }
}

struct BarrageHistoryPoint: Decodable, Identifiable {
    var id: Date { capturedAt }
    let dolulukOrani: Double
    let capturedAt: Date

    enum CodingKeys: String, CodingKey {
        case dolulukOrani = "doluluk_orani"
        case capturedAt   = "captured_at"
    }
}


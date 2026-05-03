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
            let barrages = snapshots.map(\.barrage)
            let now = Date()
            await BarrageService.shared.cache(barrages, date: now)
            return (barrages, now)
        } catch {
            return nil
        }
    }

    // MARK: - Geçmiş veri (Swift Charts için)

    func fetchHistory(barrageId: Int, days: Int = 30) async -> [BarrageHistoryPoint] {
        let since = ISO8601DateFormatter().string(
            from: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        )
        let urlStr = "\(projectURL)/rest/v1/barrage_snapshots"
            + "?barrage_id=eq.\(barrageId)"
            + "&captured_at=gte.\(since)"
            + "&select=doluluk_orani,captured_at"
            + "&order=captured_at.asc"
        guard let url = URL(string: urlStr) else { return [] }

        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let str = try decoder.singleValueContainer().decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: str) { return date }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: str) { return date }
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "Invalid date: \(str)"
                )
            }
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

    var barrage: Barrage {
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

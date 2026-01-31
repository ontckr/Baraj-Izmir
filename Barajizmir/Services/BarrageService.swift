import Foundation

actor BarrageService {
    static let shared = BarrageService()
    
    private let apiURL = URL(string: "https://openapi.izmir.bel.tr/api/izsu/barajdurum")!
    private let cacheKey = "cached_barrages"
    private let lastUpdateKey = "last_update_date"
    
    private init() {}
    
    func fetchBarrages() async -> (barrages: [Barrage], lastUpdate: Date)? {
        print("🔄 Connecting to API...")
        do {
            let (data, response) = try await URLSession.shared.data(from: apiURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            print("📦 Data size: \(data.count) bytes")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 JSON response (first 500 chars): \(String(jsonString.prefix(500)))")
            }
            
            let barrages = try JSONDecoder().decode([Barrage].self, from: data)
            print("✅ \(barrages.count) barrages decoded successfully")
            
            let now = Date()
            await cacheBarrages(barrages, date: now)
            print("💾 Data cached")
            
            return (barrages, now)
        } catch let decodingError as DecodingError {
            print("❌ Decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   - Key not found: \(key.stringValue)")
                print("   - Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   - Type mismatch: \(type)")
                print("   - Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   - Value not found: \(type)")
                print("   - Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   - Corrupted data: \(context.debugDescription)")
            @unknown default:
                print("   - Unknown decoding error")
            }
            return await loadCachedBarrages()
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            return await loadCachedBarrages()
        }
    }
    
    private func cacheBarrages(_ barrages: [Barrage], date: Date) async {
        if let encoded = try? JSONEncoder().encode(barrages) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(date, forKey: lastUpdateKey)
            print("✅ Cache updated")
        } else {
            print("⚠️ Failed to save cache")
        }
    }
    
    func loadCachedBarrages() async -> (barrages: [Barrage], lastUpdate: Date)? {
        print("📂 Loading from cache...")
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let barrages = try? JSONDecoder().decode([Barrage].self, from: data),
              let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date else {
            print("⚠️ No cached data found")
            return nil
        }
        print("✅ Loaded \(barrages.count) barrages from cache")
        return (barrages, lastUpdate)
    }
}

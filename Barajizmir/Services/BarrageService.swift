import Foundation

actor BarrageService {
    static let shared = BarrageService()
    
    private let appGroupIdentifier = "group.onatcakir.Barajizmir"
    
    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
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
        guard let sharedDefaults = sharedUserDefaults else {
            if let encoded = try? JSONEncoder().encode(barrages) {
                UserDefaults.standard.set(encoded, forKey: cacheKey)
                UserDefaults.standard.set(date, forKey: lastUpdateKey)
                print("✅ Cache updated (fallback to standard)")
            }
            return
        }
        
        if let encoded = try? JSONEncoder().encode(barrages) {
            sharedDefaults.set(encoded, forKey: cacheKey)
            sharedDefaults.set(date, forKey: lastUpdateKey)
            print("✅ Cache updated (App Group)")
        } else {
            print("⚠️ Failed to save cache")
        }
    }
    
    func loadCachedBarrages() async -> (barrages: [Barrage], lastUpdate: Date)? {
        print("📂 Loading from cache...")
        
        let defaults = sharedUserDefaults ?? UserDefaults.standard
        
        guard let data = defaults.data(forKey: cacheKey),
              let barrages = try? JSONDecoder().decode([Barrage].self, from: data),
              let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date else {
            print("⚠️ No cached data found")
            return nil
        }
        print("✅ Loaded \(barrages.count) barrages from cache")
        return (barrages, lastUpdate)
    }
}

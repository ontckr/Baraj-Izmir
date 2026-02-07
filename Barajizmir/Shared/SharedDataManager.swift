import Foundation

struct SharedDataManager {
    static let appGroupIdentifier = "group.onatcakir.Barajizmir"
    
    private static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    static func loadCachedBarrages() -> (barrages: [Barrage], lastUpdate: Date)? {
        let defaults = sharedUserDefaults ?? UserDefaults.standard
        let cacheKey = "cached_barrages"
        let lastUpdateKey = "last_update_date"
        
        guard let data = defaults.data(forKey: cacheKey),
              let barrages = try? JSONDecoder().decode([Barrage].self, from: data),
              let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date else {
            return nil
        }
        
        return (barrages, lastUpdate)
    }
    
    static func getBarrage(byId id: Int) -> Barrage? {
        guard let result = loadCachedBarrages() else { return nil }
        return result.barrages.first { $0.id == id }
    }
}

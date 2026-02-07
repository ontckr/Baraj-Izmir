import AppIntents
import Foundation

struct BarrageSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Baraj Seçimi"
    static var description = IntentDescription("Widget için gösterilecek barajı seçin")
    
    @Parameter(title: "Baraj Listesi", description: "Gösterilecek baraj")
    var barrage: BarrageEntity?
    
    init() {}
    
    init(barrage: BarrageEntity?) {
        self.barrage = barrage
    }
}

struct BarrageEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Baraj"
    
    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    var name: String
    
    static var defaultQuery = BarrageQuery()
    
    init(id: Int, name: String) {
        self.id = String(id)
        self.name = name
    }
}

struct BarrageQuery: EntityQuery {
    func entities(for identifiers: [BarrageEntity.ID]) async throws -> [BarrageEntity] {
        guard let result = await SharedDataManager.loadCachedBarrages() else {
            return []
        }
        
        let intIdentifiers = identifiers.compactMap { Int($0) }
        return result.barrages
            .filter { intIdentifiers.contains($0.id) }
            .map { BarrageEntity(id: $0.id, name: $0.barajAdi) }
    }
    
    func suggestedEntities() async throws -> [BarrageEntity] {
        guard let result = await SharedDataManager.loadCachedBarrages() else {
            return []
        }
        
        return result.barrages
            .sorted { $0.dolulukOrani > $1.dolulukOrani }
            .map { BarrageEntity(id: $0.id, name: $0.barajAdi) }
    }
    
    func entities(matching string: String) async throws -> [BarrageEntity] {
        guard let result = await SharedDataManager.loadCachedBarrages() else {
            return []
        }
        
        let normalizedSearch = normalizeTurkishSearch(string)
        
        return result.barrages
            .compactMap { barrage -> BarrageEntity? in
                let normalizedName = normalizeTurkishSearch(barrage.barajAdi)
                
                if normalizedName.contains(normalizedSearch) || normalizedSearch.contains(normalizedName) {
                    return BarrageEntity(id: barrage.id, name: barrage.barajAdi)
                }
                
                let searchWords = normalizedSearch.split(separator: " ").map(String.init)
                let nameWords = normalizedName.split(separator: " ").map(String.init)
                
                for searchWord in searchWords {
                    if searchWord.count > 2 {
                        for nameWord in nameWords {
                            if nameWord.contains(searchWord) || searchWord.contains(nameWord) {
                                return BarrageEntity(id: barrage.id, name: barrage.barajAdi)
                            }
                        }
                    }
                }
                
                return nil
            }
    }
    
    private func normalizeTurkishSearch(_ text: String) -> String {
        var normalized = text.lowercased()
        
        let commonWords = ["barajı", "baraj", "izmir", "doluluk", "oranı", "oran", "kaç", "yüzde", "durumu", "durum", "nedir", "ne"]
        for word in commonWords {
            normalized = normalized.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        
        normalized = normalized.trimmingCharacters(in: .whitespaces)
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return normalized
    }
}

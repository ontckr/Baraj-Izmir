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
        guard let result = SharedDataManager.loadCachedBarrages() else {
            return []
        }
        
        let intIdentifiers = identifiers.compactMap { Int($0) }
        return result.barrages
            .filter { intIdentifiers.contains($0.id) }
            .map { BarrageEntity(id: $0.id, name: $0.barajAdi) }
    }
    
    func suggestedEntities() async throws -> [BarrageEntity] {
        guard let result = SharedDataManager.loadCachedBarrages() else {
            return []
        }
        
        return result.barrages
            .sorted { $0.dolulukOrani > $1.dolulukOrani }
            .map { BarrageEntity(id: $0.id, name: $0.barajAdi) }
    }
    
    func entities(matching string: String) async throws -> [BarrageEntity] {
        guard let result = SharedDataManager.loadCachedBarrages() else {
            return []
        }
        
        let searchTerm = string.lowercased()
        return result.barrages
            .filter { $0.barajAdi.lowercased().contains(searchTerm) }
            .map { BarrageEntity(id: $0.id, name: $0.barajAdi) }
    }
}

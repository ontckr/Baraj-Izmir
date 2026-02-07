import AppIntents
import Foundation

@available(iOS 17.0, *)
struct BarrageFillRateIntent: AppIntent {
    static var title: LocalizedStringResource = "Baraj Doluluk Oranı Sorgula"
    static var description = IntentDescription("Barajların doluluk oranlarını öğrenmek için Siri'ye sorun")
    
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Barajların doluluk oranlarını söyle")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let result = SharedDataManager.loadCachedBarrages() else {
            if let freshResult = await BarrageService.shared.fetchBarrages() {
                return try handleResponse(barrages: freshResult.barrages)
            } else {
                throw IntentError.noDataAvailable
            }
        }
        
        let dataAge = Date().timeIntervalSince(result.lastUpdate)
        if dataAge > 43200 {
            Task {
                _ = await BarrageService.shared.fetchBarrages()
            }
        }
        
        return try handleResponse(barrages: result.barrages)
    }
    
    @MainActor
    private func handleResponse(barrages: [Barrage]) throws -> some IntentResult & ProvidesDialog {
        guard !barrages.isEmpty else {
            throw IntentError.noDataAvailable
        }
        let sortedBarrages = barrages.sorted { $0.dolulukOrani > $1.dolulukOrani }
        
        var responseParts: [String] = []
        responseParts.append("Barajların doluluk oranları:")
        
        let maxBarrages = min(6, sortedBarrages.count)
        for index in 0..<maxBarrages {
            let barrage = sortedBarrages[index]
            let fillRate = Int(round(barrage.dolulukOrani))
            let reservoirName = barrage.barajAdi
            
            if index == maxBarrages - 1 {
                responseParts.append("\(reservoirName) % \(fillRate).")
            } else {
                responseParts.append("\(reservoirName) % \(fillRate),")
            }
        }
        
        let spokenResponse = responseParts.joined(separator: " ")
        return .result(dialog: IntentDialog(stringLiteral: spokenResponse))
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noDataAvailable
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noDataAvailable:
            return "Şu anda baraj verilerine ulaşılamıyor."
        }
    }
}

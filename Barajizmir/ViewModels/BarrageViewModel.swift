import Foundation
import Combine

@MainActor
class BarrageViewModel: ObservableObject {
    @Published var barrages: [Barrage] = []
    @Published var lastUpdate: Date?
    @Published var isRefreshing = false
    
    init() {
        print("🚀 BarrageViewModel initializing...")
        Task {
            await loadBarrages()
        }
    }
    
    func loadBarrages() async {
        print("📥 Loading barrage data...")
        if let result = await BarrageService.shared.fetchBarrages() {
            print("✅ Received \(result.barrages.count) barrages, sorting...")
            barrages = result.barrages.sorted { $0.dolulukOrani > $1.dolulukOrani }
            lastUpdate = result.lastUpdate
            print("✅ UI updated - displaying \(barrages.count) barrages")
            
            for barrage in barrages {
                print("   📊 \(barrage.barajAdi): %\(barrage.dolulukOrani)")
            }
        } else {
            print("❌ No data received!")
        }
    }
    
    func refresh() async {
        print("🔄 Refresh started...")
        isRefreshing = true
        await loadBarrages()
        isRefreshing = false
        print("✅ Refresh completed")
    }
}

import Foundation
import Combine
import WidgetKit

@MainActor
class BarrageViewModel: ObservableObject {
    @Published var barrages: [Barrage] = []
    @Published var lastUpdate: Date?
    @Published var isRefreshing = false
    @Published var isLoadingFromAPI = false
    @Published var hasAPIError = false

    init() {
        // Show cached data instantly — no waiting for network
        if let cached = SharedDataManager.loadCachedBarrages() {
            barrages = cached.barrages.sorted { $0.dolulukOrani > $1.dolulukOrani }
            lastUpdate = cached.lastUpdate
        }
        Task {
            await fetchFreshFromAPI()
        }
    }

    func refresh() async {
        isRefreshing = true
        await fetchFreshFromAPI()
        isRefreshing = false
    }

    private func fetchFreshFromAPI() async {
        isLoadingFromAPI = true
        if let result = await BarrageService.shared.fetchFreshFromAPI() {
            barrages = result.barrages.sorted { $0.dolulukOrani > $1.dolulukOrani }
            lastUpdate = result.lastUpdate
            hasAPIError = false
            WidgetCenter.shared.reloadAllTimelines()
            NotificationManager.shared.checkThresholds(against: barrages)
        } else {
            hasAPIError = true
        }
        isLoadingFromAPI = false
    }
}
